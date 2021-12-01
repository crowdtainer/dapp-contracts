// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

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
            300
        ];
        uint256 _targetMinimum = 3000;
        uint256 _targetMaximum = 4000;
        crowdtainer.initialize(
            address(agent),
            tokenIdStartIndex,
            numberOfItems,
            openingTime,
            closingTime,
            _targetMinimum,
            _targetMaximum,
            _unitPricePerType,
            referralRate,
            iERC20Token
        );

        // one user buys enough to succeed the crowdtainer project
        uint256[MAX_NUMBER_OF_PRODUCTS] memory quantities = [uint256(0), 0, 10];
        alice.doJoin(quantities, false, address(0));

        agent.getPaidAndDeliver();
        assert(crowdtainer.crowdtainerState() == CrowdtainerState.Delivery);
    }
}

contract CrowdtainerAuthorizationTester is BaseTest {
    function testGetPaidAndDeliverCalledByNonAgentMustFail() public {
        failed = true; // @dev: specific error must be thrown
        try bob.getPaidAndDeliver() {} catch (bytes memory lowLevelData) {
            this.assertEqSignature(
                makeError(Errors.CallerNotAllowed.selector),
                lowLevelData
            );
            failed = false;
        }
    }
}

/* solhint-enable no-empty-blocks */
