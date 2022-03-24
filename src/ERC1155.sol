// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

import "@openzeppelin/openzeppelin-contracts/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/openzeppelin-contracts/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/openzeppelin-contracts/contracts/utils/Address.sol";

// @dev Internal dependencies
import "./Constants.sol";
import "./Errors.sol";

/**
 * A simple implementation of ERC1155 for Crowdtainer. Based on OpenZeppelin implementation,
 * with the following modifications:
 * - Use of custom errors instead of revert with strings.
 * - Added method _revertIfNotTransferable(tokenId) instead of OpenZeppelin "hooks".
 */
abstract contract ERC1155 is ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from owner => operator => approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // @dev Mapping of token ID => account => balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id)
        public
        view
        virtual
        override
        returns (uint256)
    {
        if (account == address(0)) revert Errors.AccountAddressIsZero(); // "ERC1155: balance query for the zero address"

        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        if (accounts.length != ids.length)
            revert Errors.AccountIdsLengthMismatch(); // "ERC1155: accounts and ids length mismatch"

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        if (msg.sender == operator) revert Errors.CannotSetApprovalForSelf(); // "ERC1155: setting approval status for self"

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        if (to == address(0)) revert Errors.AccountAddressIsZero(); // "ERC1155: balance query for the zero address"

        bool allowed = from == msg.sender || isApprovedForAll(from, msg.sender);
        if (!allowed) revert Errors.AccountNotOwnerOrApproved(); // "ERC1155: caller is not owner nor approved"

        _revertIfNotTransferable(id);

        uint256 fromBalance = _balances[id][from];
        if (fromBalance < amount) revert Errors.InsufficientBalance(); // ERC1155: insufficient balance for transfer

        _balances[id][from] = fromBalance - amount;
        _balances[id][to] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(msg.sender, from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        if (amounts.length != ids.length)
            revert Errors.IDsAmountsLengthMismatch(); // ERC1155: amounts and ids length mismatch

        if (to == address(0)) revert Errors.AccountAddressIsZero(); // ERC1155: balance query for the zero address

        bool allowed = from == msg.sender || isApprovedForAll(from, msg.sender);
        if (!allowed) revert Errors.AccountNotOwnerOrApproved(); // ERC1155: caller is not owner nor approved

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];

            _revertIfNotTransferable(id);

            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            if (fromBalance < amount) revert Errors.InsufficientBalance(); // ERC1155: insufficient balance for transfer

            _balances[id][from] = fromBalance - amount;
            _balances[id][to] += amount;
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(
            msg.sender,
            from,
            to,
            ids,
            amounts,
            data
        );
    }

    /**************************************************************************
     * Internal/private methods
     *************************************************************************/

    function _revertIfNotTransferable(uint256 tokenId) internal virtual;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        if (to == address(0)) revert Errors.AccountAddressIsZero(); // ERC1155: mint to address zero

        if (amounts.length != ids.length)
            revert Errors.IDsAmountsLengthMismatch(); // ERC1155: amounts and ids length mismatch

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(
            msg.sender,
            address(0),
            to,
            ids,
            amounts,
            ""
        );
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount
    ) internal virtual {
        if (to == address(0)) revert Errors.AccountAddressIsZero(); // ERC1155: mint to address zero

        _balances[id][to] += amount;
        emit TransferSingle(msg.sender, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(
            msg.sender,
            address(0),
            to,
            id,
            amount,
            ""
        );
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 tokenId,
        uint256 amount
    ) internal virtual {
        if (from == address(0)) revert Errors.AccountAddressIsZero(); // ERC1155: burn from the zero address

        uint256 fromBalance = _balances[tokenId][from];
        if (fromBalance < amount) revert Errors.InsufficientBalance(); // ERC1155: burn amount exceeds balance

        _balances[tokenId][from] = fromBalance - amount;

        emit TransferSingle(msg.sender, from, address(0), tokenId, amount);
    }

    function _asSingletonArray(uint256 element)
        private
        pure
        returns (uint256[] memory)
    {
        uint256[] memory array = new uint256[](1);
        array[0] = element;
        return array;
    }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
                if (
                    response != IERC1155Receiver(to).onERC1155Received.selector
                ) {
                    revert Errors.ERC1155ReceiverRejectedTokens(); // ERC1155: ERC1155Receiver rejected tokens
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert Errors.NonERC1155Receiver(); // ERC1155: transfer to non ERC1155Receiver implementer
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response !=
                    IERC1155Receiver(to).onERC1155BatchReceived.selector
                ) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }
}
