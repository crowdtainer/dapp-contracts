// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "./utils/CrowdtainerTest.sol";
import {Errors} from "../Crowdtainer.sol";

/* solhint-disable no-empty-blocks */

contract CrowdtainerStateTransitionTester is BaseTest {
    function testGetPaidAndDeliverCalledByOwnerMustSucceed() public {
        crowdtainer.initialize(
            openingTime,
            closingTime,
            targetMinimum,
            targetMaximum,
            unitPricePerType,
            referralRate,
            erc20Token,
            uri
        );
        crowdtainer.getPaidAndDeliver(10);
        assert(crowdtainer.crowdtainerState() == CrowdtainerState.Delivery);
        // TODO: implementation
    }
}

contract CrowdtainerAuthorizationTester is BaseTest {
    function testGetPaidAndDeliverCalledByNonOwnerMustFail() public {
        failed = true; // @dev: specific error must be thrown
        try bob.getPaidAndDeliver(10) {} catch (bytes memory lowLevelData) {
            this.assertEqSignature(
                makeError(Errors.CallerNotAllowed.selector),
                lowLevelData
            );
            failed = false;
        }
    }
}

/* solhint-enable no-empty-blocks */
