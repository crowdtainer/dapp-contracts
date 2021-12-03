// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

// @dev External dependencies
import "../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "../lib/openzeppelin-contracts/contracts/interfaces/IERC1155.sol";
// import "../lib/openzeppelin-contracts/contracts/proxy/Clones.sol";

// @dev Internal dependencies
import "./Crowdtainer.sol";
import "./ERC1155.sol";
import "./Errors.sol";
import "./Constants.sol";

/**
 * @title Manages multiple Crowdtainer projects and ownership of its product/services by participants.
 * @dev Essentially, a Crowdtainer factory with ERC1155 compliance.
 */
contract Harbor is ERC1155, ReentrancyGuard {
    //using Clones for address;

    // @dev The next available id from the ERC1159 implementation.
    // @note It is incremented by `MAX_NUMBER_OF_PRODUCTS` per Crowdtainer project.
    // @note This allows us to easily pinpoint any product/service id to its respective Crowdtainer project as follows:
    // @note crowdtainer_id = tokenId / MAX_NUMBER_OF_PRODUCTS (division will truncate). The specific product index position is: tokenId - crowdtainer_id.
    uint256 private nextTokenIdStartIndex;

    //address private immutable implementation;

    // @dev Mapping of token id to Crowdtainer contract address.
    mapping(uint256 => address) public crowdtainerForId;

    // @dev Mapping of deployed Crowdtainer contract addresses to its initial token id.
    mapping(address => uint256) public idForCrowdtainer;

    // -----------------------------------------------
    //  Events
    // -----------------------------------------------

    // @note Emmited when this contract is created.
    event HarborCreated(address indexed crowdtainer);

    // @note Emmited when a new Crowdtainer is deployed and initialized by this contract.
    event CrowdtainerDeployed(
        address indexed _crowdtainerAddress,
        uint256 _tokenIdStartIndex
    );

    // -----------------------------------------------
    //  Contract functions
    // -----------------------------------------------

    // @param Deploy a new Harbor.
    constructor() {
        // implementation = address(new Crowdtainer(address(this)));
        emit HarborCreated(address(this));
    }

    /**
     * @dev Create and deploy a new Crowdtainer.
     * @param _shippingAgent Address that represents the product or service provider.
     * @param _openingTime Funding opening time.
     * @param _expireTime Time after which the owner can no longer withdraw funds.
     * @param _targetMinimum Amount in ERC20 units required for project to be considered to be successful.
     * @param _targetMaximum Amount in ERC20 units after which no further participation is possible.
     * @param _unitPricePerType Array with price of each item, in ERC2O units. Zero is an invalid value and will throw.
     * @param _referralRate Percentage used for incentivising participation. Half the amount goes to the referee, and the other half to the referrer.
     * @param _token Address of the ERC20 token used for payment.
     */
    //     * @param _uri URI used to fetch metadata details. See `IERC1155MetadataURI`.
    function createCrowdtainer(
        address _shippingAgent,
        uint256 _openingTime,
        uint256 _expireTime,
        uint256 _targetMinimum,
        uint256 _targetMaximum,
        uint256[MAX_NUMBER_OF_PRODUCTS] memory _unitPricePerType,
        uint256 _referralRate,
        IERC20 _token
    ) public {
        //Crowdtainer crowdtainer = clone(Crowdtainer);
        Crowdtainer crowdtainer = new Crowdtainer(address(this));
        crowdtainer.initialize(
            _shippingAgent,
            _openingTime,
            _expireTime,
            _targetMinimum,
            _targetMaximum,
            _unitPricePerType,
            _referralRate,
            _token
        );

        emit CrowdtainerDeployed(address(crowdtainer), nextTokenIdStartIndex);

        idForCrowdtainer[address(crowdtainer)] = nextTokenIdStartIndex;
        crowdtainerForId[nextTokenIdStartIndex] = address(crowdtainer);

        nextTokenIdStartIndex = nextTokenIdStartIndex + MAX_NUMBER_OF_PRODUCTS;
    }

    /*
     * @dev Join the pool.
     * @param _crowdtainerId Crowdtainer project id.
     * @param _quantities Array with the number of units desired for each product.
     * @param _enableReferral Informs whether the user would like to be elible to collect rewards for being referred.
     * @param _referrer Optional referral code to be used to claim a discount.
     *
     * @note referrer is the wallet address of a previous participant.
     *
     * @note if `enableReferral` is true, and the user decides to leave after the wallet has been used to claim a discount,
     *       then the full value can't be claimed if deciding to leave the project.
     *
     * @note A same user is not allowed to increase the order amounts (i.e., by calling join multiple times).
     *       To 'update' an order, the user must first 'leave' then join again with the new values.
     *
     */
    function join(
        uint256 _crowdtainerId,
        uint256[MAX_NUMBER_OF_PRODUCTS] calldata _quantities,
        bool _enableReferral,
        address _referrer
    ) external {
        Crowdtainer crowdtainer = Crowdtainer(crowdtainerForId[_crowdtainerId]);

        crowdtainer.join(msg.sender, _quantities, _enableReferral, _referrer);

        // Mint respective products and transfer ownership
        for (uint256 i = 0; i < crowdtainer.numberOfProducts(); i++) {
            if (_quantities[i] > 0) {
                _mint(msg.sender, _crowdtainerId + i, _quantities[i]); // params: to, id, amount
            }
        }
    }

    /*
     * @dev Leave the specified Crowdtainer and withdraw all deposited funds given when joining.
     * @note Calling this method signals that the user is no longer interested in participating.
     * @note Only allowed if the respective Crowdtainer is in active funding state.
     */
    function leave(uint256 _crowdtainerId) external {
        Crowdtainer crowdtainer = Crowdtainer(crowdtainerForId[_crowdtainerId]);

        crowdtainer.leave(msg.sender);

        // Set product balances to zero for the current user
        for (uint256 i = 0; i < crowdtainer.numberOfProducts(); i++) {
            uint256 amount = balanceOf(msg.sender, _crowdtainerId + i);
            if (amount > 0) {
                _burn(msg.sender, _crowdtainerId + i, amount); // params: from, id, amount
            }
        }
    }

    /**
     * @notice Get the metadata uri
     * @return String uri of the metadata service
     */
    function uri(uint256) public view override returns (string memory) {
        // return uri_;
        return "dummy";
    }

    /**************************************************************************
     * Internal/private methods
     *************************************************************************/

    /**
     * @notice Function used to apply restrictions of states where transfers are disabled.
     * @param tokenId Token id of the item being transfered.
     * @dev Tranfers are only allowed in `Delivery` or `Failed` states, but not e.g. during `Funding`.
     */
    function _revertIfNotTransferable(uint256 tokenId) internal view override {
        // Transfers are only allowed after funding either succeeded or failed.
        uint256 crowdtainerId = tokenId / MAX_NUMBER_OF_PRODUCTS;
        Crowdtainer crowdtainer = Crowdtainer(crowdtainerForId[crowdtainerId]);
        if (
            crowdtainer.crowdtainerState() == CrowdtainerState.Delivery ||
            crowdtainer.crowdtainerState() == CrowdtainerState.Failed
        ) {
            revert Errors.TransferNotAllowed({
                crowdtainer: address(crowdtainer),
                state: crowdtainer.crowdtainerState()
            });
        }
    }
}
