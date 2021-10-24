// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "./utils/CrowdtainerTest.sol";
import {Errors} from "../Crowdtainer.sol";

/* solhint-disable no-empty-blocks */

contract ValidInitializeTester is BaseTest {
    function testValidValuesMustSucceed() public {
        crowdtainer.initialize(
            openingTime,
            closingTime,
            targetMinimum,
            targetMaximum,
            unitPricePerType,
            referralRate,
            erc20Token
        );
    }
}

contract InvalidInitializeTester is BaseTest {
    function testWithInvalidTokenAddress() public {
        failed = true; // @dev: specific error must be thrown
        IERC20 invalidTokenAddress = IERC20(address(0));
        try
            crowdtainer.initialize(
                openingTime,
                closingTime,
                targetMinimum,
                targetMaximum,
                unitPricePerType,
                referralRate,
                invalidTokenAddress
            )
        {} catch (bytes memory lowLevelData) {
            failed = !(
                this.assertEqSignature(
                    makeError(Errors.TokenAddressIsZero.selector),
                    lowLevelData
                )
            );
        }
    }

    function testInvalidClosingTime() public {
        failed = true; // @dev: specific error must be thrown
        try
            crowdtainer.initialize(
                openingTime,
                openingTime,
                targetMinimum,
                targetMaximum,
                unitPricePerType,
                referralRate,
                erc20Token
            )
        {} catch (bytes memory lowLevelData) {
            failed = !(
                this.assertEqSignature(
                    makeError(Errors.ClosingTimeTooEarly.selector),
                    lowLevelData
                )
            );
        }
    }

    function testMinimumTargetTooHigh() public {
        failed = true; // @dev: specific error must be thrown
        try
            crowdtainer.initialize(
                openingTime,
                closingTime,
                targetMaximum + 1,
                targetMaximum,
                unitPricePerType,
                referralRate,
                erc20Token
            )
        {} catch (bytes memory lowLevelData) {
            failed = !(
                this.assertEqSignature(
                    makeError(Errors.InvalidMinimumTarget.selector),
                    lowLevelData
                )
            );
        }
    }

    function testMinimumTargetTooLow() public {
        failed = true; // @dev: specific error must be thrown
        try
            crowdtainer.initialize(
                openingTime,
                closingTime,
                0,
                targetMaximum,
                unitPricePerType,
                referralRate,
                erc20Token
            )
        {} catch (bytes memory lowLevelData) {
            failed = !(
                this.assertEqSignature(
                    makeError(Errors.InvalidMinimumTarget.selector),
                    lowLevelData
                )
            );
        }
    }

    function testInvalidMaximumTarget() public {
        failed = true; // @dev: specific error must be thrown
        try
            crowdtainer.initialize(
                openingTime,
                closingTime,
                targetMinimum,
                0,
                unitPricePerType,
                referralRate,
                erc20Token
            )
        {} catch (bytes memory lowLevelData) {
            failed = !(
                this.assertEqSignature(
                    makeError(Errors.InvalidMaximumTarget.selector),
                    lowLevelData
                )
            );
        }
    }

    function testInvalidReferralRate() public {
        failed = true; // @dev: specific error must be thrown
        try
            crowdtainer.initialize(
                openingTime,
                closingTime,
                targetMinimum,
                targetMaximum,
                unitPricePerType,
                160,
                erc20Token
            )
        {} catch (bytes memory lowLevelData) {
            failed = !(
                this.assertEqSignature(
                    makeError(Errors.InvalidReferralRate.selector),
                    lowLevelData
                )
            );
        }
    }
}

//   ----------------------
//  | Fuzz tests           |
//   ----------------------
contract InitializeFuzzer is BaseTest {
    function testAllSanityChecks(
        uint256 _openingTime,
        uint256 _expireTime,
        uint256 _targetMinimum,
        uint256 _targetMaximum,
        uint256[MAX_NUMBER_OF_PRODUCTS] memory _unitPricePerType,
        uint256 _referralRate,
        IERC20 _token
    ) public {
        // Discard initialize() invariants
        if (address(_token) != address(0)) return;
        if (
            crowdtainer.expireTime() >
            (crowdtainer.openingTime() + SAFETY_TIME_RANGE)
        ) return;
        if (crowdtainer.targetMaximum() > 0) return;
        if (crowdtainer.targetMinimum() >= crowdtainer.targetMaximum()) return;

        crowdtainer.initialize(
            _openingTime,
            _expireTime,
            _targetMinimum,
            _targetMaximum,
            _unitPricePerType,
            _referralRate,
            _token
        );

        assert(address(_token) != address(0));
        assert(
            crowdtainer.expireTime() >
                (crowdtainer.openingTime() + SAFETY_TIME_RANGE)
        );
        assert(crowdtainer.targetMaximum() > 0);
        assert(crowdtainer.targetMinimum() >= crowdtainer.targetMaximum());
        assert(crowdtainer.referralRate() <= SAFETY_MAX_REFERRAL_RATE);
    }
}

//   ----------------------
//  | Symbolic Execution   |
//   ----------------------
contract InitializeProver is BaseTest {
    /*
        function proveAllSanityChecks(
        uint256 _openingTime,
        uint256 _expireTime,
        uint256 _targetMinimum,
        uint256 _targetMaximum,
        uint256[10] memory _unitPricePerType,
        uint256 _referralRate,
        IERC20 _token
    ) public {

        // Remove initialize() invariants from branch exploration
        if(address(_token) == address(0)) return;
        if(_expireTime < (_openingTime + crowdtainer.SAFETY_TIME_RANGE())) return;
        if(_targetMaximum == 0) return;
        if(_targetMinimum < _targetMaximum) return;

        crowdtainer.initialize(
            _openingTime,
            _expireTime,
            _targetMinimum,
            _targetMaximum,
            _unitPricePerType,
            _referralRate,
            _token
        );

        assert(true);

        // TODO: Other invariant checks.
    } */
}
/* solhint-enable no-empty-blocks */
