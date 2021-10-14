// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "./utils/CrowdtainerTest.sol";
import {Errors} from "../Crowdtainer.sol";

/* solhint-disable no-empty-blocks */

contract CrowdtainerInitializeTester is CrowdtainerTest {
    function testValidValuesMustSucceed() public {
        crowdtainer.initialize(
            openingTime,
            closingTime,
            minimumSoldUnits,
            maximumSoldUnits,
            unitPricePerType,
            referralRate,
            token
        );
    }

    function testInvalidOpeningTime() public {
        failed = true; // @dev: specific error must be thrown
        try
            crowdtainer.initialize(
                openingTime - 2 hours,
                closingTime,
                minimumSoldUnits,
                maximumSoldUnits,
                unitPricePerType,
                referralRate,
                token
            )
        {} catch (bytes memory lowLevelData) {
            this.assertEqSignature(
                makeError(Errors.OpeningTimeInThePast.selector),
                lowLevelData
            );
            failed = false;
        }
    }

    function testWithInvalidTokenAddress() public {
        failed = true; // @dev: specific error must be thrown

        ERC20 invalidTokenAddress = ERC20(address(0));
        try
            crowdtainer.initialize(
                openingTime,
                closingTime,
                minimumSoldUnits,
                maximumSoldUnits,
                unitPricePerType,
                referralRate,
                invalidTokenAddress
            )
        {} catch (bytes memory lowLevelData) {
            this.assertEqSignature(
                makeError(Errors.TokenAddressIsZero.selector),
                lowLevelData
            );
            failed = false;
        }
    }

    function testInvalidClosingTime() public {
        failed = true; // @dev: specific error must be thrown
        try
            crowdtainer.initialize(
                openingTime,
                openingTime,
                minimumSoldUnits,
                maximumSoldUnits,
                unitPricePerType,
                referralRate,
                token
            )
        {} catch (bytes memory lowLevelData) {
            this.assertEqSignature(
                makeError(Errors.ClosingTimeTooEarly.selector),
                lowLevelData
            );
            failed = false;
        }
    }

    function testGetPaidAndDeliverCalledByOwnerMustSucceed() public {
        crowdtainer.getPaidAndDeliver();
        // TODO: Assert that contract went into "delivery" state.
    }
}

contract CrowdtainerTester is CrowdtainerTest {
    function testGetPaidAndDeliverCalledByNonOwnerMustFail() public {
        failed = true; // @dev: specific error must be thrown
        try bob.getPaidAndDeliver() {} catch (bytes memory lowLevelData) {
            this.assertEqSignature(
                makeError(Errors.CallerNotAllowed.selector),
                lowLevelData
            );
            failed = false;
        }
    }

    function testGetPaidAndDeliverCalledByOwnerMustSucceed() public {
        crowdtainer.getPaidAndDeliver();
        // TODO: Assert that contract went into "delivery" state.
    }
}
/* solhint-enable no-empty-blocks */
