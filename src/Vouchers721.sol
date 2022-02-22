// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

// @dev External dependencies
import "../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "../lib/openzeppelin-contracts/contracts/interfaces/IERC721.sol";
import "../lib/openzeppelin-contracts/contracts/proxy/Clones.sol";

// @dev Internal dependencies
import "./ICrowdtainer.sol";
import "./Errors.sol";
import "./Constants.sol";
import "./Metadata/IMetadataService.sol";

/**
 * @title Manages multiple Crowdtainer projects and ownership of its product/services by participants.
 * @dev Essentially, a Crowdtainer factory with ERC721 compliance.
 * @dev Each token id represents a "sold voucher", a set of one or more products or services of a specific Crowdtainer.
 */
contract Vouchers721 is ERC721, ReentrancyGuard {
    // using Clones for address;

    // @dev Each Crowdtainer project is alloacted a range.
    // @dev This is used as a multiple to deduce the crowdtainer id from a given token id.
    uint256 constant public ID_MULTIPLE = 1000;

    // @dev The next available tokenId for the given crowdtainerId.
    mapping(uint256 => uint256) private nextTokenIdForCrowdtainer;

    // @dev Number of created crowdtainers.
    uint256 public crowdtainerCount;

    address private immutable crowdtainerImplementation;

    // @dev Mapping of id to Crowdtainer contract address.
    mapping(uint256 => address) public crowdtainerForId;
    // @dev Mapping of deployed Crowdtainer contract addresses to its token id.
    mapping(address => uint256) public idForCrowdtainer;

    // @dev Mapping of base token ID to metadata service, used as return value for URI method.
    mapping(uint256 => address) public metadataServiceForCrowdatinerId;

    // @dev Mapping of token ID => product quantities.
    mapping(uint256 => uint256[MAX_NUMBER_OF_PRODUCTS])
        public tokenIdQuantities;

    // @dev Mapping of crowdtainer id => array of product descriptions.
    mapping(uint256 => string[MAX_NUMBER_OF_PRODUCTS])
        public productDescription;

    // -----------------------------------------------
    //  Events
    // -----------------------------------------------

    // @note Emmited when this contract is created.
    event Vouchers721Created(address indexed crowdtainer);

    // @note Emmited when a new Crowdtainer is deployed and initialized by this contract.
    event CrowdtainerDeployed(
        address indexed _crowdtainerAddress,
        uint256 _nextCrowdtainerId
    );

    // -----------------------------------------------
    //  Contract functions
    // -----------------------------------------------

    constructor(address _crowdtainerImplementation)
        ERC721("Vouchers721", "VV1")
    {
        // implementation = address(new Crowdtainer(address(this)));
        crowdtainerImplementation = _crowdtainerImplementation;
        emit Vouchers721Created(address(this));
    }

    /**
     * @dev Create and deploy a new Crowdtainer.
     * @param _campaignData Data defining all rules and values of this Crowdtainer instance.
     * @param _productDescription An array with the description of each item.
     * @param _metadataService Contract address used to fetch metadata about the token.
     * @return crowdtainerId The identifier for the created Crowdtainer.
     */
    function createCrowdtainer(
        CampaignData calldata _campaignData,
        string[MAX_NUMBER_OF_PRODUCTS] memory _productDescription,
        address _metadataService
    ) external returns (address, uint256) {
        if (_metadataService == address(0)) {
            revert Errors.MetadataServiceAddressIsZero();
        }

        ICrowdtainer crowdtainer = ICrowdtainer(
            Clones.clone(crowdtainerImplementation)
        );
        // Crowdtainer crowdtainer = new Crowdtainer(address(this));

        crowdtainer.initialize(address(this), _campaignData);

        idForCrowdtainer[address(crowdtainer)] = ++crowdtainerCount;
        crowdtainerForId[crowdtainerCount] = address(crowdtainer);

        productDescription[crowdtainerCount] = _productDescription;
        metadataServiceForCrowdatinerId[crowdtainerCount] = _metadataService;
        emit CrowdtainerDeployed(address(crowdtainer), crowdtainerCount);

        return (address(crowdtainer), crowdtainerCount);
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
        address _crowdtainer,
        uint256[MAX_NUMBER_OF_PRODUCTS] calldata _quantities,
        bool _enableReferral,
        address _referrer
    ) external returns (uint256) {

        uint256 crowdtainerId = idForCrowdtainer[_crowdtainer];

        if (crowdtainerId == 0) {
            revert Errors.CrowdtainerInexistent();
        }

        ICrowdtainer crowdtainer = ICrowdtainer(_crowdtainer);

        crowdtainer.join(msg.sender, _quantities, _enableReferral, _referrer);

        uint256 nextAvailableTokenId = ++nextTokenIdForCrowdtainer[crowdtainerId];

        if(nextAvailableTokenId >= ID_MULTIPLE) {
            revert Errors.MaximumNumberOfParticipantsReached(ID_MULTIPLE, _crowdtainer);
        }

        uint256 newTokenID = (ID_MULTIPLE * crowdtainerId) + nextAvailableTokenId;

        tokenIdQuantities[newTokenID] = _quantities;

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

        if(ownerOf(_tokenId) != msg.sender) {
            revert Errors.AccountNotOwnerOrApproved();
        }

        address crowdtainerAddress = crowdtainerIdToAddress(tokenIdToCrowdtainerId(_tokenId));
        ICrowdtainer crowdtainer = ICrowdtainer(crowdtainerAddress);

        crowdtainer.leave(msg.sender);

        delete tokenIdQuantities[_tokenId];

        _burn(_tokenId);
    }

    /**
     * @notice Get the metadata representation.
     * @param _tokenId The encoded voucher token id.
     * @return Token URI String.
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        uint256 crowdtainerId = tokenIdToCrowdtainerId(_tokenId);
        address crowdtainerAddress = crowdtainerIdToAddress(crowdtainerId);

        ICrowdtainer crowdtainer = ICrowdtainer(crowdtainerAddress);

        uint256 numberOfProducts = crowdtainer.numberOfProducts();

        IMetadataService metadataService = IMetadataService(
            metadataServiceForCrowdatinerId[crowdtainerId]
        );

        uint256[MAX_NUMBER_OF_PRODUCTS] memory prices = [
            crowdtainer.unitPricePerType(0),
            crowdtainer.unitPricePerType(1),
            crowdtainer.unitPricePerType(2),
            crowdtainer.unitPricePerType(3)
        ];

        Metadata memory metadata = Metadata(
            crowdtainerId,
            _tokenId - (tokenIdToCrowdtainerId(_tokenId) * ID_MULTIPLE),
            ownerOf(_tokenId),
            false, // claimed?
            prices,
            tokenIdQuantities[_tokenId],
            productDescription[crowdtainerId],
            numberOfProducts
        );

        return metadataService.uri(metadata);
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
        if (mintOrBurn) return;

        // Transfers are only allowed after funding either succeeded or failed.
        address crowdtainerAddress = crowdtainerIdToAddress(tokenIdToCrowdtainerId(tokenId));
        ICrowdtainer crowdtainer = ICrowdtainer(crowdtainerAddress);

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

    function tokenIdToCrowdtainerId(uint256 _tokenId) public pure returns (uint256) {
        if(_tokenId == 0
           || _tokenId < ID_MULTIPLE) {
            revert Errors.InvalidTokenId(_tokenId);
        }

        return _tokenId / ID_MULTIPLE;
    }

    function crowdtainerIdToAddress(uint256 _crowdtainerId) public view returns (address) {
        address crowdtainerAddress = crowdtainerForId[_crowdtainerId];
        if (crowdtainerAddress == address(0)) {
            revert Errors.CrowdtainerInexistent();
        }
        return crowdtainerAddress;
    }
}