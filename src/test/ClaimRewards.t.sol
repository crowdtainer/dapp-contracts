// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.21;

import "./utils/CrowdtainerTest.sol";
import {Errors} from "../contracts/Crowdtainer.sol";

/* solhint-disable no-empty-blocks */

contract CrowdtainerRewardsTester is CrowdtainerTest {
    function testClaimRewardsMustSucceed() public {
        uint256[] memory _unitPricePerType = new uint256[](4);
        _unitPricePerType[0] = 10 * ONE;
        _unitPricePerType[1] = 20 * ONE;
        _unitPricePerType[2] = 25 * ONE;
        _unitPricePerType[3] = 5000 * ONE;

        crowdtainer.initialize(
            address(0),
            CampaignData(
                address(agent),
                address(0),
                openingTime,
                closingTime,
                20000 * ONE,
                30000 * ONE,
                _unitPricePerType,
                referralRate,
                referralEligibilityValue,
                address(iERC20Token),
                ""
            )
        );

        uint256[] memory quantities = new uint256[](4);
        quantities[0] = 1;
        quantities[1] = 10;

        bob.doJoin(quantities, true, address(0));

        uint256 previousBobBalance = erc20Token.balanceOf(address(bob));

        quantities[3] = 5;
        quantities[0] = 0;
        quantities[1] = 0;
        quantities[2] = 0;

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
