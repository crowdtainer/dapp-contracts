// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

import "./utils/CrowdtainerTest.sol";
import {Errors} from "../Crowdtainer.sol";

/* solhint-disable no-empty-blocks */

contract CrowdtainerValidLeaveTester is BaseTest {
    function testJoinThenLeaveWithoutReferralsMustSucceed() public {
        init();

        uint256 previousBalance = erc20Token.balanceOf(address(bob));

        uint256[MAX_NUMBER_OF_PRODUCTS] memory quantities = [
            uint256(0),
            2,
            10,
            0
        ];

        bob.doJoin(quantities, false, address(0));

        uint256 totalCost = quantities[1] * unitPricePerType[1];
        totalCost += quantities[2] * unitPricePerType[2];

        assertEq(
            erc20Token.balanceOf(address(bob)),
            (previousBalance - totalCost)
        );

        bob.doLeave();

        assertEq(erc20Token.balanceOf(address(bob)), previousBalance);
    }

    function testJoinAndLeaveWithReferralEnabledButNoRewardsAccumulated()
        public
    {
        init();
        uint256[MAX_NUMBER_OF_PRODUCTS] memory quantities = [
            uint256(1),
            2,
            10,
            0
        ];

        uint256 totalCost = quantities[0] * unitPricePerType[0];
        totalCost += quantities[1] * unitPricePerType[1];
        totalCost += quantities[2] * unitPricePerType[2];

        uint256 previousAliceBalance = erc20Token.balanceOf(address(alice));

        // alice enabled referrals to be eligible for rewards
        alice.doJoin(quantities, true, address(0));

        // alice paid full value to join (since no referral code was used)
        assertEq(
            erc20Token.balanceOf(address(alice)),
            previousAliceBalance - totalCost
        );

        // no one uses alice's referral code, and she decides to leave.
        alice.doLeave();

        // alice is back with her initial funds.
        assertEq(erc20Token.balanceOf(address(alice)), previousAliceBalance);
    }
}

contract CrowdtainerInvalidLeaveTester is BaseTest {
    function testFailJoinUsingReferralThenLeaveWithAccumulatedRewards() public {
        init();
        uint256[MAX_NUMBER_OF_PRODUCTS] memory quantities = [
            uint256(1),
            2,
            10,
            0
        ];

        uint256 totalCost = quantities[0] * unitPricePerType[0];
        totalCost += quantities[1] * unitPricePerType[1];
        totalCost += quantities[2] * unitPricePerType[2];
        uint256 discount = ((totalCost * referralRate) / 100) / 2;

        uint256 previousBobBalance = erc20Token.balanceOf(address(bob));

        bob.doJoin(quantities, true, address(0));

        // no discount for bob
        assertEq(
            erc20Token.balanceOf(address(bob)),
            previousBobBalance - totalCost
        );

        emit log_named_uint("Total cost:", totalCost);
        emit log_named_uint("Referral rate:", referralRate);
        emit log_named_uint("Discount:", discount);

        uint256 previousAliceBalance = erc20Token.balanceOf(address(alice));

        alice.doJoin(quantities, false, address(bob));

        assertEq(
            erc20Token.balanceOf(address(alice)),
            previousAliceBalance - (totalCost - discount)
        );

        // verify that bob received referral credits
        assertEq(crowdtainer.accumulatedRewardsOf(address(bob)), discount);

        bob.doLeave();
    }
}

//   ----------------------
//  | Fuzz tests           |
//   ----------------------
contract LeaveFuzzer is BaseTest {
    /* function testInvariantsHold(
        uint256 amountA,
        uint256 amountB,
        uint256 amountC
    ) public {
        init();

        if (amountA > MAX_NUMBER_OF_PURCHASED_ITEMS) return;
        if (amountB > MAX_NUMBER_OF_PURCHASED_ITEMS) return;
        if (amountC > MAX_NUMBER_OF_PURCHASED_ITEMS) return;

        uint256 previousAliceBalance = erc20Token.balanceOf(address(alice));

        uint256[MAX_NUMBER_OF_PRODUCTS] memory quantities = [
            amountA,
            amountB,
            amountC,
            0
        ];

        uint256 totalCost = 0;
        for (uint256 i = 0; i < MAX_NUMBER_OF_PRODUCTS; i++) {
            totalCost += unitPricePerType[i] * quantities[i];
        }

        alice.doLeave();

        assertEq(
            erc20Token.balanceOf(address(alice)),
            (previousAliceBalance - totalCost)
        );
    } */
}

//   ----------------------
//  | Symbolic Execution   |
//   ----------------------
contract LeaveProver is BaseTest {
    /*function proveAllSanityChecks(
        uint256 amountA, uint256 amountB, uint256 amountC
    ) public {

        crowdtainer.initialize(
            openingTime,
            closingTime,
            targetMinimum,
            targetMaximum,
            unitPricePerType,
            referralRate,
            erc20Token
        );

        // Remove unrealistic values from branch exploration
        if(amountA > MAX_NUMBER_OF_PURCHASED_ITEMS) return;
        if(amountB > MAX_NUMBER_OF_PURCHASED_ITEMS) return;
        if(amountC > MAX_NUMBER_OF_PURCHASED_ITEMS) return;
    
        uint256 previousAliceBalance = erc20Token.balanceOf(address(alice));

        uint256[MAX_NUMBER_OF_PRODUCTS] memory quantities = [amountA, amountB, amountC];

        uint256 totalCost = 0;
        for (uint256 i = 0; i < MAX_NUMBER_OF_PRODUCTS; i++) {
            totalCost += unitPricePerType[i] * quantities[i];
        }

        alice.doLeave(quantities, bytes32(0x0), "");

        assertEq(erc20Token.balanceOf(address(alice)), (previousAliceBalance - totalCost));
    }*/
}
/* solhint-enable no-empty-blocks */
