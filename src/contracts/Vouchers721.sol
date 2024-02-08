// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

// @dev External dependencies
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

// @dev Internal dependencies
import "./ICrowdtainer.sol";
import "./Crowdtainer.sol";
import "./Errors.sol";
import "./Constants.sol";
import "./Metadata/IMetadataService.sol";

/**
 * @title Crowdtainer's project manager contract.
 * @author Crowdtainer.eth
 * @notice Manages Crowdtainer projects and ownership of its product/services by participants.
 * @dev Essentially, a Crowdtainer factory with ERC-721 compliance.
 * @dev Each token id represents a "sold voucher", a set of one or more products or services of a specific Crowdtainer.
 */
contract Vouchers721 is ERC721Enumerable {
    // @dev Each Crowdtainer project is alloacted a range.
    // @dev This is used as a multiple to deduce the crowdtainer id from a given token id.
    uint256 public constant ID_MULTIPLE = 1000000;

    // @dev Claimed status of a specific token id
    BitMaps.BitMap private claimed;

    // @dev The next available tokenId for the given crowdtainerId.
    mapping(uint256 => uint256) private nextTokenIdForCrowdtainer;

    /// @notice Owner of this contract deployment.
    /// @dev Has permission to call createCrowdtainer() function. This function is optionally
    /// @dev gated so that unrelated entities can't maliciously associate themselves with the deployer
    /// @dev of this contract, but is instead required to deploy a new contract.
    address public owner;

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
    mapping(uint256 => uint256[]) public tokenIdQuantities;

    // @dev Mapping of crowdtainer id => array of product descriptions.
    mapping(uint256 => string[]) public productDescription;

    // -----------------------------------------------
    //  Modifiers
    // -----------------------------------------------
    /**
     * @dev If the contract has an "owner" specified, this modifier will
     * enforce that only the owner can call the function. If no owner is assigned (is address(0)), then the
     * restriction is not applied.
     */
    modifier onlyOwner() {
        if (owner == address(0)) {
            // No restrictions.
            _;
            return;
        }
        if (msg.sender != owner)
            revert Errors.CallerNotAllowed({
                expected: owner,
                actual: msg.sender
            });
        require(msg.sender == owner);
        _;
    }

    // -----------------------------------------------
    //  Events
    // -----------------------------------------------

    // @note Emmited when this contract is created.
    event Vouchers721Created(
        address indexed crowdtainer,
        address indexed owner
    );

    // @note Emmited when a new Crowdtainer is deployed and initialized by this contract.
    event CrowdtainerDeployed(
        address indexed _crowdtainerAddress,
        uint256 _nextCrowdtainerId
    );

    /// @notice Emmited when the owner changes.
    event OwnerChanged(address indexed newOwner);

    function requireMsgSender(address requiredAddress) internal view {
        if (msg.sender != requiredAddress)
            revert Errors.CallerNotAllowed({
                expected: requiredAddress,
                actual: msg.sender
            });
        require(msg.sender == requiredAddress);
    }

    // -----------------------------------------------
    //  Contract functions
    // -----------------------------------------------

    /**
     * @notice Create and deploy a new Crowdtainer manager.
     * @dev Uses contract factory pattern.
     * @param _crowdtainerImplementation the address of the reference implementation.
     * @param _owner Optional. If not address(0), it will be the only address allowed to create new crowdtainer projects from this manager contract.
     */
    constructor(
        address _crowdtainerImplementation,
        address _owner
    ) ERC721("Vouchers721", "VV1") {
        // equivalent to: crowdtainerImplementation = address(new Crowdtainer(address(this)));.
        crowdtainerImplementation = _crowdtainerImplementation;
        owner = _owner;
        emit Vouchers721Created(address(this), owner);
    }

    /**
     * @notice Set a new address to be allowed to deploy new campaigns from this manager contract.
     * @notice Only possible if this contract was deployed with a owner other than address(0).
     */
    function setOwner(address _owner) external onlyOwner {
        if (owner == address(0)) {
            revert Errors.OwnerAddressIsZero();
        }
        owner = _owner;
        emit OwnerChanged(owner);
    }

    /**
     * @notice Create and deploy a new Crowdtainer.
     * @param _campaignData Data defining all rules and values of this Crowdtainer instance.
     * @param _productDescription An array with the description of each item.
     * @param _metadataService Contract address used to fetch metadata about the token.
     * @return crowdtainerId The contract address and id for the created Crowdtainer.
     */
    function createCrowdtainer(
        CampaignData calldata _campaignData,
        string[] memory _productDescription,
        address _metadataService
    ) external onlyOwner returns (address, uint256) {
        if (_metadataService == address(0)) {
            revert Errors.MetadataServiceAddressIsZero();
        }

        // Equivalent to: ICrowdtainer crowdtainer = ICrowdtainer(new Crowdtainer());
        ICrowdtainer crowdtainer = ICrowdtainer(
            Clones.clone(crowdtainerImplementation)
        );

        try crowdtainer.initialize(address(this), _campaignData) {
            idForCrowdtainer[address(crowdtainer)] = ++crowdtainerCount;
            crowdtainerForId[crowdtainerCount] = address(crowdtainer);

            productDescription[crowdtainerCount] = _productDescription;
            metadataServiceForCrowdatinerId[
                crowdtainerCount
            ] = _metadataService;
            emit CrowdtainerDeployed(address(crowdtainer), crowdtainerCount);

            return (address(crowdtainer), crowdtainerCount);
        } catch (bytes memory receivedBytes) {
            _bubbleRevert(receivedBytes);
        }
    }

    /**
     * @notice Join the specified Crowdtainer project.
     * @param _crowdtainer Crowdtainer project address.
     * @param _quantities Array with the number of units desired for each product.
     *
     * @dev This method is present to make wallet UX more friendly, by requiring fewer parameters (for projects with referral system disabled).
     * @dev Requires IERC20 permit.
     */
    function join(
        address _crowdtainer,
        uint256[] calldata _quantities
    ) public returns (uint256) {
        return join(_crowdtainer, _quantities, false, address(0));
    }

    /**
     * @notice Join the specified Crowdtainer project with optional referral and discount.
     * @param _crowdtainer Crowdtainer project address.
     * @param _quantities Array with the number of units desired for each product.
     * @param _enableReferral Informs whether the user would like to be eligible to collect rewards for being referred.
     * @param _referrer Optional referral code to be used to claim a discount.
     * @return The token id that represents the created voucher / ownership.
     *
     * @dev Requires IERC20 permit.
     * @dev referrer is the wallet address of a previous participant.
     * @dev if `enableReferral` is true, and the user decides to leave after the wallet has been used to claim a discount,
     *       then the full value can't be claimed if deciding to leave the project.
     * @dev A same user is not allowed to increase the order amounts (i.e., by calling join multiple times).
     *      To 'update' an order, the user must first 'leave' then join again with the new values.
     */
    function join(
        address _crowdtainer,
        uint256[] calldata _quantities,
        bool _enableReferral,
        address _referrer
    ) public returns (uint256) {
        uint256 crowdtainerId = idForCrowdtainer[_crowdtainer];

        if (crowdtainerId == 0) {
            revert Errors.CrowdtainerInexistent();
        }

        ICrowdtainer crowdtainer = ICrowdtainer(_crowdtainer);

        try
            crowdtainer.join(
                msg.sender,
                _quantities,
                _enableReferral,
                _referrer
            )
        /* solhint-disable-next-line no-empty-blocks */
        {

        } catch (bytes memory receivedBytes) {
            handleJoinError(_crowdtainer, receivedBytes);
        }

        uint256 nextAvailableTokenId = ++nextTokenIdForCrowdtainer[
            crowdtainerId
        ];

        if (nextAvailableTokenId >= ID_MULTIPLE) {
            revert Errors.MaximumNumberOfParticipantsReached(
                ID_MULTIPLE,
                _crowdtainer
            );
        }

        uint256 newTokenID = (ID_MULTIPLE * crowdtainerId) +
            nextAvailableTokenId;

        tokenIdQuantities[newTokenID] = _quantities;

        // Mint the voucher to the respective owner
        _safeMint(msg.sender, newTokenID);

        return newTokenID;
    }

    /**
     * @notice Join the specified Crowdtainer project with optional referral and discount, along with an ERC-2612 Permit.
     * @param _crowdtainer Crowdtainer project address.
     * @param _quantities Array with the number of units desired for each product.
     * @param _enableReferral Informs whether the user would like to be eligible to collect rewards for being referred.
     * @param _referrer Optional referral code to be used to claim a discount.
     * @param _signedPermit The ERC-2612 signed permit data.
     * @return The token id that represents the created voucher / ownership.
     *
     * @dev referrer is the wallet address of a previous participant.
     * @dev if `enableReferral` is true, and the user decides to leave after the wallet has been used to claim a discount,
     *       then the full value can't be claimed if deciding to leave the project.
     * @dev A same user is not allowed to increase the order amounts (i.e., by calling join multiple times).
     *      To 'update' an order, the user must first 'leave' then join again with the new values.
     */
    function join(
        address _crowdtainer,
        uint256[] calldata _quantities,
        bool _enableReferral,
        address _referrer,
        SignedPermit memory _signedPermit
    ) public returns (uint256) {
        IERC20Permit erc20token = IERC20Permit(
            address(Crowdtainer(_crowdtainer).token())
        );

        try
            erc20token.permit(
                _signedPermit.owner,
                _crowdtainer,
                _signedPermit.value,
                _signedPermit.deadline,
                _signedPermit.v,
                _signedPermit.r,
                _signedPermit.s
            )
        {
            return join(_crowdtainer, _quantities, _enableReferral, _referrer);
        } catch (bytes memory receivedBytes) {
            _bubbleRevert(receivedBytes);
        }
    }

    // @dev Function that calls a contract, and makes sure any revert 'bubbles up' and halts execution.
    // This function is used because there is no Solidity syntax to 'rethrow' custom errors within a try/catch,
    // other than comparing each error manually (which would unnecessarily increase code size / deployment costs).
    function _bubbleRevert(
        bytes memory receivedBytes
    ) internal pure returns (bytes memory) {
        if (receivedBytes.length == 0) revert();
        assembly {
            revert(add(32, receivedBytes), mload(receivedBytes))
        }
    }

    // @dev Extract abi encoded selector bytes
    function getSignature(bytes calldata data) external pure returns (bytes4) {
        assert(data.length >= 4);
        return bytes4(data[:4]);
    }

    // @dev Extract abi encoded parameters
    function getParameters(
        bytes calldata data
    ) external pure returns (bytes calldata) {
        assert(data.length > 4);
        return data[4:];
    }

    // @dev Decodes external Crowdtainer join function call errors.
    function handleJoinError(
        address crowdtainer,
        bytes memory receivedBytes
    ) private view {
        if (
            receivedBytes.length >= 4 &&
            this.getSignature(receivedBytes) == Errors.OffchainLookup.selector
        ) {
            // EIP-3668 OffchainLookup revert requires processing as below.
            // Namely, the 'sender' must be address(this), and not the inner contract address.
            (
                address sender,
                string[] memory urls,
                bytes memory callData,
                bytes4 callbackFunction,
                bytes memory extraData
            ) = abi.decode(
                    this.getParameters(receivedBytes),
                    (address, string[], bytes, bytes4, bytes)
                );

            if (sender != address(crowdtainer)) {
                revert Errors.CCIP_Read_InvalidOperation();
            }

            revert Errors.OffchainLookup(
                address(this),
                urls,
                callData,
                this.joinWithSignature.selector,
                abi.encode(address(crowdtainer), callbackFunction, extraData)
            );
        }
        // All other Crowdtainer.sol's errors can be propagated for decoding in external tooling.
        _bubbleRevert(receivedBytes);
    }

    /**
     * @notice Allows joining by means of CCIP-READ (EIP-3668).
     * @param result ABI encoded (uint64, bytes) for signature time validity and the signature itself.
     * @param extraData ABI encoded (address, bytes4, bytes), 3rd parameter contains encoded values for Crowdtainer._join() method.
     *
     * @dev Requires IRC20 permit.
     * @dev This function is called automatically by EIP-3668-compliant clients.
     */
    function joinWithSignature(
        bytes calldata result, // off-chain signed payload
        bytes calldata extraData // retained by client, passed for verification in this function
    ) public returns (uint256) {
        (
            address crowdtainer, // Address of Crowdtainer contract
            bytes4 innerCallbackFunction,
            bytes memory innerExtraData
        ) = abi.decode(extraData, (address, bytes4, bytes));

        require(
            innerCallbackFunction == Crowdtainer.joinWithSignature.selector
        );

        (address _wallet, uint256[] memory _quantities, , ) = abi.decode(
            innerExtraData,
            (address, uint256[], bool, address)
        );

        require(crowdtainer != address(0));
        uint256 crowdtainerId = idForCrowdtainer[crowdtainer];

        if (crowdtainerId == 0) {
            revert Errors.CrowdtainerInexistent();
        }

        require(crowdtainer.code.length > 0);

        uint256 costForWallet = Crowdtainer(crowdtainer).costForWallet(_wallet);

        try Crowdtainer(crowdtainer).joinWithSignature(result, innerExtraData) {
            // internal state invariant after joining
            assert(
                Crowdtainer(crowdtainer).costForWallet(_wallet) > costForWallet
            );
        } catch (bytes memory receivedBytes) {
            handleJoinError(crowdtainer, receivedBytes);
        }

        uint256 nextAvailableTokenId = ++nextTokenIdForCrowdtainer[
            crowdtainerId
        ];

        if (nextAvailableTokenId >= ID_MULTIPLE) {
            revert Errors.MaximumNumberOfParticipantsReached(
                ID_MULTIPLE,
                crowdtainer
            );
        }

        uint256 newTokenID = (ID_MULTIPLE * crowdtainerId) +
            nextAvailableTokenId;

        tokenIdQuantities[newTokenID] = _quantities;

        // Mint the voucher to the respective owner
        _safeMint(_wallet, newTokenID);

        return newTokenID;
    }

    /**
     * @notice Set ERC20's allowance using Permit, and call joinWithSignature(..), in a single call.
     * @param result ABI encoded (uint64, bytes) for signature time validity and the signature itself.
     * @param extraData ABI encoded (address, bytes4, bytes), 3rd parameter contains encoded values for Crowdtainer._join() method.
     * @param _signedPermit The ERC-2612 signed permit data.
     *
     * @dev This convenience function is *not* EIP-3668-compliant: the frontend needs to be aware of it to take advantage.
     */
    function joinWithSignatureAndPermit(
        bytes calldata result, // off-chain signed payload
        bytes calldata extraData, // retained by client, passed for verification in this function
        SignedPermit memory _signedPermit // Params to be forwarded to ERC-20 contract.
    ) external returns (uint256) {
        (address crowdtainer, , ) = abi.decode(
            extraData,
            (address, bytes4, bytes)
        );

        IERC20Permit erc20token = IERC20Permit(
            address(Crowdtainer(crowdtainer).token())
        );

        try
            erc20token.permit(
                _signedPermit.owner,
                crowdtainer,
                _signedPermit.value,
                _signedPermit.deadline,
                _signedPermit.v,
                _signedPermit.r,
                _signedPermit.s
            )
        {
            return joinWithSignature(result, extraData);
        } catch (bytes memory receivedBytes) {
            _bubbleRevert(receivedBytes);
        }
    }

    /**
     * @notice Returns the specified voucher and withdraw all deposited funds given when joining the Crowdtainer.
     * @notice Calling this method signals that the participant is no longer interested in the project.
     * @dev Only allowed if the respective Crowdtainer is in active funding state.
     */
    function leave(uint256 _tokenId) external {
        if (ownerOf(_tokenId) != msg.sender) {
            revert Errors.AccountNotOwner();
        }

        address crowdtainerAddress = crowdtainerIdToAddress(
            tokenIdToCrowdtainerId(_tokenId)
        );

        try ICrowdtainer(crowdtainerAddress).leave(msg.sender) {
            // internal state invariant after leaving
            assert(
                Crowdtainer(crowdtainerAddress).costForWallet(msg.sender) == 0
            );

            delete tokenIdQuantities[_tokenId];

            _burn(_tokenId);
        } catch (bytes memory receivedBytes) {
            _bubbleRevert(receivedBytes);
        }
    }

    /**
     * @notice Get the metadata representation.
     * @param _tokenId The encoded voucher token id.
     * @return Token URI String.
     */
    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        uint256 crowdtainerId = tokenIdToCrowdtainerId(_tokenId);
        address crowdtainerAddress = crowdtainerIdToAddress(crowdtainerId);

        ICrowdtainer crowdtainer = ICrowdtainer(crowdtainerAddress);

        uint256 numberOfProducts = crowdtainer.numberOfProducts();
        uint256[] memory unitPricePerType = new uint256[](numberOfProducts);

        for (uint256 i = 0; i < numberOfProducts; i++) {
            unitPricePerType[i] = crowdtainer.unitPricePerType(i);
        }

        IMetadataService metadataService = IMetadataService(
            metadataServiceForCrowdatinerId[crowdtainerId]
        );

        Metadata memory metadata = Metadata(
            crowdtainerId,
            _tokenId - (tokenIdToCrowdtainerId(_tokenId) * ID_MULTIPLE),
            ownerOf(_tokenId),
            getClaimStatus(_tokenId),
            unitPricePerType,
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
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        bool mintOrBurn = from == address(0) || to == address(0);
        if (mintOrBurn) return;

        // Transfers are only allowed after funding either succeeded or failed.
        address crowdtainerAddress = crowdtainerIdToAddress(
            tokenIdToCrowdtainerId(tokenId)
        );
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

    function tokenIdToCrowdtainerId(
        uint256 _tokenId
    ) public pure returns (uint256) {
        if (_tokenId == 0) {
            revert Errors.InvalidTokenId(_tokenId);
        }

        return _tokenId / ID_MULTIPLE;
    }

    function crowdtainerIdToAddress(
        uint256 _crowdtainerId
    ) public view returns (address) {
        address crowdtainerAddress = crowdtainerForId[_crowdtainerId];
        if (crowdtainerAddress == address(0)) {
            revert Errors.CrowdtainerInexistent();
        }
        return crowdtainerAddress;
    }

    function getClaimStatus(uint256 _tokenId) public view returns (bool) {
        return BitMaps.get(claimed, _tokenId);
    }

    function setClaimStatus(uint256 _tokenId, bool _value) public {
        address crowdtainerAddress = crowdtainerIdToAddress(
            tokenIdToCrowdtainerId(_tokenId)
        );

        ICrowdtainer crowdtainer = ICrowdtainer(crowdtainerAddress);

        address shippingAgent = crowdtainer.shippingAgent();

        if (msg.sender != shippingAgent) {
            revert Errors.SetClaimedOnlyAllowedByShippingAgent();
        }

        BitMaps.setTo(claimed, _tokenId, _value);
    }
}
