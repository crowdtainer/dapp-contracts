// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import "./States.sol";

library Errors {
    // -----------------------------------------------
    //  EIP1155
    //
    // @notice: Account cannot be of address(0)
    error AccountAddressIsZero();
    // @notice: Accounts and ids lengths do not match
    error AccountIdsLengthMismatch();
    // @notice: ID's and amounts lengths do not match
    error IDsAmountsLengthMismatch();
    // @notice: Cannot set approval for the same account
    error CannotSetApprovalForSelf();
    // @notice: Caller is not owner nor approved
    error AccountNotOwnerOrApproved();
    // @notice: Cannot transfer someone else's tokens
    error UnauthorizedTransfer();
    // @notice: Insufficient balance
    error InsufficientBalance();
    // @notice: ERC1155: ERC1155Receiver rejected tokens
    error ERC1155ReceiverRejectedTokens();
    // @notice: Invalid receiver (non ERC155Receiver)
    error NonERC1155Receiver();

    // -----------------------------------------------
    //  Initialization with invalid parameters
    // -----------------------------------------------
    // @notice: Cannot initialize with owner of address(0)
    error OwnerAddressIsZero();
    // @notice: Cannot initialize with token of address(0)
    error TokenAddressIsZero();
    // @notice: Initialize called with closing time is less than one hour away from the opening time
    error ClosingTimeTooEarly();
    // @notice: Initialize called with invalid number of maximum units to be sold (0)
    error InvalidMaximumTarget();
    // @notice: Initialize called with invalid number of minimum units to be sold (less than maximum sold units)
    error InvalidMinimumTarget();
    // @notice: Initialize called with invalid minimum and maximum targets (minimum value higher than maximum)
    error MinimumTargetHigherThanMaximum();
    // @notice: Initialize called with invalid referral rate.
    error InvalidReferralRate(uint256 received, uint256 maximum);
    // @notice: Referral rate not multiple of 2.
    error ReferralRateNotMultipleOfTwo();

    // -----------------------------------------------
    //  Authorization
    // -----------------------------------------------
    // @notice: Method not authorized for caller (message sender)
    error CallerNotAllowed(address expected, address actual);

    // -----------------------------------------------
    //  Join() operation
    // -----------------------------------------------
    // @notice: The given referral was not found thus can't be used to claim a discount.
    error ReferralInexistent();
    // @notice: Purchase exceed target's maximum goal.
    error PurchaseExceedsMaximumTarget(uint256 received, uint256 maximum);
    // @notice: Number of items purchased per type exceeds maximum allowed.
    error ExceededNumberOfItemsAllowed(uint256 received, uint256 maximum);
    // @notice: Wallet already used to join project.
    error UserAlreadyJoined();
    // @notice: Referral is not enabled for the given wallet.
    error ReferralDisabled();

    // -----------------------------------------------
    //  GetPaidAndDeliver() operation
    // -----------------------------------------------
    // @notice: GetPaidAndDeliver can't be called on a expired project.
    error CrowdtainerExpired(uint256 timestamp, uint256 expiredTime);
    // @notice: Not enough funds were raised.
    error MinimumTargetNotReached(uint256 minimum, uint256 actual);

    error OpeningTimeNotReachedYet(uint256 timestamp, uint256 openingTime);

    // -----------------------------------------------
    //  ClaimFunds() operation
    // -----------------------------------------------
    // @notice: Can't be called if the project is still active.
    error CantClaimFundsOnActiveProject();

    // -----------------------------------------------
    //  State transition
    // -----------------------------------------------
    // @notice: Method can't be invoked at current state
    error InvalidOperationFor(CrowdtainerState state);

    // -----------------------------------------------
    //  ERC-1155
    // -----------------------------------------------
    // @notice: Can't make transfers in given state.
    error TransferNotAllowed(address crowdtainer, CrowdtainerState state);

    // -----------------------------------------------
    //  Other Invariants
    // -----------------------------------------------
    // @notice: Payable receive function called, but we don't accept Eth for payment
    error ContractDoesNotAcceptEther();
}
