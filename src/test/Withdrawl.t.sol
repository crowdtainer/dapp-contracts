// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import "./utils/CrowdtainerTest.sol";
import {Errors} from "../contracts/Crowdtainer.sol";

/* solhint-disable no-empty-blocks */

contract CrowdtainerStateTransitionTester is CrowdtainerTest {
    function testGetPaidAndDeliverCalledByShippingAgentMustSucceed() public {
        // Create a crowdtainer where targetMinimum is small enough that a single user could
        // make the project succeed with a single join() call.
        uint256[] memory _unitPricePerType = new uint256[](4);
        _unitPricePerType[0] = 100 * ONE;
        _unitPricePerType[1] = 200 * ONE;
        _unitPricePerType[2] = 300 * ONE;
        _unitPricePerType[3] = 1 * ONE;

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
        try alice.doJoin(quantities, false, address(0)) {} catch (
            bytes memory
        ) {
            fail();
        }

        try agent.doGetPaidAndDeliver() {} catch (bytes memory) {
            fail();
        }
        assert(crowdtainer.crowdtainerState() == CrowdtainerState.Delivery);
    }

    function testFailclaimFundsOnSuccessfulProject() public {
        uint256[] memory _unitPricePerType = new uint256[](4);
        _unitPricePerType[0] = 100 * ONE;
        _unitPricePerType[1] = 200 * ONE;
        _unitPricePerType[2] = 300 * ONE;

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

        try alice.doClaimFunds() {} catch (bytes memory lowLevelData) {
            bool failed = this.isEqualSignature(
                makeError(Errors.InvalidOperationFor.selector),
                lowLevelData
            );
            if (failed) fail();
        }
    }

    function testFailGetPaidAndDeliverCalledBeforeTargetReached() public {
        uint256[] memory _unitPricePerType = new uint256[](4);
        _unitPricePerType[0] = 100 * ONE;
        _unitPricePerType[1] = 200 * ONE;
        _unitPricePerType[2] = 300 * ONE;

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

        uint256[] memory quantities = new uint256[](4);
        quantities[2] = 9;
        alice.doJoin(quantities, true, address(0));

        quantities[2] = 0;
        quantities[0] = 3;
        bob.doJoin(quantities, false, address(alice));

        try agent.doGetPaidAndDeliver() {} catch (bytes memory lowLevelData) {
            bool failed = this.isEqualSignature(
                makeError(Errors.MinimumTargetNotReached.selector),
                lowLevelData
            );
            if (failed) fail();
        }
    }

    function testFailGetPaidAndDeliverCalledBeforeActivePeriod() public {
        uint256[] memory _unitPricePerType = new uint256[](4);
        _unitPricePerType[0] = 100 * ONE;
        _unitPricePerType[1] = 200 * ONE;
        _unitPricePerType[2] = 300 * ONE;

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

        uint256[] memory quantities = new uint256[](4);
        quantities[2] = 9;

        alice.doJoin(quantities, false, address(0));

        // go back in time just for testing (though in practice small shifts backward in blocktime are possible)
        hevm.warp(openingTime - 1 seconds);

        try alice.doClaimFunds() {} catch (bytes memory lowLevelData) {
            bool failed = this.isEqualSignature(
                makeError(Errors.OpeningTimeNotReachedYet.selector),
                lowLevelData
            );
            if (failed) fail();
        }
    }

    function testFailGetPaidAndDeliverCalledOnFailedAndExpiredProject() public {
        uint256[] memory _unitPricePerType = new uint256[](4);
        _unitPricePerType[0] = 100 * ONE;
        _unitPricePerType[1] = 200 * ONE;
        _unitPricePerType[2] = 300 * ONE;

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

        uint256[] memory quantities = new uint256[](4);
        quantities[2] = 9;

        alice.doJoin(quantities, false, address(0));

        hevm.warp(closingTime + 1 hours);

        try agent.doGetPaidAndDeliver() {} catch (bytes memory lowLevelData) {
            bool failed = this.isEqualSignature(
                makeError(Errors.MinimumTargetNotReached.selector),
                lowLevelData
            );
            if (failed) fail();
        }
    }
}

contract CrowdtainerAuthorizationTester is CrowdtainerTest {
    function testFailGetPaidAndDeliverCalledByNonAgent() public {
        // Create a crowdtainer where targetMinimum is small enough that a single user could
        // make the project succeed with a single join() call.
        uint256[] memory _unitPricePerType = new uint256[](4);
        _unitPricePerType[0] = 100 * ONE;
        _unitPricePerType[1] = 200 * ONE;
        _unitPricePerType[2] = 300 * ONE;
        _unitPricePerType[3] = 1 * ONE;

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

        try bob.doGetPaidAndDeliver() {} catch (bytes memory lowLevelData) {
            bool errorMatch = this.isEqualSignature(
                makeError(Errors.CallerNotAllowed.selector),
                lowLevelData
            );
            if (errorMatch) {
                fail();
            }
        }
    }
}

/* solhint-enable no-empty-blocks */
