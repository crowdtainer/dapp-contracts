// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

// @dev External dependencies
import "../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "../lib/openzeppelin-contracts/contracts/interfaces/IERC721.sol";
// import "../lib/openzeppelin-contracts/contracts/proxy/Clones.sol";

// @dev Internal dependencies
import "./Crowdtainer.sol";
import "./Errors.sol";
import "./Constants.sol";

/**
 * @dev Metadata service used to provide URI for a voucher / token id.
 */
 interface IMetadataService {
    function uri(uint256) external view returns (string memory);
}

/**
 * @title Manages multiple Crowdtainer projects and ownership of its product/services by participants.
 * @dev Essentially, a Crowdtainer factory with ERC721 compliance.
 * @dev Each token id represents a "sold voucher", a set of one or more products or services of a specific Crowdtainer.
 */
contract Vouchers721 is ERC721, ReentrancyGuard {
    //using Clones for address;

    // @dev The next available base id from the ERC721 implementation to be used for a new Crowdtainer.
    // @note In order to support multiple crowdtainer instances, we split the uint256 ID bits into two parts:
    // @note <uint128: base token id><uint128: index of non-fungible>. `nextTokenBaseId` represents the next available base token id.
    uint128 private nextTokenBaseId;

    // @dev The next available token id for the given base id.
    mapping(uint128 => uint128) public nextTokenIdForBase;

    //address private immutable implementation;

    // @dev Mapping of token base id to Crowdtainer contract address.
    mapping(uint128 => address) public crowdtainerForId;
    // @dev Mapping of deployed Crowdtainer contract addresses to its initial token base id.
    mapping(address => uint256) public idForCrowdtainer;

    // @dev Mapping of deployed Crowdtainer contract addresses to its base token id.
    // mapping(address => uint256) public idForCrowdtainer;

    // @dev Mapping of base token ID to metadata service, used as return value for URI method.
    mapping(uint128 => address) public metadataServiceForCrowdatinerId;

    // -----------------------------------------------
    //  Events
    // -----------------------------------------------

    // @note Emmited when this contract is created.
    event Vouchers721Created(address indexed crowdtainer);

    // @note Emmited when a new Crowdtainer is deployed and initialized by this contract.
    event CrowdtainerDeployed(
        address indexed _crowdtainerAddress,
        uint256 _nextTokenBaseId
    );

    // -----------------------------------------------
    //  Contract functions
    // -----------------------------------------------

    constructor() ERC721("Vouchers721", "VV1") {
        // implementation = address(new Crowdtainer(address(this)));
        emit Vouchers721Created(address(this));
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
     * @param _referralEligibilityValue The minimum purchase value required to be eligible to participate in referral rewards.
     * @param _token Address of the ERC20 token used for payment.
     * @param _metadataService Contract address used to fetch metadata about the token.
     */
    function createCrowdtainer(
        address _shippingAgent,
        uint256 _openingTime,
        uint256 _expireTime,
        uint256 _targetMinimum,
        uint256 _targetMaximum,
        uint256[MAX_NUMBER_OF_PRODUCTS] memory _unitPricePerType,
        uint256 _referralRate,
        uint256 _referralEligibilityValue,
        IERC20 _token,
        address _metadataService
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
            _referralEligibilityValue,
            _token
        );

        idForCrowdtainer[address(crowdtainer)] = nextTokenBaseId;
        crowdtainerForId[nextTokenBaseId] = address(crowdtainer);
        metadataServiceForCrowdatinerId[nextTokenBaseId] = _metadataService;
        emit CrowdtainerDeployed(address(crowdtainer), nextTokenBaseId);

        nextTokenBaseId++;
    }

    /*
     * @dev Join the pool.
     * @param _crowdtainerId Crowdtainer project id; The token id base value.
     * @param _quantities Array with the number of units desired for each product.
     * @param _enableReferral Informs whether the user would like to be eligible to collect rewards for being referred.
     * @param _referrer Optional referral code to be used to claim a discount.
     * @return The token id that represents the created voucher.
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
        uint128 _crowdtainerId,
        uint256[MAX_NUMBER_OF_PRODUCTS] calldata _quantities,
        bool _enableReferral,
        address _referrer
    ) external returns (uint256) {
        Crowdtainer crowdtainer = Crowdtainer(crowdtainerForId[_crowdtainerId]);

        crowdtainer.join(msg.sender, _quantities, _enableReferral, _referrer);

        nextTokenIdForBase[_crowdtainerId]++;

        uint256 newTokenID = _crowdtainerId + nextTokenIdForBase[_crowdtainerId];
        // Mint the voucher to the respective owner
        _safeMint(msg.sender, newTokenID);

        return newTokenID;
    }

    /*
     * @dev Return the specified voucher and withdraw all deposited funds given when joining the Crowdtainer.
     * @note Calling this method signals that the user is no longer interested in participating.
     * @note Only allowed if the respective Crowdtainer is in active funding state.
     */
    function leave(uint256 _tokenId) external {
        uint128 crowdtainerBaseTokenId = uint128(_tokenId << 128);
        Crowdtainer crowdtainer = Crowdtainer(crowdtainerForId[crowdtainerBaseTokenId]);

        crowdtainer.leave(msg.sender);

        _burn(_tokenId);
    }

    /**
     * @notice Get the metadata.
     * @return Token URI String.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        uint128 crowdtainerBaseTokenId = uint128(tokenId << 128);
        IMetadataService metadataService = IMetadataService(metadataServiceForCrowdatinerId[crowdtainerBaseTokenId]);
        return metadataService.uri(tokenId);
    }

    /**************************************************************************
     * Internal/private methods
     *************************************************************************/

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     * @dev Tranfers are only allowed in `Delivery` or `Failed` states, but not e.g. during `Funding`.
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal view override {
        bool mintOrBurn = from == address(0) || to == address(0);
        if(mintOrBurn)
            return;

        // Transfers are only allowed after funding either succeeded or failed.
        uint128 crowdtainerBaseTokenId = uint128(tokenId << 128);

        Crowdtainer crowdtainer = Crowdtainer(crowdtainerForId[crowdtainerBaseTokenId]);
        if (
            crowdtainer.crowdtainerState() == CrowdtainerState.Funding ||
            crowdtainer.crowdtainerState() == CrowdtainerState.Uninitialized
        ) {
            revert Errors.TransferNotAllowed({
                crowdtainer: address(crowdtainer),
                state: crowdtainer.crowdtainerState()
            });
        }
    }
}