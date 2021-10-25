// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "./utils/CrowdtainerTest.sol";
import {Errors} from "../Crowdtainer.sol";

/* solhint-disable no-empty-blocks */

contract CrowdtainerValidJoinTester is BaseTest {

    function testNoDiscountAndNoNewCodeMustSucceed() public {
        init();

        uint256 previousBalance = erc20Token.balanceOf(address(bob));

        uint256[MAX_NUMBER_OF_PRODUCTS] memory quantities = [uint256(0), 2, 10];

        bob.doJoin(quantities, bytes32(0x0), "");

        uint256 totalCost = quantities[1] * unitPricePerType[1];
        totalCost += quantities[2] * unitPricePerType[2];

        assertEq(erc20Token.balanceOf(address(bob)), (previousBalance - totalCost));
    }

    function testNewValidReferralCodeMustSucceed() public {
        init();
        uint256[MAX_NUMBER_OF_PRODUCTS] memory quantities = [uint256(0), 2, 10];
        bytes32 bobsReferralCode = "BobsReferralCode";
        assertEq(crowdtainer.ownerOfReferralCode(bobsReferralCode), address(0x0));

        bob.doJoin(quantities, bytes32(0x0), bobsReferralCode);

        assertEq(crowdtainer.ownerOfReferralCode(bobsReferralCode), address(bob));
    }

    function testUsageOfValidReferralCodeMustSucceed() public {
        init();
        uint256[MAX_NUMBER_OF_PRODUCTS] memory quantities = [uint256(0), 2, 10];
        bytes32 bobsReferralCode = "BobsReferralCode";
        bob.doJoin(quantities, bytes32(0x0), bobsReferralCode);
        
        uint256 totalCost = quantities[1] * unitPricePerType[1];
        totalCost += quantities[2] * unitPricePerType[2];
        uint256 discount = totalCost * ((referralRate / 2) / 100);

        uint256 previousAliceBalance = erc20Token.balanceOf(address(alice));

        alice.doJoin(quantities, bobsReferralCode, bytes32(0x0));

        assertEq(erc20Token.balanceOf(address(alice)), previousAliceBalance - (totalCost - discount));

        // verify that bob received referral credits
        assertEq(crowdtainer.accumulatedRewardsOf(address(bob)), discount);
    }
}

contract CrowdtainerInvalidJoinTester is BaseTest {
    function testFailCreateNewButAlreadyUsedReferralCode() public {
        init();
        uint256[MAX_NUMBER_OF_PRODUCTS] memory quantities = [uint256(0), 2, 10];
        bytes32 bobsReferralCode = "BobsReferralCode";
        assertEq(crowdtainer.ownerOfReferralCode(bobsReferralCode), address(0x0));

        bob.doJoin(quantities, bytes32(0x0), bobsReferralCode);

        try
            // alice can't use same referral code already used by bob
            alice.doJoin(quantities, bytes32(0x0), bobsReferralCode)
        {} catch (bytes memory lowLevelData) {
            failed = this.assertEqSignature(
                    makeError(Errors.ReferralCodeAlreadyUsed.selector),
                    lowLevelData
                );
        }
    }

    function testFailUseOwnReferralCode() public {
        init();
        uint256[MAX_NUMBER_OF_PRODUCTS] memory quantities = [uint256(0), 2, 10];
        bytes32 bobsReferralCode = "BobsReferralCode";

        // join and create a new referral code
        bob.doJoin(quantities, bytes32(0x0), bobsReferralCode);

        try
            // bob can't use referral code coming from the same wallet
            bob.doJoin(quantities, bobsReferralCode, bytes32(0x0))
        {} catch (bytes memory lowLevelData) {
            failed = this.assertEqSignature(
                    makeError(Errors.CannotReferItself.selector),
                    lowLevelData
                );
        }
    }

    function testFailUseOfInvalidReferralCode() public {
        init();
        uint256[MAX_NUMBER_OF_PRODUCTS] memory quantities = [uint256(0), 2, 10];

        bytes32 bobsReferralCode = "BobsReferralCode";
        assertEq(crowdtainer.ownerOfReferralCode(bobsReferralCode),address(0x0));

        //bob.doJoin(quantities, bytes32(0x0), bobsReferralCode); // not registered

        try
            alice.doJoin(quantities, bobsReferralCode, bytes32(0x0))
        {} catch (bytes memory lowLevelData) {
            failed = this.assertEqSignature(
                    makeError(Errors.ReferralCodeInexistent.selector),
                    lowLevelData
                );
        }
    }

    function testFailExceedingNumberOfMaximumItemsPurchased() public {
        init();
        uint256[MAX_NUMBER_OF_PRODUCTS] memory quantities = [uint256(2), MAX_NUMBER_OF_PURCHASED_ITEMS + 1, 10];

        try
            alice.doJoin(quantities, bytes32(0x0), bytes32(0x0))
        {} catch (bytes memory lowLevelData) {
            failed = this.assertEqSignature(
                    makeError(Errors.ExceededNumberOfItemsAllowed.selector),
                    lowLevelData
                );
            this.printTwoUint256(lowLevelData);
        }
    }

    function testFailPurchaseExceedsMaximumTarget() public {
        init();
        uint256[MAX_NUMBER_OF_PRODUCTS] memory quantities;
        quantities = [uint256(MAX_NUMBER_OF_PURCHASED_ITEMS), MAX_NUMBER_OF_PURCHASED_ITEMS, MAX_NUMBER_OF_PURCHASED_ITEMS];

        for(uint256 i = 0; i < 9999; i++)
        {
            try
                alice.doJoin(quantities, bytes32(0x0), bytes32(0x0))
            {} catch (bytes memory lowLevelData) {
                failed = this.assertEqSignature(
                        makeError(Errors.PurchaseExceedsMaximumTarget.selector),
                        lowLevelData
                    );
                this.printTwoUint256(lowLevelData);
                emit log_named_uint("Required purchases to exceed target:", i);
                break;
            }
        }
    }
}

//   ----------------------
//  | Fuzz tests           |
//   ----------------------
contract JoinFuzzer is BaseTest {

    function testInvariantsHold(uint256 amountA, uint256 amountB, uint256 amountC) public {
        init();

        if(amountA > MAX_NUMBER_OF_PURCHASED_ITEMS) return;
        if(amountB > MAX_NUMBER_OF_PURCHASED_ITEMS) return;
        if(amountC > MAX_NUMBER_OF_PURCHASED_ITEMS) return;
    
        uint256 previousAliceBalance = erc20Token.balanceOf(address(alice));

        uint256[MAX_NUMBER_OF_PRODUCTS] memory quantities = [amountA, amountB, amountC];

        uint256 totalCost = 0;
        for (uint256 i = 0; i < MAX_NUMBER_OF_PRODUCTS; i++) {
            totalCost += unitPricePerType[i] * quantities[i];
        }

        alice.doJoin(quantities, bytes32(0x0), "");

        assertEq(erc20Token.balanceOf(address(alice)), (previousAliceBalance - totalCost));
    }
}

//   ----------------------
//  | Symbolic Execution   |
//   ----------------------
contract JoinProver is BaseTest {
    /*function proveAllSanityChecks(
        uint256 amountA, uint256 amountB, uint256 amountC
    ) public {

        crowdtainer.initialize(
            openingTime,
            closingTime,
            targetMinimum,
            targetMaximum,
            unitPricePerType,
            referralRate,
            erc20Token
        );

        // Remove unrealistic values from branch exploration
        if(amountA > MAX_NUMBER_OF_PURCHASED_ITEMS) return;
        if(amountB > MAX_NUMBER_OF_PURCHASED_ITEMS) return;
        if(amountC > MAX_NUMBER_OF_PURCHASED_ITEMS) return;
    
        uint256 previousAliceBalance = erc20Token.balanceOf(address(alice));

        uint256[MAX_NUMBER_OF_PRODUCTS] memory quantities = [amountA, amountB, amountC];

        uint256 totalCost = 0;
        for (uint256 i = 0; i < MAX_NUMBER_OF_PRODUCTS; i++) {
            totalCost += unitPricePerType[i] * quantities[i];
        }

        alice.doJoin(quantities, bytes32(0x0), "");

        assertEq(erc20Token.balanceOf(address(alice)), (previousAliceBalance - totalCost));
    }*/
}
/* solhint-enable no-empty-blocks */
