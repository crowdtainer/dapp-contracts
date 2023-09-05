// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

// -----------------------------------------------
//  Safety margins to avoid impractical values
// -----------------------------------------------
uint256 constant SAFETY_TIME_RANGE = 1 hours;
// @notice Maximum value for referral discounts and rewards
uint256 constant SAFETY_MAX_REFERRAL_RATE = 50;
// @notice Maximum number of different products for a given Crowdtainer deployment.
uint256 constant MAX_NUMBER_OF_PRODUCTS = 4;
// @notice Maximum number of items per type on each purchase/join.
uint256 constant MAX_NUMBER_OF_PURCHASED_ITEMS = 200;
