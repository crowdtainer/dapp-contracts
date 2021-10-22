// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "./utils/CrowdtainerTest.sol";
import {Errors} from "../Crowdtainer.sol";

/* solhint-disable no-empty-blocks */

contract CrowdtainerValidJoinTester is BaseTest {

    function setup() private {
        crowdtainer.initialize(
            openingTime,
            closingTime,
            targetMinimum,
            targetMaximum,
            unitPricePerType,
            referralRate,
            token
        );
    }
    function testWithNoDiscountNoNewCodeMustSucceed() public {
        setup();

        uint256[MAX_NUMBER_OF_PRODUCTS] memory quantities = [uint256(0), 2];

        crowdtainer.join(quantities, bytes32(0x0), "");
        
    }
}

contract CrowdtainerInvalidJoinTester is BaseTest {
    function testWithInvalidValuesMustFail() public {
        failed = true; // @dev: specific error must be thrown
        try bob.getPaidAndDeliver() {} catch (bytes memory lowLevelData) {
            this.assertEqSignature(
                makeError(Errors.CallerNotAllowed.selector),
                lowLevelData
            );
            failed = false;
        }
        // TODO: Implementation
    }
}

//   ----------------------
//  | Fuzz tests           |
//   ----------------------
contract JoinFuzzer is BaseTest {
    function testInvariantsHold(
        uint256 _openingTime,
        uint256 _expireTime,
        uint256 _targetMinimum,
        uint256 _targetMaximum,
        uint256[MAX_NUMBER_OF_PRODUCTS] memory _unitPricePerType,
        uint256 _referralRate,
        IERC20 _token
    ) public {
        // Discard initialize() invariants
        if (address(token) != address(0)) return;
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

        assert(address(token) != address(0));
        assert(
            crowdtainer.expireTime() >
                (crowdtainer.openingTime() + SAFETY_TIME_RANGE)
        );
        assert(crowdtainer.targetMaximum() > 0);
        assert(crowdtainer.targetMinimum() >= crowdtainer.targetMaximum());
        assert(crowdtainer.referralRate() <= SAFETY_MAX_REFERRAL_RATE);

        // TODO: Implementation
    }
}

//   ----------------------
//  | Symbolic Execution   |
//   ----------------------
contract JoinProver is BaseTest {
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
