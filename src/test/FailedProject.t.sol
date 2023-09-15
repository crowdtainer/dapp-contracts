// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import "./utils/CrowdtainerTest.sol";
import {Errors} from "../contracts/Crowdtainer.sol";
import "../contracts/States.sol";

/* solhint-disable no-empty-blocks */

contract CrowdtainerValidProjectTerminationTester is CrowdtainerTest {
    function testAbortDuringFundingPhaseMustSucceed() public {
        init();

        uint256 previousBalance = erc20Token.balanceOf(address(bob));

        uint256[] memory quantities = new uint256[](4);
        quantities[1] = 2;
        quantities[2] = 10;

        bob.doJoin(quantities, false, address(0));

        uint256 totalCost = quantities[1] * unitPricePerType[1];
        totalCost += quantities[2] * unitPricePerType[2];

        assertEq(
            erc20Token.balanceOf(address(bob)),
            previousBalance - totalCost
        );

        agent.doAbortProject();

        assert(crowdtainer.crowdtainerState() == CrowdtainerState.Failed);

        bob.doClaimFunds();

        assertEq(erc20Token.balanceOf(address(bob)), previousBalance);
    }

    function testFailClaimFundsBeforeOpeningTime() public {
        init();

        uint256 previousBalance = erc20Token.balanceOf(address(bob));

        uint256[] memory quantities = new uint256[](4);
        quantities[1] = 2;

        uint256 totalCost = quantities[1] * unitPricePerType[1];

        bob.doJoin(quantities, false, address(0));

        hevm.warp(openingTime - 1 seconds);

        try bob.doClaimFunds() {} catch (bytes memory lowLevelData) {
            bool failed = this.isEqualSignature(
                makeError(Errors.OpeningTimeNotReachedYet.selector),
                lowLevelData
            ) &&
                (erc20Token.balanceOf(address(bob)) ==
                    (previousBalance - totalCost));

            if (failed) fail();
        }
    }

    function testFailClaimFundsOnActiveProject() public {
        init();

        uint256 previousBalance = erc20Token.balanceOf(address(bob));

        uint256[] memory quantities = new uint256[](4);
        quantities[1] = 2;

        uint256 totalCost = quantities[1] * unitPricePerType[1];

        bob.doJoin(quantities, false, address(0));

        try bob.doClaimFunds() {} catch (bytes memory lowLevelData) {
            bool failed = this.isEqualSignature(
                makeError(Errors.CantClaimFundsOnActiveProject.selector),
                lowLevelData
            ) &&
                (erc20Token.balanceOf(address(bob)) ==
                    (previousBalance - totalCost));
            if (failed) fail();
        }
    }

    function testClaimFundsOnFailedProject() public {
        init();

        assert(crowdtainer.crowdtainerState() == CrowdtainerState.Funding);

        uint256 previousBalance = erc20Token.balanceOf(address(bob));

        uint256[] memory quantities = new uint256[](4);
        quantities[1] = 2;

        uint256 totalCost = quantities[1] * unitPricePerType[1];

        bob.doJoin(quantities, false, address(0));

        assertEq(
            erc20Token.balanceOf(address(bob)),
            previousBalance - totalCost
        );

        hevm.warp(closingTime + 1 seconds);

        try bob.doClaimFunds() {} catch (bytes memory) {
            fail();
        }

        assertEq(erc20Token.balanceOf(address(bob)), previousBalance);
    }
}

contract CrowdtainerInvalidProjectTerminationTester is CrowdtainerTest {
    function testFailAbortDuringDeliveryPhase() public {
        // Create a crowdtainer where targetMinimum is small enough that a single user could
        // make the project succeed with a single join() call.
        uint256[] memory _unitPricePerType = new uint256[](4);
        _unitPricePerType[0] = 100 * ONE;
        _unitPricePerType[1] = 200 * ONE;
        _unitPricePerType[2] = 300 * ONE;
        _unitPricePerType[3] = ONE;

        uint256 _targetMinimum = 3000 * ONE;
        uint256 _targetMaximum = 4000 * ONE;

        crowdtainer.initialize(
            address(0),
            CampaignData(
                address(agent),
                address(0),
                openingTime,
                closingTime,
                _targetMinimum,
                _targetMaximum,
                _unitPricePerType,
                referralRate,
                referralEligibilityValue,
                address(iERC20Token),
                ""
            )
        );

        // one user buys enough to succeed the crowdtainer project
        uint256[] memory quantities = new uint256[](4);
        quantities[2] = 10;

        alice.doJoin(quantities, false, address(0));

        agent.doGetPaidAndDeliver();
        assert(crowdtainer.crowdtainerState() == CrowdtainerState.Delivery);

        try agent.doAbortProject() {} catch (bytes memory lowLevelData) {
            bool errorMatch = this.isEqualSignature(
                makeError(Errors.InvalidOperationFor.selector),
                lowLevelData
            );
            if (errorMatch) {
                fail();
            }
        }
    }
}

/* solhint-enable no-empty-blocks */
