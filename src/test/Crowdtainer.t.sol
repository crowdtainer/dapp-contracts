// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "./utils/CrowdtainerTest.sol";
import {Errors} from "../Crowdtainer.sol";

contract CrowdtainerTester is CrowdtainerTest {
    function testDummyFunctionCalledByWrongAddress() public {
        try bob.dummyFunction("I'm not allowed") {} catch Error(
            string memory reason
        ) {
            // This is executed in case
            // revert was called inside getData
            // and a reason string was provided.
            emit log("failed due reason: ");
            emit log(reason);
            return ();
        } catch Panic(
            uint256 /*errorCode*/
        ) {
            // This is executed in case of a panic,
            // i.e. a serious error like division by zero
            // or overflow. The error code can be used
            // to determine the kind of error.
            return ();
        } catch (bytes memory lowLevelData) {
            string memory expectedError = "CallerNotAllowed(address,address)";

            assertEqSignature(expectedError, lowLevelData);

            printAddress2(lowLevelData);
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
