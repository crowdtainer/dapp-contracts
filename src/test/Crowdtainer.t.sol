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

    function testInvalidMinimumSoldUnits() public {
        failed = true; // @dev: specific error must be thrown
        try
            crowdtainer.initialize(
                openingTime,
                closingTime,
                maximumSoldUnits + 1,
                maximumSoldUnits,
                unitPricePerType,
                referralRate,
                token
            )
        {} catch (bytes memory lowLevelData) {
            this.assertEqSignature(
                makeError(Errors.InvalidMinimumSoldUnits.selector),
                lowLevelData
            );
            failed = false;
        }
    }

    function testInvalidMaximumSoldUnits() public {
        failed = true; // @dev: specific error must be thrown
        try
            crowdtainer.initialize(
                openingTime,
                closingTime,
                minimumSoldUnits,
                0,
                unitPricePerType,
                referralRate,
                token
            )
        {} catch (bytes memory lowLevelData) {
            this.assertEqSignature(
                makeError(Errors.InvalidMinimumSoldUnits.selector),
                lowLevelData
            );
            failed = false;
        }
    }
}

contract CrowdtainerStateTransitionTester is CrowdtainerTest {
    function testGetPaidAndDeliverCalledByOwnerMustSucceed() public {
        crowdtainer.initialize(
            openingTime,
            closingTime,
            minimumSoldUnits,
            maximumSoldUnits,
            unitPricePerType,
            referralRate,
            token
        );
        crowdtainer.getPaidAndDeliver();
        assert(crowdtainer.crowdtainerState() == CrowdtainerState.Delivery);
    }
}

contract CrowdtainerAuthorizationTester is CrowdtainerTest {
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
}

//   ----------------------
//  | Fuzz tests           |
//   ----------------------
contract InitializeFuzzer is CrowdtainerTest {
    function testAllSanityChecks(
        uint256 _openingTime,
        uint256 _expireTime,
        uint256 _minimumSoldUnits,
        uint256 _maximumSoldUnits,
        uint256[10] memory _unitPricePerType,
        uint256 _referralRate,
        IERC20 _token
    ) public {

        // Discard initialize() invariants
        if(address(token) != address(0)) return;
        if(crowdtainer.expireTime() > (crowdtainer.openingTime() + crowdtainer.SAFETY_TIME_RANGE())) return;
        if(crowdtainer.maximumSoldUnits() > 0) return;
        if(crowdtainer.minimumSoldUnits() >= crowdtainer.maximumSoldUnits()) return;


        crowdtainer.initialize(
            _openingTime,
            _expireTime,
            _minimumSoldUnits,
            _maximumSoldUnits,
            _unitPricePerType,
            _referralRate,
            _token
        );

        assert(address(token) != address(0));
        assert(crowdtainer.expireTime() > (crowdtainer.openingTime() + crowdtainer.SAFETY_TIME_RANGE()));
        assert(crowdtainer.maximumSoldUnits() > 0);
        assert(crowdtainer.minimumSoldUnits() >= crowdtainer.maximumSoldUnits());
        assert(crowdtainer.referralRate() <= crowdtainer.SAFETY_MAX_REFERRAL_RATE());
    }
}

//   ----------------------
//  | Symbolic Execution   |
//   ----------------------
contract InitializeProver is CrowdtainerTest {
    /*
        function proveAllSanityChecks(
        uint256 _openingTime,
        uint256 _expireTime,
        uint256 _minimumSoldUnits,
        uint256 _maximumSoldUnits,
        uint256[10] memory _unitPricePerType,
        uint256 _referralRate,
        IERC20 _token
    ) public {

        // Remove initialize() invariants from branch exploration
        if(address(_token) == address(0)) return;
        if(_expireTime < (_openingTime + crowdtainer.SAFETY_TIME_RANGE())) return;
        if(_maximumSoldUnits == 0) return;
        if(_minimumSoldUnits < _maximumSoldUnits) return;

        crowdtainer.initialize(
            _openingTime,
            _expireTime,
            _minimumSoldUnits,
            _maximumSoldUnits,
            _unitPricePerType,
            _referralRate,
            _token
        );

        assert(true);

        // TODO: Other invariant checks.
    } */
}
/* solhint-enable no-empty-blocks */
