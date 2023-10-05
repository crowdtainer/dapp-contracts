// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

// @dev External dependencies
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
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

    /**
     * @notice Create and deploy a new Crowdtainer manager.
     * @dev Uses contract factory pattern.
     * @param _crowdtainerImplementation the address of the reference implementation.
     */
    constructor(
        address _crowdtainerImplementation
    ) ERC721("Vouchers721", "VV1") {
        // equivalent to: crowdtainerImplementation = address(new Crowdtainer(address(this)));.
        crowdtainerImplementation = _crowdtainerImplementation;
        emit Vouchers721Created(address(this));
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
    ) external returns (address, uint256) {
        if (_metadataService == address(0)) {
            revert Errors.MetadataServiceAddressIsZero();
        }

        ICrowdtainer crowdtainer = ICrowdtainer(
            Clones.clone(crowdtainerImplementation)
        );
        // ICrowdtainer crowdtainer = ICrowdtainer(new Crowdtainer());

        crowdtainer.initialize(address(this), _campaignData);

        idForCrowdtainer[address(crowdtainer)] = ++crowdtainerCount;
        crowdtainerForId[crowdtainerCount] = address(crowdtainer);

        productDescription[crowdtainerCount] = _productDescription;
        metadataServiceForCrowdatinerId[crowdtainerCount] = _metadataService;
        emit CrowdtainerDeployed(address(crowdtainer), crowdtainerCount);

        return (address(crowdtainer), crowdtainerCount);
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
    ) external returns (uint256) {
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

    // @dev Decodes external Crowdtainer join function call errors.
    // Most of this function code can be removed once Solidity supports
    // 'rethrowing' an external call's custom error revert.
    function handleJoinError(
        address crowdtainer,
        bytes memory receivedBytes
    ) private view {
        bytes4 receivedErrorSelector = this.getSignature(receivedBytes);

        if (receivedErrorSelector == Errors.OffchainLookup.selector) {
            // decode error parameters
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
                Vouchers721.joinWithSignature.selector,
                abi.encode(address(crowdtainer), callbackFunction, extraData)
            );
        } else if (receivedErrorSelector == Errors.SignatureExpired.selector) {
            (uint64 current, uint64 expires) = abi.decode(
                this.getParameters(receivedBytes),
                (uint64, uint64)
            );
            revert Errors.SignatureExpired(current, expires);
        } else if (receivedErrorSelector == Errors.CallerNotAllowed.selector) {
            (address expected, address actual) = abi.decode(
                this.getParameters(receivedBytes),
                (address, address)
            );
            revert Errors.CallerNotAllowed(expected, actual);
        } else if (
            receivedErrorSelector ==
            Errors.InvalidProductNumberAndPrices.selector
        ) {
            revert Errors.InvalidProductNumberAndPrices();
        } else if (
            receivedErrorSelector == Errors.InvalidNumberOfQuantities.selector
        ) {
            revert Errors.InvalidNumberOfQuantities();
        } else if (
            receivedErrorSelector == Errors.ReferralInexistent.selector
        ) {
            revert Errors.ReferralInexistent();
        } else if (
            receivedErrorSelector ==
            Errors.PurchaseExceedsMaximumTarget.selector
        ) {
            (uint256 received, uint256 maximum) = abi.decode(
                this.getParameters(receivedBytes),
                (uint256, uint256)
            );
            revert Errors.PurchaseExceedsMaximumTarget(received, maximum);
        } else if (
            receivedErrorSelector ==
            Errors.ExceededNumberOfItemsAllowed.selector
        ) {
            (uint256 received, uint256 maximum) = abi.decode(
                this.getParameters(receivedBytes),
                (uint256, uint256)
            );
            revert Errors.ExceededNumberOfItemsAllowed(received, maximum);
        } else if (receivedErrorSelector == Errors.UserAlreadyJoined.selector) {
            revert Errors.UserAlreadyJoined();
        } else if (
            receivedErrorSelector ==
            Errors.ReferralDisabledForProvidedCode.selector
        ) {
            revert Errors.ReferralDisabledForProvidedCode();
        } else if (
            receivedErrorSelector ==
            Errors.MinimumPurchaseValueForReferralNotMet.selector
        ) {
            (uint256 received, uint256 maximum) = abi.decode(
                this.getParameters(receivedBytes),
                (uint256, uint256)
            );
            revert Errors.MinimumPurchaseValueForReferralNotMet(
                received,
                maximum
            );
        } else if (
            receivedErrorSelector ==
            Errors.NonceAlreadyUsed.selector
        ) {
            (address wallet, bytes32 nonce) = abi.decode(
                this.getParameters(receivedBytes),
                (address, bytes32)
            );
            revert Errors.NonceAlreadyUsed(wallet, nonce);
        }
        else {
            // other
            revert Errors.CrowdtainerLowLevelError(receivedBytes);
        }
    }

    function getSignature(bytes calldata data) external pure returns (bytes4) {
        require(data.length >= 4);
        return bytes4(data[:4]);
    }

    function getParameters(
        bytes calldata data
    ) external pure returns (bytes calldata) {
        require(data.length > 4);
        return data[4:];
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
    ) external returns (uint256) {
        (
            address crowdtainer, // Address of Crowdtainer contract
            bytes4 innerCallbackFunction,
            bytes memory innerExtraData
        ) = abi.decode(extraData, (address, bytes4, bytes));

        require(innerCallbackFunction == Crowdtainer.joinWithSignature.selector);
    
        (address _wallet, uint256[] memory _quantities, , ) = abi.decode(
            innerExtraData,
            (address, uint256[], bool, address)
        );

        if (msg.sender != _wallet)
            revert Errors.CallerNotAllowed({
                expected: _wallet,
                actual: msg.sender
            });

        require(crowdtainer != address(0));
        uint256 crowdtainerId = idForCrowdtainer[crowdtainer];

        if (crowdtainerId == 0) {
            revert Errors.CrowdtainerInexistent();
        }

        require(crowdtainer.code.length > 0);

        uint256 costForWallet = Crowdtainer(crowdtainer).costForWallet(_wallet);
        try Crowdtainer(crowdtainer).joinWithSignature(result, innerExtraData) {
            // internal state invariant after joining
            require(
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

        try Crowdtainer(crowdtainerAddress).leave(msg.sender) {
            // internal state invariant after leaving
            require(
                Crowdtainer(crowdtainerAddress).costForWallet(msg.sender) == 0
            );
        } catch (bytes memory receivedBytes) {
            bytes4 receivedErrorSelector = this.getSignature(receivedBytes);

            if (
                receivedErrorSelector ==
                Errors.CannotLeaveDueAccumulatedReferralCredits.selector
            ) {
                revert Errors.CannotLeaveDueAccumulatedReferralCredits();
            } else if (
                receivedErrorSelector == Errors.CallerNotAllowed.selector
            ) {
                (address expected, address actual) = abi.decode(
                    this.getParameters(receivedBytes),
                    (address, address)
                );
                revert Errors.CallerNotAllowed(expected, actual);
            } else {
                revert Errors.CrowdtainerLowLevelError(receivedBytes);
            }
        }

        delete tokenIdQuantities[_tokenId];

        _burn(_tokenId);
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
