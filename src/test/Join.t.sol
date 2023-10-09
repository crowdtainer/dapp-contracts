// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import "./utils/CrowdtainerTest.sol";

import {Errors} from "../contracts/Crowdtainer.sol";

/* solhint-disable no-empty-blocks */

interface Cheats {
    // Signs data, (privateKey, digest) => (v, r, s)
    function sign(uint256, bytes32) external returns (uint8, bytes32, bytes32);
}

contract CrowdtainerValidJoinTester is CrowdtainerTest {
    Cheats internal constant cheats = Cheats(HEVM_ADDRESS);
    uint256 internal signerPrivateKey;
    address internal signer;

    function testJoinUsingSignatureMustSucceed() public {
        signerPrivateKey = 0xA11CE;
        signer = vm.addr(signerPrivateKey);

        initWithSignature(signer);

        uint256 previousBalance = erc20Token.balanceOf(address(bob));

        uint256[] memory quantities = new uint256[](4);
        quantities[1] = 2;
        quantities[2] = 10;

        uint64 epochExpiration = uint64(block.timestamp) + uint64(1000); // signature expiration
        bytes32 aliceNonce = keccak256("random");

        bytes memory payload = abi.encodePacked(
            address(crowdtainer),
            address(bob),
            quantities,
            false,
            address(0),
            epochExpiration,
            aliceNonce
        );

        bytes32 messageHash = keccak256(payload);
        bytes32 message = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
        );

        (uint8 v, bytes32 r, bytes32 s) = cheats.sign(
            signerPrivateKey,
            message
        );

        // bytes memory signature = bytes.concat(r, s, bytes1(v));
        bytes memory proof = abi.encode(
            address(crowdtainer),
            epochExpiration,
            aliceNonce,
            bytes.concat(r, s, bytes1(v))
        );

        bytes memory extraData = abi.encode(
            address(bob),
            quantities,
            false,
            address(0)
        );

        try bob.doJoinWithSignature(proof, extraData) {} catch (bytes memory) {
            fail();
        }

        uint256 totalCost = quantities[1] * unitPricePerType[1];
        totalCost += quantities[2] * unitPricePerType[2];
        {
            assertEq(
                erc20Token.balanceOf(address(bob)),
                (previousBalance - totalCost)
            );
        }
    }

    function testNoDiscountAndNoReferralCodeMustSucceed() public {
        init();

        uint256 previousBalance = erc20Token.balanceOf(address(bob));

        uint256[] memory quantities = new uint256[](4);
        quantities[1] = 2;
        quantities[2] = 10;

        try bob.doJoinSimple(quantities) {} catch (bytes memory) {
            fail();
        }

        uint256 totalCost = quantities[1] * unitPricePerType[1];
        totalCost += quantities[2] * unitPricePerType[2];

        assertEq(
            erc20Token.balanceOf(address(bob)),
            (previousBalance - totalCost)
        );
    }

    function testSmallPricesAndDiscountsMustSucceed() public {
        uint256[] memory prices = new uint256[](4);
        prices[0] = ONE;
        prices[1] = ONE;
        prices[2] = ONE;
        prices[3] = ONE;
        crowdtainer.initialize(
            address(0),
            CampaignData(
                address(agent),
                address(0),
                openingTime,
                closingTime,
                targetMinimum,
                targetMaximum,
                prices,
                referralRate,
                0,
                address(iERC20Token),
                ""
            )
        );

        uint256[] memory quantities = new uint256[](4);
        quantities[0] = 1;

        bob.doJoin(quantities, true, address(0));

        uint256 totalCost = quantities[0] * ONE;

        uint256 discount = (totalCost * referralRate) / 100 / 2;
        assert(discount != 0);

        uint256 previousAliceBalance = erc20Token.balanceOf(address(alice));

        alice.doJoin(quantities, false, address(bob));

        assertEq(
            erc20Token.balanceOf(address(alice)),
            previousAliceBalance - (totalCost - discount)
        );

        // verify that bob received referral credits
        assertEq(crowdtainer.accumulatedRewardsOf(address(bob)), discount);
    }
}

contract CrowdtainerInvalidJoinTester is CrowdtainerTest {
    function testFailJoinWithValueRaisedAboveMaximumTarget() public {
        crowdtainer.initialize(
            address(0),
            CampaignData(
                address(agent),
                address(0),
                openingTime,
                closingTime,
                1 * ONE,
                2 * ONE,
                unitPricePerType,
                referralRate,
                referralEligibilityValue,
                address(iERC20Token),
                ""
            )
        );

        uint256[] memory quantities = new uint256[](4);
        quantities[1] = 1;

        try
            // bob can't use referral code coming from the same wallet
            bob.doJoin(quantities, false, address(0))
        {} catch (bytes memory lowLevelData) {
            bool failed = this.isEqualSignature(
                makeError(Errors.PurchaseExceedsMaximumTarget.selector),
                lowLevelData
            );
            if (failed) fail();
        }
    }

    function testFailUseOwnReferralCode() public {
        init();

        uint256[] memory quantities = new uint256[](4);
        quantities[0] = 1;
        quantities[1] = 2;
        quantities[2] = 10;

        // join with enabled referral code
        bob.doJoin(quantities, true, address(0));

        try
            // bob can't use referral code coming from the same wallet
            bob.doJoin(quantities, true, address(bob))
        {} catch (bytes memory lowLevelData) {
            bool failed = this.isEqualSignature(
                makeError(Errors.UserAlreadyJoined.selector),
                lowLevelData
            );
            if (failed) fail();
        }
    }

    function testFailUseOfInvalidReferralCode() public {
        init();

        uint256[] memory quantities = new uint256[](4);
        quantities[0] = 1;
        quantities[1] = 2;
        quantities[2] = 10;

        //bob.doJoin(quantities, true, address(0)); // not registered

        try alice.doJoin(quantities, false, address(bob)) {} catch (
            bytes memory lowLevelData
        ) {
            bool failed = this.isEqualSignature(
                makeError(Errors.ReferralInexistent.selector),
                lowLevelData
            );
            if (failed) fail();
        }
    }

    function testFailExceedingNumberOfMaximumItemsPurchased() public {
        init();

        uint256[] memory quantities = new uint256[](4);
        quantities[0] = 2;
        quantities[1] = MAX_NUMBER_OF_PURCHASED_ITEMS + 1;
        quantities[2] = 10;

        try alice.doJoin(quantities, false, address(0)) {} catch (
            bytes memory lowLevelData
        ) {
            bool failed = this.isEqualSignature(
                makeError(Errors.ExceededNumberOfItemsAllowed.selector),
                lowLevelData
            );
            this.printTwoUint256(lowLevelData);
            if (failed) fail();
        }
    }

    function testFailPurchaseExceedsMaximumTarget() public {
        uint256[] memory _unitPricePerType = new uint256[](4);
        _unitPricePerType[0] = 10 * ONE;
        _unitPricePerType[1] = 20 * ONE;
        _unitPricePerType[2] = 25 * ONE;
        _unitPricePerType[3] = 5000 * ONE;

        crowdtainer.initialize(
            address(0),
            CampaignData(
                address(agent),
                address(0),
                openingTime,
                closingTime,
                20000,
                30000,
                _unitPricePerType,
                referralRate,
                referralEligibilityValue,
                address(iERC20Token),
                ""
            )
        );

        uint256[] memory quantities = new uint256[](4);
        _unitPricePerType[0] = MAX_NUMBER_OF_PURCHASED_ITEMS;
        _unitPricePerType[1] = MAX_NUMBER_OF_PURCHASED_ITEMS;
        _unitPricePerType[2] = MAX_NUMBER_OF_PURCHASED_ITEMS;
        _unitPricePerType[3] = MAX_NUMBER_OF_PURCHASED_ITEMS;

        try alice.doJoin(quantities, false, address(0)) {} catch (
            bytes memory lowLevelData
        ) {
            bool failed = this.isEqualSignature(
                makeError(Errors.PurchaseExceedsMaximumTarget.selector),
                lowLevelData
            );
            this.printTwoUint256(lowLevelData);
            if (failed) fail();
        }
    }

    function testFailJoinWithReferralEnabledAndTotalCostLowerThanMinimum()
        public
    {
        uint256[] memory _unitPricePerType = new uint256[](4);
        _unitPricePerType[0] = 10;
        _unitPricePerType[1] = 20;
        _unitPricePerType[2] = 25;
        _unitPricePerType[3] = 50;

        crowdtainer.initialize(
            address(0),
            CampaignData(
                address(agent),
                address(0),
                openingTime,
                closingTime,
                20000,
                30000,
                _unitPricePerType,
                referralRate,
                20,
                address(iERC20Token),
                ""
            )
        );

        uint256[] memory quantities = new uint256[](4);
        quantities[0] = 1;

        try alice.doJoin(quantities, true, address(0)) {} catch (
            bytes memory lowLevelData
        ) {
            bool failed = this.isEqualSignature(
                makeError(
                    Errors.MinimumPurchaseValueForReferralNotMet.selector
                ),
                lowLevelData
            );
            this.printTwoUint256(lowLevelData);
            if (failed) fail();
        }
    }

    function testFailUserJoinWithReferralCodeThatIsNotEnabled() public {
        init();

        uint256[] memory quantities = new uint256[](4);
        quantities[0] = 2;
        quantities[1] = MAX_NUMBER_OF_PURCHASED_ITEMS;
        quantities[2] = 10;

        alice.doJoin(quantities, false, address(0));

        try bob.doJoin(quantities, true, address(alice)) {} catch (
            bytes memory lowLevelData
        ) {
            bool failed = this.isEqualSignature(
                makeError(Errors.ReferralDisabledForProvidedCode.selector),
                lowLevelData
            );
            if (failed) fail();
        }
    }
}

//   ----------------------
//  | Fuzz tests           |
//   ----------------------
contract JoinFuzzer is CrowdtainerTest {
    function testInvariantsHold(
        uint256 amountA,
        uint256 amountB,
        uint256 amountC
    ) public {
        init();

        if (amountA > MAX_NUMBER_OF_PURCHASED_ITEMS) return;
        if (amountB > MAX_NUMBER_OF_PURCHASED_ITEMS) return;
        if (amountC > MAX_NUMBER_OF_PURCHASED_ITEMS) return;

        if (amountA == 0 && amountB == 0 && amountC == 0) return;

        uint256 previousAliceBalance = erc20Token.balanceOf(address(alice));

        uint256[] memory quantities = new uint256[](4);
        quantities[0] = amountA;
        quantities[1] = amountB;
        quantities[2] = amountC;

        uint256 totalCost = 0;
        for (uint256 i = 0; i < unitPricePerType.length; i++) {
            totalCost += unitPricePerType[i] * quantities[i];
        }

        alice.doJoin(quantities, false, address(0));

        assertEq(
            erc20Token.balanceOf(address(alice)),
            (previousAliceBalance - totalCost)
        );
    }
}

//   ----------------------
//  | Symbolic Execution   |
//   ----------------------
contract JoinProver is CrowdtainerTest {
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

        uint256[] memory quantities = [amountA, amountB, amountC];

        uint256 totalCost = 0;
        for (uint256 i = 0; i < ; i++) {
            totalCost += unitPricePerType[i] * quantities[i];
        }

        alice.doJoin(quantities, bytes32(0x0), "");

        assertEq(erc20Token.balanceOf(address(alice)), (previousAliceBalance - totalCost));
    }*/
}
/* solhint-enable no-empty-blocks */
