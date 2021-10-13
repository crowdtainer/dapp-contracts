// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "./utils/CrowdtainerTest.sol";
import {Errors} from "../Crowdtainer.sol";

/* solhint-disable no-empty-blocks */
contract CrowdtainerTester is CrowdtainerTest {
    function testGetPaidAndDeliverCalledByNonOwnerMustFail() public {
        try bob.getPaidAndDeliver() {} catch (bytes memory lowLevelData) {
            this.assertEqSignature(
                makeError(Errors.CallerNotAllowed.selector),
                lowLevelData
            );
            this.printAddresses(lowLevelData);
        }
    }

    function testGetPaidAndDeliverCalledByOwnerMustSucceed() public {
        crowdtainer.getPaidAndDeliver();
        // TODO: Assert that contract went into "delivery" state.
    }
}
/* solhint-enable no-empty-blocks */
