// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

// @dev External dependencies
import "../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "../lib/openzeppelin-contracts/contracts/interfaces/IERC1155.sol";
import "../lib/openzeppelin-contracts/contracts/proxy/Clones.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

// @dev Internal dependencies
import "./Crowdtainer.sol";
import "./ERC1155.sol";
import "./Errors.sol";
import "./Constants.sol";

/**
 * @title Crowdtainer factory with ERC1155 compliance
 */
contract Harbor is ERC1155, ReentrancyGuard, Ownable {

    using Clones for address;

    // @dev The next available id from the ERC1159 implementation.
    uint256 private tokenIdStartIndex;

    // @dev Mapping of tokenId to Crowdtainer contract address.
    mapping(uint256 => address) public crowdtainerForId;

    // -----------------------------------------------
    //  Events
    // -----------------------------------------------

    // @note Emmited when this contract is created.
    event HarborCreated(address indexed owner);

    // -----------------------------------------------
    //  Modifiers
    // -----------------------------------------------
    /**
     * @dev Throws if called by any account other than the specified.
     */
    modifier onlyAddress(address requiredAddress) {
        if (msg.sender != requiredAddress)
            revert Errors.CallerNotAllowed({
                expected: msg.sender,
                actual: requiredAddress
            });
        require(msg.sender == requiredAddress);
        _;
    }

    // -----------------------------------------------
    //  Contract functions
    // -----------------------------------------------

    // @param _owner Owner of this contract.
    constructor(address _owner) {
        if (_owner == address(0)) revert Errors.OwnerAddressIsZero();
        owner = _owner;
        emit HarborCreated(owner);
    }

    /**
     * @dev Deploy a new Crowdtainer.
     * @param _shippingAgent Address that represents the product or service provider.
     * @param _numberOfItems The number of item variations avaiable to choose from.
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
        uint256 _numberOfItems,
        uint256 _openingTime,
        uint256 _expireTime,
        uint256 _targetMinimum,
        uint256 _targetMaximum,
        uint256[MAX_NUMBER_OF_PRODUCTS] memory _unitPricePerType,
        uint256 _referralRate,
        IERC20 _token
    ) public {
        // TODO: Create new Crowdtainer and save its address
        crowdtainer = address(new Crowdtainer());
        crowdtainer.initialize(address(this),
                              _shippingAgent,
                              tokenIdStartIndex,
                              _numberOfItems,
                              _openingTime, 
                              _expireTime, 
                              _targetMinimum,
                              _targetMaximum,
                              _unitPricePerType,
                              _referralRate,
                              _token);
        crowdtainerForId[tokenIdStartIndex] = crowdtainer;
        tokenIdStartIndex++;
    }

    /*
     * @dev Join the pool.
     * @param quantities Array with the number of units desired for each product.
     * @param referralCode Optional referral code to be used to claim a discount.
     * @param newReferralCode Optional identifier to generate a new referral code.
     *
     * @note referralCode and newReferralCode both accept values of 0x0, which means no current or future
     * discounts will be available for the participant joining the pool.
     *
     * @note referralCode and newReferralCode are expected to only contain printable ASCII characters,
     * which means the characters between and including 0x1F .. 0x7E, and be in total up to 32 characters.
     * The frontend can normalize all characters to lower-case before interacting with this contract to
     * avoid user typing mistakes.
     *
     * @note A same user is allowed to increase the order amounts (i.e., by calling join multiple times).
     *       However, a second call to join() can't provide yet a new referral code (newReferralCode parameter) if
     *       the previous referral code has already been claimed by another account.
     *
     * @dev State variables manipulated by this function:
     *
     *       ownerOfReferralCode[newReferralCode]   (msg.sender)
     *       balanceOf[msg.sender][i]               (+= quantities[i])
     *       accumulatedRewardsOf[referrer]         (+= discount)
     *       discountAndRewards                     (+= discount * 2)
     *       discountForUser[msg.sender]            (+= discount)
     *       totalRaised                            (+= finalCost)
     */
    function join(
        uint256 _crowdtainerId,
        address _wallet,
        uint256[MAX_NUMBER_OF_PRODUCTS] calldata _quantities,
        address _referrer
    ) external {
        Crowdtainer(crowdtainerForId[_crowdtainerId]).join(_wallet, _quantities, _referrer);
    }

    /*
     * @dev Leave the pool and withdraw deposited funds given when joining.
     * @note Calling this method signals that the user is no longer interested in participating.
     */
    function leave()
        external
    {
        Crowdtainer(crowdtainerForId[_crowdtainerId]).leave(msg.sender);
    }

    /**
     * @notice Get the metadata uri
     * @return String uri of the metadata service
     */
    function uri(uint256) public view override returns (string memory) {
        return uri_;
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private override {
        // super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        // Transfers are only allowed after funding either succeeded (or failed).
        if (crowdtainerState != CrowdtainerState.Delivery || crowdtainerState != CrowdtainerState.Failed)
            revert Errors.InvalidOperationFor({state: crowdtainerState});
    }

    /**************************************************************************
     * Internal/private methods
     *************************************************************************/

    function _canTransfer(uint256 tokenId) internal virtual override returns (bool) {
        return false;
    }
}
