// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "./States.sol";

library Errors {
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
    // @notice: Initialize called with invalid number of product types: must be > 0 and smaller than `MAX_NUMBER_OF_PRODUCTS`.
    error InvalidNumberOfProductTypes();
    // @notice: Initialize called with invalid referral rate.
    error InvalidReferralRate(uint256 received, uint256 maximum);
    // @notice: The given referral was not created and thus can't be used to claim a discount.
    error ReferralCodeInexistent();
    // @notice: An account can't refer itself to claim a discount.
    error CannotReferItself();
    // @notice: Referral code already used by another account.
    error ReferralCodeAlreadyUsed();
    // @notice: Purchase exceed target's maximum goal.
    error PurchaseExceedsMaximumTarget();

    // -----------------------------------------------
    //  Authorization
    // -----------------------------------------------
    // @notice: Method not authorized for caller (message sender)
    error CallerNotAllowed(address expected, address actual);

    // -----------------------------------------------
    //  State transition
    // -----------------------------------------------
    // @notice: Invalid state transition
    error InvalidStateTransition(CrowdtainerState from, CrowdtainerState to);
    // @notice: Method can't be invoked at current state
    error InvalidOperationFor(CrowdtainerState state);

    // -----------------------------------------------
    //  Other Invariants
    // -----------------------------------------------
    // @notice: Payable receive function called, but we don't accept Eth for payment
    error ContractDoesNotAcceptEther();
}
