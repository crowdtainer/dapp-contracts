// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

import "./utils/CrowdtainerTest.sol";
import {Errors} from "../Crowdtainer.sol";

/* solhint-disable no-empty-blocks */

contract CrowdtainerStateTransitionTester is BaseTest {
    function testGetPaidAndDeliverCalledByShippingAgentMustSucceed() public {
        // Create a crowdtainer where targetMinimum is small enough that a single user could
        // make the project succeed with a single join() call.
        uint256[MAX_NUMBER_OF_PRODUCTS] memory _unitPricePerType = [
            uint256(100),
            200,
            300,
            0
        ];
        uint256 _targetMinimum = 3000;
        uint256 _targetMaximum = 4000;
        crowdtainer.initialize(
            CampaignData(
                address(agent),
                openingTime,
                closingTime,
                _targetMinimum,
                _targetMaximum,
                _unitPricePerType,
                referralRate,
                referralEligibilityValue,
                iERC20Token
            )
        );

        // one user buys enough to succeed the crowdtainer project
        uint256[MAX_NUMBER_OF_PRODUCTS] memory quantities = [
            uint256(0),
            0,
            10,
            0
        ];
        alice.doJoin(quantities, false, address(0));

        agent.doGetPaidAndDeliver();
        assert(crowdtainer.crowdtainerState() == CrowdtainerState.Delivery);
    }

    function testFailclaimFundsOnSuccessfulProject() public {
        uint256[MAX_NUMBER_OF_PRODUCTS] memory _unitPricePerType = [
            uint256(100),
            200,
            300,
            0
        ];
        uint256 _targetMinimum = 3000;
        uint256 _targetMaximum = 4000;
        crowdtainer.initialize(
            CampaignData(
                address(agent),
                openingTime,
                closingTime,
                _targetMinimum,
                _targetMaximum,
                _unitPricePerType,
                referralRate,
                referralEligibilityValue,
                iERC20Token
            )
        );

        // one user buys enough to succeed the crowdtainer project
        uint256[MAX_NUMBER_OF_PRODUCTS] memory quantities = [
            uint256(0),
            0,
            10,
            0
        ];
        alice.doJoin(quantities, false, address(0));

        agent.doGetPaidAndDeliver();
        assert(crowdtainer.crowdtainerState() == CrowdtainerState.Delivery);

        try alice.doClaimFunds() {} catch (bytes memory lowLevelData) {
            failed = this.assertEqSignature(
                makeError(Errors.InvalidOperationFor.selector),
                lowLevelData
            );
        }
    }

    function testFailGetPaidAndDeliverCalledBeforeTargetReached() public {
        uint256[MAX_NUMBER_OF_PRODUCTS] memory _unitPricePerType = [
            uint256(100),
            200,
            300,
            0
        ];
        uint256 _targetMinimum = 3000;
        uint256 _targetMaximum = 4000;
        crowdtainer.initialize(
            CampaignData(
                address(agent),
                openingTime,
                closingTime,
                _targetMinimum,
                _targetMaximum,
                _unitPricePerType,
                referralRate,
                referralEligibilityValue,
                iERC20Token
            )
        );

        uint256[MAX_NUMBER_OF_PRODUCTS] memory quantities = [
            uint256(0),
            0,
            9,
            0
        ];
        alice.doJoin(quantities, true, address(0));

        quantities = [uint256(3), 0, 0, 0];
        bob.doJoin(quantities, false, address(alice));

        try agent.doGetPaidAndDeliver() {} catch (bytes memory lowLevelData) {
            failed = this.assertEqSignature(
                makeError(Errors.MinimumTargetNotReached.selector),
                lowLevelData
            );
        }
    }

    function testFailGetPaidAndDeliverCalledBeforeActivePeriod() public {
        uint256[MAX_NUMBER_OF_PRODUCTS] memory _unitPricePerType = [
            uint256(100),
            200,
            300,
            0
        ];
        uint256 _targetMinimum = 3000;
        uint256 _targetMaximum = 4000;
        crowdtainer.initialize(
            CampaignData(
                address(agent),
                openingTime,
                closingTime,
                _targetMinimum,
                _targetMaximum,
                _unitPricePerType,
                referralRate,
                referralEligibilityValue,
                iERC20Token
            )
        );

        uint256[MAX_NUMBER_OF_PRODUCTS] memory quantities = [
            uint256(0),
            0,
            9,
            0
        ];
        alice.doJoin(quantities, false, address(0));

        // go back in time just for testing (though in practice small shifts backward in blocktime are possible)
        hevm.warp(openingTime - 1 seconds);

        try alice.doClaimFunds() {} catch (bytes memory lowLevelData) {
            failed = this.assertEqSignature(
                makeError(Errors.OpeningTimeNotReachedYet.selector),
                lowLevelData
            );
        }
    }

    function testFailGetPaidAndDeliverCalledOnFailedAndExpiredProject() public {
        uint256[MAX_NUMBER_OF_PRODUCTS] memory _unitPricePerType = [
            uint256(100),
            200,
            300,
            0
        ];
        uint256 _targetMinimum = 3000;
        uint256 _targetMaximum = 4000;
        crowdtainer.initialize(
            CampaignData(
                address(agent),
                openingTime,
                closingTime,
                _targetMinimum,
                _targetMaximum,
                _unitPricePerType,
                referralRate,
                referralEligibilityValue,
                iERC20Token
            )
        );

        uint256[MAX_NUMBER_OF_PRODUCTS] memory quantities = [
            uint256(0),
            0,
            9,
            0
        ];
        alice.doJoin(quantities, false, address(0));

        hevm.warp(closingTime + 1 hours);

        try agent.doGetPaidAndDeliver() {} catch (bytes memory lowLevelData) {
            failed = this.assertEqSignature(
                makeError(Errors.MinimumTargetNotReached.selector),
                lowLevelData
            );
        }
    }
}

contract CrowdtainerAuthorizationTester is BaseTest {
    function testGetPaidAndDeliverCalledByNonAgentMustFail() public {
        failed = true; // @dev: specific error must be thrown
        try bob.doGetPaidAndDeliver() {} catch (bytes memory lowLevelData) {
            this.assertEqSignature(
                makeError(Errors.CallerNotAllowed.selector),
                lowLevelData
            );
            failed = false;
        }
    }
}

/* solhint-enable no-empty-blocks */
