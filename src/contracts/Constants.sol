// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

// -----------------------------------------------
//  Safety margins to avoid impractical values
// -----------------------------------------------
// @notice Safety time buffer to avoid expiration time too close to the opening time.
uint256 constant SAFETY_TIME_RANGE = 1 hours;
// @notice Maximum value for referral discounts and rewards
uint256 constant SAFETY_MAX_REFERRAL_RATE = 50;
// @notice Maximum number of items per type on each purchase/join.
uint256 constant MAX_NUMBER_OF_PURCHASED_ITEMS = 200;
// @notice Maximum time the service provider has to react after campaigm reaches target, 
// otherwise the campaign can be still put into failed state, in case of unresponsive service providers.
uint256 constant MAX_UNRESPONSIVE_TIME = 30 days;