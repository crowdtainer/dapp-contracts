// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import "./utils/CrowdtainerTest.sol";
import {Errors} from "../contracts/Crowdtainer.sol";

/* solhint-disable no-empty-blocks */

contract CrowdtainerValidLeaveTester is CrowdtainerTest {
    function testJoinThenLeaveWithoutReferralsMustSucceed() public {
        init();

        uint256 previousBalance = erc20Token.balanceOf(address(bob));

        uint256[] memory quantities = new uint256[](4);
        quantities[1] = 2;
        quantities[2] = 10;

        try bob.doJoin(quantities, false, address(0)) {} catch (bytes memory) {
            fail();
        }

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
        uint256[] memory quantities = new uint256[](4);
        quantities[0] = 1;
        quantities[1] = 2;
        quantities[2] = 10;

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

    function testJoinAndLeaveMustHaveAccumulatedRewardsAsZero() public {
        init();

        uint256[] memory quantities = new uint256[](4);
        quantities[0] = 1;
        quantities[1] = 2;
        quantities[2] = 10;

        uint256 totalCost = quantities[0] * unitPricePerType[0];
        totalCost += quantities[1] * unitPricePerType[1];
        totalCost += quantities[2] * unitPricePerType[2];
        uint256 discount = ((totalCost * referralRate) / 100) / 2;

        uint256 previousBobBalance = erc20Token.balanceOf(address(bob));

        try bob.doJoin(quantities, true, address(0)) {} catch (bytes memory) {
            fail();
        }

        // no discount for bob
        assertEq(
            erc20Token.balanceOf(address(bob)),
            previousBobBalance - totalCost
        );

        emit log_named_uint("Total cost:", totalCost);
        emit log_named_uint("Referral rate:", referralRate);
        emit log_named_uint("Discount:", discount);

        uint256 previousAliceBalance = erc20Token.balanceOf(address(alice));

        // alice joins with discount
        try alice.doJoin(quantities, false, address(bob)) {} catch (
            bytes memory
        ) {
            fail();
        }

        assertEq(
            erc20Token.balanceOf(address(alice)),
            previousAliceBalance - (totalCost - discount)
        );

        // verify that bob received referral credits
        assertEq(crowdtainer.accumulatedRewardsOf(address(bob)), discount);

        // alice leaves
        alice.doLeave();

        // verify that bob's received referral credits is back to zero
        assertEq(crowdtainer.accumulatedRewardsOf(address(bob)), 0);

        // verify that contract reward accumulator is back to zero
        assertEq(crowdtainer.accumulatedRewards(), 0);
    }
}

contract CrowdtainerInvalidLeaveTester is CrowdtainerTest {
    function testFailJoinUsingReferralThenLeaveWithAccumulatedRewards() public {
        init();

        uint256[] memory quantities = new uint256[](4);
        quantities[0] = 1;
        quantities[1] = 2;
        quantities[2] = 10;

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

        try bob.doLeave() {} catch (bytes memory) {
            if (crowdtainer.costForWallet(address(bob)) != 0) {
                fail();
            }
        }
    }
}

//   ----------------------
//  | Fuzz tests           |
//   ----------------------
contract LeaveFuzzer is CrowdtainerTest {
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

        uint256[] memory quantities = [
            amountA,
            amountB,
            amountC,
            0
        ];

        uint256 totalCost = 0;
        for (uint256 i = 0; i < ; i++) {
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
contract LeaveProver is CrowdtainerTest {
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

        uint256[] memory quantities = [amountA, amountB, amountC];

        uint256 totalCost = 0;
        for (uint256 i = 0; i < ; i++) {
            totalCost += unitPricePerType[i] * quantities[i];
        }

        alice.doLeave(quantities, bytes32(0x0), "");

        assertEq(erc20Token.balanceOf(address(alice)), (previousAliceBalance - totalCost));
    }*/
}
/* solhint-enable no-empty-blocks */
