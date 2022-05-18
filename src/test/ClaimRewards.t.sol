// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

import "./utils/CrowdtainerTest.sol";
import {Errors} from "../contracts/Crowdtainer.sol";

/* solhint-disable no-empty-blocks */

contract CrowdtainerRewardsTester is CrowdtainerTest {
    function testClaimRewardsMustSucceed() public {
        uint256[MAX_NUMBER_OF_PRODUCTS] memory _unitPricePerType = [
            uint256(10) * ONE,
            20 * ONE,
            25 * ONE,
            5000 * ONE
        ];

        crowdtainer.initialize(
            address(0),
            CampaignData(
                address(agent),
                openingTime,
                closingTime,
                20000 * ONE,
                30000 * ONE,
                _unitPricePerType,
                referralRate,
                referralEligibilityValue,
                address(iERC20Token)
            )
        );

        uint256[MAX_NUMBER_OF_PRODUCTS] memory quantities = [
            uint256(1),
            10,
            0,
            0
        ];

        bob.doJoin(quantities, true, address(0));

        uint256 previousBobBalance = erc20Token.balanceOf(address(bob));

        quantities = [uint256(0), 0, 0, 5];

        uint256 totalCost = quantities[3] * _unitPricePerType[3];

        uint256 discount = ((totalCost * referralRate) / 100) / 2;
        assert(discount != 0);

        uint256 previousAliceBalance = erc20Token.balanceOf(address(alice));

        alice.doJoin(quantities, true, address(bob));

        assertEq(
            erc20Token.balanceOf(address(alice)),
            previousAliceBalance - (totalCost - discount)
        );

        // verify that bob received referral credits
        assertEq(crowdtainer.accumulatedRewardsOf(address(bob)), discount);

        agent.doGetPaidAndDeliver();

        bob.doClaimRewards();

        assertEq(
            erc20Token.balanceOf(address(bob)),
            previousBobBalance + discount
        );
    }
}

/* solhint-enable no-empty-blocks */
