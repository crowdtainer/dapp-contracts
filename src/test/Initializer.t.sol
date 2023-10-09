// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.21;

import "./utils/CrowdtainerTest.sol";
import {Errors} from "../contracts/Crowdtainer.sol";

/* solhint-disable no-empty-blocks*/
/* solhint-disable code-complexity*/

contract ValidInitializeTester is CrowdtainerTest {
    function testValidValuesMustSucceed() public {
        crowdtainer.initialize(
            address(0),
            CampaignData(
                address(agent),
                address(0),
                openingTime,
                closingTime,
                targetMinimum,
                targetMaximum,
                unitPricePerType,
                referralRate,
                referralEligibilityValue,
                address(erc20Token),
                ""
            )
        );
    }
}

contract InvalidInitializeTester is CrowdtainerTest {
    function testFailWithInvalidTokenAddress() public {
        IERC20 invalidTokenAddress = IERC20(address(0));
        try
            crowdtainer.initialize(
                address(0),
                CampaignData(
                    address(agent),
                    address(0),
                    openingTime,
                    closingTime,
                    targetMinimum,
                    targetMaximum,
                    unitPricePerType,
                    referralRate,
                    referralEligibilityValue,
                    address(invalidTokenAddress),
                    ""
                )
            )
        {} catch (bytes memory lowLevelData) {
            bool failed = this.isEqualSignature(
                makeError(Errors.TokenAddressIsZero.selector),
                lowLevelData
            );
            if (failed) fail();
        }
    }

    function testFailWithInvalidShippingAgentAddress() public {
        IERC20 invalidTokenAddress = IERC20(address(0));
        try
            crowdtainer.initialize(
                address(0),
                CampaignData(
                    address(invalidTokenAddress),
                    address(0),
                    openingTime,
                    closingTime,
                    targetMinimum,
                    targetMaximum,
                    unitPricePerType,
                    referralRate,
                    referralEligibilityValue,
                    address(erc20Token),
                    ""
                )
            )
        {} catch (bytes memory lowLevelData) {
            bool failed = this.isEqualSignature(
                makeError(Errors.ShippingAgentAddressIsZero.selector),
                lowLevelData
            );
            if (failed) fail();
        }
    }

    function testFailWithInvalidReferralEligibilityValue() public {
        try
            crowdtainer.initialize(
                address(0),
                CampaignData(
                    address(agent),
                    address(0),
                    openingTime,
                    closingTime,
                    targetMinimum,
                    targetMaximum,
                    unitPricePerType,
                    referralRate,
                    targetMinimum + 1,
                    address(erc20Token),
                    ""
                )
            )
        {} catch (bytes memory lowLevelData) {
            bool failed = this.isEqualSignature(
                makeError(Errors.ReferralMinimumValueTooHigh.selector),
                lowLevelData
            );
            if (failed) fail();
        }
    }

    function testFailInvalidClosingTime() public {
        try
            crowdtainer.initialize(
                address(0),
                CampaignData(
                    address(agent),
                    address(0),
                    openingTime,
                    openingTime,
                    targetMinimum,
                    targetMaximum,
                    unitPricePerType,
                    referralRate,
                    referralEligibilityValue,
                    address(erc20Token),
                    ""
                )
            )
        {} catch (bytes memory lowLevelData) {
            bool failed = this.isEqualSignature(
                makeError(Errors.ClosingTimeTooEarly.selector),
                lowLevelData
            );
            if (failed) fail();
        }
    }

    function testFailMinimumTargetTooHigh() public {
        try
            crowdtainer.initialize(
                address(0),
                CampaignData(
                    address(agent),
                    address(0),
                    openingTime,
                    openingTime,
                    targetMaximum + 1,
                    targetMaximum,
                    unitPricePerType,
                    referralRate,
                    referralEligibilityValue,
                    address(erc20Token),
                    ""
                )
            )
        {} catch (bytes memory lowLevelData) {
            bool failed = this.isEqualSignature(
                makeError(Errors.ClosingTimeTooEarly.selector),
                lowLevelData
            );
            if (failed) fail();
        }
    }

    function testFailMinimumTargetTooLow() public {
        try
            crowdtainer.initialize(
                address(0),
                CampaignData(
                    address(agent),
                    address(0),
                    openingTime,
                    closingTime,
                    0,
                    targetMaximum,
                    unitPricePerType,
                    referralRate,
                    0,
                    address(erc20Token),
                    ""
                )
            )
        {} catch (bytes memory lowLevelData) {
            bool failed = this.isEqualSignature(
                makeError(Errors.InvalidMinimumTarget.selector),
                lowLevelData
            );
            if (failed) fail();
        }
    }

    function testFailMinimumTargetHigherThanMaximum() public {
        try
            crowdtainer.initialize(
                address(0),
                CampaignData(
                    address(agent),
                    address(0),
                    openingTime,
                    closingTime,
                    targetMaximum + 1,
                    targetMaximum,
                    unitPricePerType,
                    referralRate,
                    referralEligibilityValue,
                    address(erc20Token),
                    ""
                )
            )
        {} catch (bytes memory lowLevelData) {
            bool failed = this.isEqualSignature(
                makeError(Errors.MinimumTargetHigherThanMaximum.selector),
                lowLevelData
            );
            if (failed) fail();
        }
    }

    function testFailInvalidMaximumTarget() public {
        try
            crowdtainer.initialize(
                address(0),
                CampaignData(
                    address(agent),
                    address(0),
                    openingTime,
                    closingTime,
                    targetMinimum,
                    0,
                    unitPricePerType,
                    referralRate,
                    referralEligibilityValue,
                    address(erc20Token),
                    ""
                )
            )
        {} catch (bytes memory lowLevelData) {
            bool failed = this.isEqualSignature(
                makeError(Errors.InvalidMaximumTarget.selector),
                lowLevelData
            );
            if (failed) fail();
        }
    }

    function testFailInvalidReferralRate() public {
        try
            crowdtainer.initialize(
                address(0),
                CampaignData(
                    address(agent),
                    address(0),
                    openingTime,
                    closingTime,
                    targetMinimum,
                    targetMaximum,
                    unitPricePerType,
                    160,
                    referralEligibilityValue,
                    address(erc20Token),
                    ""
                )
            )
        {} catch (bytes memory lowLevelData) {
            bool failed = this.isEqualSignature(
                makeError(Errors.InvalidReferralRate.selector),
                lowLevelData
            );
            if (failed) fail();
        }
    }

    function testFailInvalidReferralRateNotMultipleOfTwo() public {
        try
            crowdtainer.initialize(
                address(0),
                CampaignData(
                    address(agent),
                    address(0),
                    openingTime,
                    closingTime,
                    targetMinimum,
                    targetMaximum,
                    unitPricePerType,
                    3,
                    referralEligibilityValue,
                    address(erc20Token),
                    ""
                )
            )
        {} catch (bytes memory lowLevelData) {
            bool failed = this.isEqualSignature(
                makeError(Errors.ReferralRateNotMultipleOfTwo.selector),
                lowLevelData
            );
            if (failed) fail();
        }
    }
}

//   ----------------------
//  | Fuzz tests           |
//   ----------------------
contract InitializeFuzzer is CrowdtainerTest {
    function testAllSanityChecks(
        address _agent,
        uint256 _openingTime,
        uint256 _closingTime,
        uint256 _targetMinimum,
        uint256 _targetMaximum,
        uint256[] memory _unitPricePerType,
        uint256 _referralRate,
        uint256 _referralEligibilityValue,
        IERC20 _token
    ) public {
        // Discard initialize() invariants
        if (address(_token) == address(0)) return;
        if (address(_agent) == address(0)) return;
        if (!(_openingTime < type(uint256).max - SAFETY_TIME_RANGE)) return;
        if (_closingTime > _openingTime + SAFETY_TIME_RANGE) return;
        if (_targetMaximum == 0) return;
        if (_targetMinimum == 0) return;
        if (_targetMinimum > _targetMaximum) return;
        if (_referralRate % 2 != 0) return;
        if (_referralEligibilityValue > _targetMinimum) return;

        if (_closingTime < _openingTime + SAFETY_TIME_RANGE) return;

        // Ensure that there are no prices set to zero
        for (uint256 i = 0; i < _unitPricePerType.length; i++) {
            // @dev Check if number of items isn't beyond the allowed.
            if (_unitPricePerType[i] == 0) return;
        }

        if (_referralRate > SAFETY_MAX_REFERRAL_RATE) return;

        crowdtainer.initialize(
            address(0),
            CampaignData(
                _agent,
                address(0),
                _openingTime,
                _closingTime,
                _targetMinimum,
                _targetMaximum,
                _unitPricePerType,
                _referralRate,
                _referralEligibilityValue,
                address(_token),
                ""
            )
        );

        assert(
            crowdtainer.expireTime() >
                (crowdtainer.openingTime() + SAFETY_TIME_RANGE)
        );
        assertGt(crowdtainer.targetMaximum(), 0);
        assert(crowdtainer.targetMinimum() >= crowdtainer.targetMaximum());
        assert(crowdtainer.referralRate() <= SAFETY_MAX_REFERRAL_RATE);
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
        uint256 _targetMinimum,
        uint256 _targetMaximum,
        uint256[] memory _unitPricePerType,
        uint256 _referralRate,
        uint256 _referralEligibilityValue,
        IERC20 _token
    ) public {

        // Remove initialize() invariants from branch exploration
        if(address(_token) == address(0)) return;
        if(_expireTime < (_openingTime + SAFETY_TIME_RANGE)) return;
        if(_targetMaximum == 0) return;
        if(_targetMinimum < _targetMaximum) return;
        if(_referralRate % 2 != 0) return;
        if(_referralRate >= _targetMinimum) return;

        crowdtainer.initialize(address(this), CampaignData(
                    address(agent),
                    address(0),
                    openingTime,
                    closingTime,
                    targetMinimum,
                    targetMaximum,
                    unitPricePerType,
                    referralRate,
                    referralEligibilityValue,
                    address(erc20Token),
                    ""
                )
            );

        assert(true);

        // TODO: Other invariant checks.
    } */
}
/* solhint-enable code-complexity*/
/* solhint-enable no-empty-blocks code-complexity */
