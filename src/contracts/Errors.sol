// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.21;

import "./States.sol";

library Errors {
    // -----------------------------------------------
    //  Vouchers
    // -----------------------------------------------
    // @notice: The provided crowdtainer does not exist.
    error CrowdtainerInexistent();
    // @notice: Invalid token id.
    error InvalidTokenId(uint256 tokenId);
    // @notice: Prices lower than 1 * 1^6 not supported.
    error PriceTooLow();
    // @notice: Attempted to join with all product quantities set to zero.
    error InvalidNumberOfQuantities();
    // @notice: Account cannot be of address(0).
    error AccountAddressIsZero();
    // @notice: Metadata service contract cannot be of address(0).
    error MetadataServiceAddressIsZero();
    // @notice: Accounts and ids lengths do not match.
    error AccountIdsLengthMismatch();
    // @notice: ID's and amounts lengths do not match.
    error IDsAmountsLengthMismatch();
    // @notice: Cannot set approval for the same account.
    error CannotSetApprovalForSelf();
    // @notice: Caller is not owner or has correct permission.
    error AccountNotOwner();
    // @notice: Only the shipping agent is able to set a voucher/tokenId as "claimed".
    error SetClaimedOnlyAllowedByShippingAgent();
    // @notice: Cannot transfer someone else's tokens.
    error UnauthorizedTransfer();
    // @notice: Insufficient balance.
    error InsufficientBalance();
    // @notice: Quantities input length doesn't match number of available products.
    error InvalidProductNumberAndPrices();
    // @notice: Can't make transfers in given state.
    error TransferNotAllowed(address crowdtainer, CrowdtainerState state);
    // @notice: No further participants possible in a given Crowdtainer.
    error MaximumNumberOfParticipantsReached(
        uint256 maximum,
        address crowdtainer
    );
    // Used to apply off-chain verifications/rules per CCIP-read (EIP-3668),
    // see https://eips.ethereum.org/EIPS/eip-3668 for description.
    error OffchainLookup(
        address sender,
        string[] urls,
        bytes callData,
        bytes4 callbackFunction,
        bytes extraData
    );

    error CCIP_Read_InvalidOperation();
    error SignatureExpired(uint64 current, uint64 expires);
    error NonceAlreadyUsed(address wallet, bytes32 nonce);
    error InvalidSignature();
    // Errors that occur inside external function calls, provided without decoding.
    error CrowdtainerLowLevelError(bytes reason);

    // -----------------------------------------------
    //  Initialization with invalid parameters
    // -----------------------------------------------
    // @notice: Cannot initialize with owner of address(0).
    error OwnerAddressIsZero();
    // @notice: Cannot initialize with token of address(0).
    error TokenAddressIsZero();
    // @notice: Shipping agent can't have address(0).
    error ShippingAgentAddressIsZero();
    // @notice: Initialize called with closing time is less than one hour away from the opening time.
    error ClosingTimeTooEarly();
    // @notice: Initialize called with invalid number of maximum units to be sold (0).
    error InvalidMaximumTarget();
    // @notice: Initialize called with invalid number of minimum units to be sold (less than maximum sold units).
    error InvalidMinimumTarget();
    // @notice: Initialize called with invalid minimum and maximum targets (minimum value higher than maximum).
    error MinimumTargetHigherThanMaximum();
    // @notice: Initialize called with invalid referral rate.
    error InvalidReferralRate(uint256 received, uint256 maximum);
    // @notice: Referral rate not multiple of 2.
    error ReferralRateNotMultipleOfTwo();
    // @notice: Refferal minimum value for participation can't be higher than project's minimum target.
    error ReferralMinimumValueTooHigh(uint256 received, uint256 maximum);

    // -----------------------------------------------
    //  Authorization
    // -----------------------------------------------
    // @notice: Method not authorized for caller (message sender).
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
    // @notice: Referral is not enabled for the given code/wallet.
    error ReferralDisabledForProvidedCode();
    // @notice: Participant can't participate in referral if the minimum purchase value specified by the service provider is not met.
    error MinimumPurchaseValueForReferralNotMet(
        uint256 received,
        uint256 minimum
    );

    // -----------------------------------------------
    //  Leave() operation
    // -----------------------------------------------
    // @notice: It is not possible to leave when the user has referrals enabled, has been referred and gained rewards.
    error CannotLeaveDueAccumulatedReferralCredits();

    // -----------------------------------------------
    //  GetPaidAndDeliver() operation
    // -----------------------------------------------
    // @notice: GetPaidAndDeliver can't be called on a expired project.
    error CrowdtainerExpired(uint256 timestamp, uint256 expiredTime);
    // @notice: Not enough funds were raised.
    error MinimumTargetNotReached(uint256 minimum, uint256 actual);
    // @notice: The project is not active yet.
    error OpeningTimeNotReachedYet(uint256 timestamp, uint256 openingTime);

    // -----------------------------------------------
    //  ClaimFunds() operation
    // -----------------------------------------------
    // @notice: Can't be called if the project is still active.
    error CantClaimFundsOnActiveProject();

    // -----------------------------------------------
    //  State transition
    // -----------------------------------------------
    // @notice: Method can't be invoked at current state.
    error InvalidOperationFor(CrowdtainerState state);

    // -----------------------------------------------
    //  Other Invariants
    // -----------------------------------------------
    // @notice: Payable receive function called, but we don't accept Eth for payment.
    error ContractDoesNotAcceptEther();
}
