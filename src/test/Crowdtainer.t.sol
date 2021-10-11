// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "./utils/CrowdtainerTest.sol";
import {Errors} from "../Crowdtainer.sol";

contract CrowdtainerTester is CrowdtainerTest {

    function testDummyFunctionCalledByWrongAddress() public {
        try bob.dummyFunction("I'm not allowed") {

        } catch (bytes memory lowLevelData) {
            this.assertEqSignature(makeError(Errors.CallerNotAllowed.selector), lowLevelData);
            this.printAddresses(lowLevelData);
        }
    }

    function testDummyFunctionSucceeds() public {
        string memory mAllowed = "I'm allowed";
        crowdtainer.dummyFunction(mAllowed);
        assertEq(crowdtainer.receivedMessage(), mAllowed);
    }

    function testWorksForAllMessages(string memory message) public {
        crowdtainer.dummyFunction(message);
        assertEq(crowdtainer.receivedMessage(), message);
    }
}
