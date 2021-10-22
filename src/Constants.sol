// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

// -----------------------------------------------
//  Safety margins to avoid impractical values
// -----------------------------------------------
uint256 constant SAFETY_TIME_RANGE = 1 hours;
// @notice Maximum value for referral discounts and rewards
uint256 constant SAFETY_MAX_REFERRAL_RATE = 50;
// @notice Maximum number of different products.
uint256 constant MAX_NUMBER_OF_PRODUCTS = 3;
