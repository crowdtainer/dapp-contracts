// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import "./utils/Vouchers721Test.sol";
import {Errors} from "../contracts/Crowdtainer.sol";

import "../contracts/Metadata/MetadataServiceV1.sol";

/* solhint-disable no-empty-blocks */

interface Cheats {
    // Signs data, (privateKey, digest) => (v, r, s)
    function sign(uint256, bytes32) external returns (uint8, bytes32, bytes32);
}

contract Vouchers721CreateTester is VouchersTest {
    function testCreateCrowdtainerMustSucceed() public {
        metadataService = IMetadataService(address(1));

        uint256 crowdtainerId1;
        address crowdtainerAddress1;
        (crowdtainerAddress1, crowdtainerId1) = createCrowdtainer(address(0));

        assert(
            vouchers.crowdtainerForId(crowdtainerId1) == crowdtainerAddress1
        );
        assert(crowdtainerAddress1 != address(0));

        assertEq(crowdtainerId1, 1);

        uint256 crowdtainerId2;
        address crowdtainerAddress2;
        (crowdtainerAddress2, crowdtainerId2) = createCrowdtainer(address(0));

        assertEq(crowdtainerId2, 2);
        assertTrue(crowdtainerAddress1 != crowdtainerAddress2);
    }

    function testTokenIdMustBeSequential() public {
        metadataService = IMetadataService(address(1));
        address crowdtainerAddress;

        uint256[] memory quantities = new uint256[](4);
        quantities[0] = 1;
        quantities[1] = 4;
        quantities[2] = 3;
        quantities[3] = 1;

        (crowdtainerAddress, ) = createCrowdtainer(address(0));
        uint256 tokenId = alice.doJoin({
            _crowdtainerAddress: crowdtainerAddress,
            _quantities: quantities,
            _enableReferral: false,
            _referrer: address(0)
        });

        assertEq(tokenId, vouchers.ID_MULTIPLE() + 1);

        tokenId = bob.doJoinSimple({
            _crowdtainerAddress: crowdtainerAddress,
            _quantities: quantities
        });

        assertEq(tokenId, vouchers.ID_MULTIPLE() + 2);
    }

    function testTokenIdOwnershipMustBeCorrect() public {
        metadataService = IMetadataService(address(1));
        address crowdtainerAddress;

        uint256[] memory quantities = new uint256[](4);
        quantities[0] = 1;
        quantities[1] = 4;
        quantities[2] = 3;
        quantities[3] = 1;

        (crowdtainerAddress, ) = createCrowdtainer(address(0));

        // Alice (smart contract)
        uint256 tokenId = alice.doJoin({
            _crowdtainerAddress: crowdtainerAddress,
            _quantities: quantities,
            _enableReferral: false,
            _referrer: address(0)
        });

        emit log_named_address("alice", address(alice));
        emit log_named_address(
            "vouchers.ownerOf(tokenId)",
            vouchers.ownerOf(tokenId)
        );
        assertEq(vouchers.ownerOf(tokenId), address(alice));

        // Bob (smart contract)
        tokenId = bob.doJoinSimple({
            _crowdtainerAddress: crowdtainerAddress,
            _quantities: quantities
        });

        emit log_named_address("bob", address(bob));
        emit log_named_address(
            "vouchers.ownerOf(tokenId)",
            vouchers.ownerOf(tokenId)
        );
        assertEq(vouchers.ownerOf(tokenId), address(bob));

        // Eve (EOA)
        PrankedVoucherParticipant evePranked = new PrankedVoucherParticipant(
            vm,
            evePrivateKey,
            address(vouchers),
            address(erc20Token)
        );

        uint256 totalCost = calculateTotalCost(
            AvoidStackTooDeep(quantities, unitPricePerType)
        );

        evePranked.doApprovePayment(crowdtainerAddress, totalCost);
        evePranked.doJoinSimple({
            _crowdtainerAddress: crowdtainerAddress,
            _quantities: quantities
        });
        emit log_named_address("eve", address(eve));
        emit log_named_address(
            "vouchers.ownerOf(tokenId)",
            vouchers.ownerOf(tokenId)
        );
        assertEq(vouchers.ownerOf(tokenId), address(bob));
    }

    Cheats internal constant cheats = Cheats(HEVM_ADDRESS);
    uint256 internal signerPrivateKey;
    address internal signer;

    function testJoinWithPermitMustReturnTokenId() public {
        metadataService = IMetadataService(address(1));
        createCrowdtainer(address(0));

        uint256 previousBalance = erc20Token.balanceOf(address(eve));

        uint256[] memory quantities = new uint256[](4);
        quantities[0] = 1;
        quantities[1] = 4;
        quantities[2] = 3;
        quantities[3] = 100;

        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: eve,
            spender: address(defaultCrowdtainer),
            value: calculateTotalCost(
                AvoidStackTooDeep(quantities, unitPricePerType)
            ),
            nonce: 0,
            deadline: block.timestamp + 2 minutes
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(evePrivateKey, digest);

        SignedPermit memory signedPermit = SignedPermit(
            permit.owner,
            permit.spender,
            permit.value,
            permit.nonce,
            permit.deadline,
            v,
            r,
            s
        );

        PrankedVoucherParticipant evePranked = new PrankedVoucherParticipant(
            vm,
            evePrivateKey,
            address(vouchers),
            address(erc20Token)
        );

        uint256 eveCrowdtainerTokenId = evePranked.doJoinWithPermit(
            address(defaultCrowdtainer),
            quantities,
            false,
            address(0),
            signedPermit
        );

        assertTrue(!vouchers.getClaimStatus(eveCrowdtainerTokenId));

        // Shipping agent deems project successful
        agent.doGetPaidAndDeliver(defaultCrowdtainerId);

        // agent set claimed to true
        agent.doSetClaimStatus(eveCrowdtainerTokenId, true);

        // verify state is true
        assertTrue(vouchers.getClaimStatus(eveCrowdtainerTokenId));

        assertEq(
            erc20Token.balanceOf(address(eve)),
            (previousBalance -
                calculateTotalCost(
                    AvoidStackTooDeep(quantities, unitPricePerType)
                ))
        );
    }

    function testJoinUsingSignatureMustReturnTokenId() public {
        signerPrivateKey = 0xA11CE;
        signer = vm.addr(signerPrivateKey);

        metadataService = IMetadataService(address(1));
        address crowdtainerAddress;

        (crowdtainerAddress, ) = createCrowdtainer(address(signer));

        vm.label(address(signer), "Signer");
        vm.label(address(crowdtainerAddress), "Crowdtainer");

        uint256[] memory quantities = new uint256[](4);
        quantities[1] = 2;
        quantities[2] = 10;

        bool offchainLookupErrorThrown;

        address sender;
        // string[] memory urls;
        // bytes memory callData;
        bytes4 callbackFunction;
        bytes memory extraData;

        try
            bob.doJoin({
                _crowdtainerAddress: crowdtainerAddress,
                _quantities: quantities,
                _enableReferral: false,
                _referrer: address(0)
            })
        {} catch (bytes memory receivedBytes) {
            // We expect `join()` to revert with OffchainLookup()
            bool correctRevert = this.isEqualSignature(
                receivedBytes,
                makeError(Errors.OffchainLookup.selector)
            );

            require(correctRevert, "Invalid error. Expected: OffchainLookup.");

            // decode OffchainLooup error parameters
            // sender, ulrs, params for gateway, 4 byte selector, params for contract (extraData)
            (sender, , , callbackFunction, extraData) = abi.decode(
                this.getParameters(receivedBytes),
                (address, string[], bytes, bytes4, bytes)
            );

            require(
                sender == address(vouchers),
                "The revert must be 'thrown' by Vouchers721 itself"
            );

            assertEq(callbackFunction, Vouchers721.joinWithSignature.selector);

            offchainLookupErrorThrown = true;
        }

        require(
            offchainLookupErrorThrown,
            "OffChainLookup invalid or not thrown."
        );

        // Craft service provider auth/proof
        uint64 epochExpiration = uint64(block.timestamp) + uint64(1000); // signature expiration
        bytes32 bobNonce = keccak256("random");

        bytes memory bobPayload = abi.encodePacked(
            crowdtainerAddress,
            address(bob),
            quantities,
            false,
            address(0),
            epochExpiration,
            bobNonce
        );

        bytes32 bobMessage = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(bobPayload)
            )
        );

        // Service provider signs 'authorization' for Bob
        (uint8 v, bytes32 r, bytes32 s) = cheats.sign(
            signerPrivateKey,
            bobMessage
        );
        bytes memory bobSignature = bytes.concat(r, s, bytes1(v));
        bytes memory bobProof = abi.encode(
            crowdtainerAddress,
            epochExpiration,
            bobNonce,
            bobSignature
        );

        uint256 bobTokenId = bob.doJoinWithSignature(bobProof, extraData);

        assertEq(bobTokenId, vouchers.ID_MULTIPLE() + 1);
    }

    function testJoinUsingSignatureAndPermitMustReturnTokenId() public {
        signerPrivateKey = 0xA11CE;
        signer = vm.addr(signerPrivateKey);

        metadataService = IMetadataService(address(1));
        address crowdtainerAddress;

        (crowdtainerAddress, ) = createCrowdtainer(address(signer));

        vm.label(address(signer), "Signer");
        vm.label(address(crowdtainerAddress), "Crowdtainer");

        uint256[] memory quantities = new uint256[](4);
        quantities[1] = 2;
        quantities[2] = 10;

        // PrankedVoucherParticipant evePranked = new PrankedVoucherParticipant(
        //     vm,
        //     evePrivateKey,
        //     address(vouchers),
        //     address(erc20Token)
        // );

        // bool offchainLookupErrorThrown;

        // address sender;
        // // string[] memory urls;
        // // bytes memory callData;
        // bytes4 callbackFunction;
        // // bytes memory extraData;

        // try
        //     evePranked.doJoin({
        //         _crowdtainerAddress: crowdtainerAddress,
        //         _quantities: quantities,
        //         _enableReferral: false,
        //         _referrer: address(0)
        //     })
        // {} catch (bytes memory receivedBytes) {
        //     // We expect `join()` to revert with OffchainLookup()
        //     bool correctRevert = this.isEqualSignature(
        //         receivedBytes,
        //         makeError(Errors.OffchainLookup.selector)
        //     );

        //     require(correctRevert, "Invalid error. Expected: OffchainLookup.");

        //     // decode OffchainLooup error parameters
        //     // sender, ulrs, params for gateway, 4 byte selector, params for contract (extraData)
        //     (sender, , , callbackFunction, extraData) = abi.decode(
        //         this.getParameters(receivedBytes),
        //         (address, string[], bytes, bytes4, bytes)
        //     );

        //     emit log_named_bytes("extraData: ", extraData);

        //     require(
        //         sender == address(vouchers),
        //         "The revert must be 'thrown' by Vouchers721 itself"
        //     );

        //     assertEq(callbackFunction, Vouchers721.joinWithSignature.selector);

        //     offchainLookupErrorThrown = true;
        // }

        // require(
        //     offchainLookupErrorThrown,
        //     "OffChainLookup invalid or not thrown."
        // );

        // To avoid solidity stack too deep errors, the resulting extraData is hardcoded in this test.
        // Uncomment code above to re-generate extraData.
        bytes
            memory extraData = hex"00000000000000000000000073a1564465e54a58de2dbc3b5032fd013fc95ad4566a2cc200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000001200000000000000000000000001d64f27720657aff7110688db6288f7574c3b711000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000000";

        // Craft service provider auth/proof
        // uint64 epochExpiration = uint64(block.timestamp) + uint64(1000); // signature expiration

        // bytes memory evePayload = abi.encodePacked(
        //     crowdtainerAddress,
        //     address(eve),
        //     quantities,
        //     false,
        //     address(0),
        //     epochExpiration,
        //     keccak256("random")
        // );

        // bytes32 eveMessage = keccak256(
        //     abi.encodePacked(
        //         "\x19Ethereum Signed Message:\n32",
        //         keccak256(evePayload)
        //     )
        // );

        // // Service provider signs 'authorization' for Eve
        // (uint8 vProvider, bytes32 rProvider, bytes32 sProvider) = cheats.sign(
        //     signerPrivateKey,
        //     eveMessage
        // );
        // bytes memory eveSignature = bytes.concat(
        //     rProvider,
        //     sProvider,
        //     bytes1(vProvider)
        // );
        // bytes memory eveProof = abi.encode(
        //     crowdtainerAddress,
        //     epochExpiration,
        //     keccak256("random"),
        //     eveSignature
        // );

        //  emit log_named_bytes("eveProof: ", eveProof);
        // To avoid solidity stack too deep errors, the resulting eveProof is hardcoded in this test.
        // Uncomment code above to re-generate eveProof.
        bytes
            memory eveProof = hex"00000000000000000000000073a1564465e54a58de2dbc3b5032fd013fc95ad40000000000000000000000000000000000000000000000000000000061e57f10a4896a3f93bf4bf58378e579f3cf193bb4af1022af7d2089f37d8bae7157b85f000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000411c9b054219414bc49d3283d98aef95f7a397562635ffda71a3d8bfb6573035d01c993ae07b92efdbf59e5dce1566b5e904eb79c97729d5003a2a2dc11313ddf21b00000000000000000000000000000000000000000000000000000000000000";

        uint256 totalCost = quantities[1] * unitPricePerType[1];
        totalCost += quantities[2] * unitPricePerType[2];

        // Create ERC-2612 signed 'permit' from Eve's EOA
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: eve,
            spender: address(defaultCrowdtainer),
            value: totalCost,
            nonce: 0,
            deadline: block.timestamp + 2 minutes
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(evePrivateKey, digest);

        SignedPermit memory signedPermit = SignedPermit(
            permit.owner,
            permit.spender,
            permit.value,
            permit.nonce,
            permit.deadline,
            v,
            r,
            s
        );

        // let service provider pay the gas.
        uint256 eveTokenId = agent.doJoinWithSignatureAndPermit(
            eveProof,
            extraData,
            signedPermit
        );

        assertEq(eveTokenId, vouchers.ID_MULTIPLE() + 1);

        assertEq(vouchers.ownerOf(eveTokenId), eve);
    }

    function testTokenIdToCrowdtainerIdMustSucceed(
        uint256 randomTokenId
    ) public {
        if (randomTokenId == 0 || randomTokenId < vouchers.ID_MULTIPLE()) {
            return;
        }
        // for any tokenId, the crowdtainer Id must be the following:
        uint256 derivedCrowdtainerId = vouchers.tokenIdToCrowdtainerId(
            randomTokenId
        );
        assertEq(randomTokenId / vouchers.ID_MULTIPLE(), derivedCrowdtainerId);
    }

    function testTokenIdMatchesCrowdtainerId() public {
        metadataService = IMetadataService(address(1));

        // setup
        VoucherParticipant neo = new VoucherParticipant(
            address(vouchers),
            address(erc20Token)
        );
        VoucherParticipant georg = new VoucherParticipant(
            address(vouchers),
            address(erc20Token)
        );
        erc20Token.mint(address(neo), 100000 * ONE);
        erc20Token.mint(address(georg), 100000 * ONE);

        uint256 crowdtainerId1;
        address crowdtainerAddress1;
        (crowdtainerAddress1, crowdtainerId1) = createCrowdtainer(address(0));

        uint256[] memory quantities = new uint256[](4);
        quantities[0] = 1;
        quantities[1] = 4;
        quantities[2] = 3;
        quantities[3] = 1;

        uint256 aliceCrowdtainer1TokenId = alice.doJoin({
            _crowdtainerAddress: crowdtainerAddress1,
            _quantities: quantities,
            _enableReferral: false,
            _referrer: address(0)
        });

        uint256 crowdtainerId2;
        address crowdtainerAddress2;
        (crowdtainerAddress2, crowdtainerId2) = createCrowdtainer(address(0));

        uint256 bobCrowdtainer2TokenId = bob.doJoin({
            _crowdtainerAddress: crowdtainerAddress2,
            _quantities: quantities,
            _enableReferral: false,
            _referrer: address(0)
        });

        neo.doApprovePayment(
            crowdtainerAddress2,
            type(uint256).max - 1000 * ONE
        );

        uint256 neoCrowdtainer2TokenId = neo.doJoin({
            _crowdtainerAddress: crowdtainerAddress2,
            _quantities: quantities,
            _enableReferral: false,
            _referrer: address(0)
        });

        uint256 crowdtainerId3;
        address crowdtainerAddress3;
        (crowdtainerAddress3, crowdtainerId3) = createCrowdtainer(address(0));

        georg.doApprovePayment(
            crowdtainerAddress3,
            type(uint256).max - 1000 * ONE
        );

        uint256 georgCrowdtainer3TokenId = georg.doJoin({
            _crowdtainerAddress: crowdtainerAddress3,
            _quantities: quantities,
            _enableReferral: false,
            _referrer: address(0)
        });

        alice.doApprovePayment(
            crowdtainerAddress3,
            type(uint256).max - 1000 * ONE
        );

        uint256 aliceCrowdtainer3TokenId = alice.doJoin({
            _crowdtainerAddress: crowdtainerAddress3,
            _quantities: quantities,
            _enableReferral: false,
            _referrer: address(0)
        });

        assertEq(crowdtainerId1, 1);
        assertEq(crowdtainerId2, 2);
        assertEq(crowdtainerId3, 3);

        // Derive CrowdtainerId from tokenId's and check correctness.

        assertEq(
            aliceCrowdtainer1TokenId / vouchers.ID_MULTIPLE(),
            crowdtainerId1
        );
        assertEq(
            bobCrowdtainer2TokenId / vouchers.ID_MULTIPLE(),
            crowdtainerId2
        );
        assertEq(
            neoCrowdtainer2TokenId / vouchers.ID_MULTIPLE(),
            crowdtainerId2
        );
        assertEq(
            georgCrowdtainer3TokenId / vouchers.ID_MULTIPLE(),
            crowdtainerId3
        );
        assertEq(
            aliceCrowdtainer3TokenId / vouchers.ID_MULTIPLE(),
            crowdtainerId3
        );
    }

    function testUserLeavesAndAttemptsToTransferVoucherMustFail() public {
        // This test is just a 'sanity check' on our ERC721 open zeppelin implementation.
        metadataService = IMetadataService(address(1));

        createCrowdtainer(address(0));

        uint256[] memory quantities = new uint256[](4);
        quantities[0] = 1;
        quantities[1] = 4;
        quantities[2] = 3;
        quantities[3] = 1;

        uint256 aliceCrowdtainerTokenId = alice.doJoin({
            _crowdtainerAddress: address(defaultCrowdtainer),
            _quantities: quantities,
            _enableReferral: false,
            _referrer: address(0)
        });

        // Bob purchases enough to make project succeed its target
        quantities[0] = 1;
        quantities[1] = 4;
        quantities[2] = 3;
        quantities[3] = 100;

        uint256 bobCrowdtainer1TokenId = bob.doJoin({
            _crowdtainerAddress: address(defaultCrowdtainer),
            _quantities: quantities,
            _enableReferral: false,
            _referrer: address(0)
        });

        // Alice decides to leave
        alice.doLeave(aliceCrowdtainerTokenId);

        // Shipping agent deems project successful (because bob purchase enough to hit target)
        agent.doGetPaidAndDeliver(defaultCrowdtainerId);

        // Bob must be able to transfer his voucher to another account.
        bob.doSafeTransferTo(address(10), bobCrowdtainer1TokenId);

        bool failed = true;
        // Alice attempts transfer her 'non-existent' voucher.
        try
            alice.doSafeTransferTo(address(11), aliceCrowdtainerTokenId)
        {} catch (bytes memory /*lowLevelData*/) {
            failed = false;
        }

        if (failed) fail();
    }

    function testShippingAgentAbleToSetVoucherClaimStatus() public {
        metadataService = IMetadataService(address(1));

        createCrowdtainer(address(0));

        // Alice purchases enough to make project succeed its target
        uint256[] memory quantities = new uint256[](4);
        quantities[0] = 1;
        quantities[1] = 4;
        quantities[2] = 3;
        quantities[3] = 100;

        uint256 aliceCrowdtainerTokenId = alice.doJoin({
            _crowdtainerAddress: address(defaultCrowdtainer),
            _quantities: quantities,
            _enableReferral: false,
            _referrer: address(0)
        });

        assertTrue(!vouchers.getClaimStatus(aliceCrowdtainerTokenId));

        // Shipping agent deems project successful
        agent.doGetPaidAndDeliver(defaultCrowdtainerId);

        // agent set claimed to true
        agent.doSetClaimStatus(aliceCrowdtainerTokenId, true);

        // verify state is true
        assertTrue(vouchers.getClaimStatus(aliceCrowdtainerTokenId));
    }

    function testFailJoinInexistentCrowdtainer() public {
        uint256[] memory quantities = new uint256[](4);
        quantities[0] = 1;
        quantities[1] = 4;
        quantities[2] = 3;
        quantities[3] = 1;

        try
            alice.doJoin({
                _crowdtainerAddress: address(0x111),
                _quantities: quantities,
                _enableReferral: false,
                _referrer: address(0)
            })
        {} catch (bytes memory lowLevelData) {
            bool failed = this.isEqualSignature(
                makeError(Errors.CrowdtainerInexistent.selector),
                lowLevelData
            );
            if (failed) fail();
        }
    }

    /*
    // To run this test the ID_MULTIPLE must be reduced to avoid test memory usage issues with hevm.
    function testFailGivenParticipantJoinLimitReachedThenErrorMustBeThrown() public {
        metadataService = IMetadataService(address(1));

        address crowdtainerAddress;
        (crowdtainerAddress,) = createCrowdtainer(address(0));

        for(uint256 i = 0; i < vouchers.ID_MULTIPLE(); ++i) {
            VoucherParticipant smith = new VoucherParticipant(address(vouchers), address(erc20Token));
            erc20Token.mint(address(smith), 100000);
            smith.doApprovePayment(crowdtainerAddress, 100000);

            try smith.doJoin({
                _crowdtainerAddress: crowdtainerAddress,
                _quantities: [uint256(1), 0, 0, 0],
                _enableReferral: false,
                _referrer: address(0)
            }) {} catch (bytes memory lowLevelData) {
                bool failed = this.isEqualSignature(
                makeError(Errors.MaximumNumberOfParticipantsReached.selector),
                lowLevelData
                );
                if(failed) fail();
                break;
            }
        }
    }*/

    function testTokenURIOfExistingTokenIdMustSucceed() public {
        metadataService = IMetadataService(
            new MetadataServiceV1({
                _unitSymbol: unicode"＄",
                _erc20Decimals: 6,
                _ticketFootnotes: "This voucher is not valid as an invoice."
            })
        );

        productDescription = [
            "Roasted beans 250g",
            "Roasted beans 500g",
            "Roasted beans 1Kg",
            "Roasted beans 2Kg"
        ];

        address crowdtainerAddress;

        (crowdtainerAddress, ) = createCrowdtainer(address(0));

        uint256[] memory quantities = new uint256[](4);
        quantities[0] = 1;
        quantities[1] = 4;
        quantities[2] = 3;
        quantities[3] = 1;

        uint256 tokenID = alice.doJoin({
            _crowdtainerAddress: crowdtainerAddress,
            _quantities: quantities,
            _enableReferral: false,
            _referrer: address(0)
        });

        string memory metadata = vouchers.tokenURI(tokenID);
        /*solhint-disable max-line-length*/
        assertEq(
            metadata,
            "data:application/json;base64,eyJjcm93ZHRhaW5lcklkIjoiMSIsICJ2b3VjaGVySWQiOiIxIiwgImN1cnJlbnRPd25lciI6IjB4MGI3MTA4ZTI3OGMyZTc3ZTRlNGY1YzkzZDllNWU5YTExYWM4MzdmYyIsICJlcmMyMFN5bWJvbCI6Iu+8hCIsICJlcmMyMERlY2ltYWxzIjoiNiIsICJkZXNjcmlwdGlvbiI6W3siZGVzY3JpcHRpb24iOiJSb2FzdGVkIGJlYW5zIDI1MGciLCJhbW91bnQiOiIxIiwicHJpY2VQZXJVbml0IjoiMTAwMDAwMDAifSwgeyJkZXNjcmlwdGlvbiI6IlJvYXN0ZWQgYmVhbnMgNTAwZyIsImFtb3VudCI6IjQiLCJwcmljZVBlclVuaXQiOiIyMDAwMDAwMCJ9LCB7ImRlc2NyaXB0aW9uIjoiUm9hc3RlZCBiZWFucyAxS2ciLCJhbW91bnQiOiIzIiwicHJpY2VQZXJVbml0IjoiMjUwMDAwMDAifSwgeyJkZXNjcmlwdGlvbiI6IlJvYXN0ZWQgYmVhbnMgMktnIiwiYW1vdW50IjoiMSIsInByaWNlUGVyVW5pdCI6IjIwMDAwMDAwMCJ9XSwgIlRvdGFsQ29zdCI6IjM2NTAwMDAwMCIsICJpbWFnZSI6ICJkYXRhOmltYWdlL3N2Zyt4bWw7YmFzZTY0LFBITjJaeUIzYVdSMGFEMGlNVEF3YlcwaUlHaGxhV2RvZEQwaU1UTXdiVzBpSUhacFpYZENiM2c5SWpBZ01DQXpNREFnTkRNd0lpQjJaWEp6YVc5dVBTSXhMakVpSUdsa1BTSnpkbWMxSWlCamJHRnpjejBpYzNablFtOWtlU0lnZUcxc2JuTTlJbWgwZEhBNkx5OTNkM2N1ZHpNdWIzSm5Mekl3TURBdmMzWm5JajQ4WnlCcFpEMGliR0Y1WlhJeElqNDhjR0YwYUNCcFpEMGljR0YwYURJaUlITjBlV3hsUFNKamIyeHZjam9qTURBd01EQXdPMlpwYkd3NmRYSnNLQ05UZG1kcWMweHBibVZoY2tkeVlXUnBaVzUwTWpVMk1TazdabWxzYkMxdmNHRmphWFI1T2pBdU9EazVNVGt6TzJacGJHd3RjblZzWlRwbGRtVnViMlJrTzNOMGNtOXJaUzEzYVdSMGFEb3hMalUwTlRRek95MXBibXR6WTJGd1pTMXpkSEp2YTJVNmJtOXVaU0lnWkQwaWJUTXlMakl3TWlBeE1pNDFPSEV0TWpZdU5UQTBOeTB1TURJeE5pMHlOaTQwTkRneElESTJMams0TTJ3d0lETTJNUzQzTXpnMGNTNHdNVEUwSURFeExqZ3pNU0F4TlM0M01qWTVJREV4TGpjNE1EbG9Oell1TnprM1l5MHVNVFl3T1MweExqYzBNVGd0TGpZM016UXRNVEV1TlRJNU1TQTRMakU1TURndE1URXVNRFkzT1M0eE5EVXpMakF3T0M0ek9ERTBMakF4TmpVdU5USTNOUzR3TVRZMWFEa3dMamd3TmpoakxqRTBOakVnTUNBdU16Z3pMUzR3TURVdU5USTVNUzB1TURBMUlEWXVOekF4TmkwdU1EQTJJRGN1TnpBNE15QTVMak0xTlRRZ055NDRNellnTVRFdU1EVTJNUzR3TVRBNUxqRTBOVE11TVRNMU1pNHlOak0wTGpJNE1UTXVNall6Tkd3NE1DNHdPVE14SURCeE1USXVNamcwT1M0d01pQXhNaTR5T1RRM0xURXlMakk1TkRkMkxUTTJNUzQzTmpZNWNTMHVNVEEyT0MweU5pNDVOakUwTFRJMkxqUTBPREl0TWpZdU9UZ3pNbWd0TmpZdU1qYzVOR011TURBeklERXlMall6TVRVdU1EVXdOQ0E1TGpVMU5Ua3ROVFF1TnpJNElEa3VOVFEyTFRRNExqTTBPQzR3TVRBMkxUVXhMalU0TlRRZ01pNHhOelk0TFRVeExqZ3dORFF0T1M0M05UUXllaUl2UGp4MFpYaDBJSGh0YkRwemNHRmpaVDBpY0hKbGMyVnlkbVVpSUdOc1lYTnpQU0p0WldScGRXMGlJSGc5SWpFd0xqUTNPRE0xTkNJZ2VUMGlNQ0lnYVdROUluUmxlSFF4TmpJNE1DMDJMVGtpSUhSeVlXNXpabTl5YlQwaWJXRjBjbWw0S0RFMkxqUTVNVFlzTUN3d0xERTFMall5TnpVME55dzNMakV6TWpVeU1URXNOVFF1TmpZME9UTXlLU0krUEhSemNHRnVJSGc5SWpFMUxqUTNPRE0xTkNJZ2VUMGlNU0krUTNKdmQyUjBZV2x1WlhJZ01Ud3ZkSE53WVc0K1BDOTBaWGgwUGp4MFpYaDBJSGh0YkRwemNHRmpaVDBpY0hKbGMyVnlkbVVpSUdOc1lYTnpQU0owYVc1NUlpQjRQU0l4TUM0ME56Z3pOVFFpSUhrOUlqQWlJR2xrUFNKMFpYaDBNVFl5T0RBdE5pMDVMVGNpSUhSeVlXNXpabTl5YlQwaWJXRjBjbWw0S0RFMkxqUTVNVFlzTUN3d0xERTFMall5TnpVME55dzFMamN5T0RJNE9EUXNPVEF1TVRZd01EazRLU0krUEhSemNHRnVJSGc5SWpFMUxqUTNPRE0xTkNJZ2VUMGlNUzQxSWlCcFpEMGlkSE53WVc0eE1UWXpJajVEYkdGcGJXVmtPaUJPYnp3dmRITndZVzQrUEM5MFpYaDBQangwWlhoMElIaHRiRHB6Y0dGalpUMGljSEpsYzJWeWRtVWlJR05zWVhOelBTSnRaV1JwZFcwaUlIZzlJakV6TGpRM09ETTFOQ0lnZVQwaU1UUXVNVFk0T1RrME5DSWdhV1E5SW5SbGVIUXhOakk0TUMwMklpQjBjbUZ1YzJadmNtMDlJbTFoZEhKcGVDZ3hOaTQwT1RFMkxEQXNNQ3d4TlM0Mk1qYzFORGNzTnk0MU9EazNOeklzTmk0NU9UUTNPVEF6S1NJK1BIUnpjR0Z1SUhnOUlqRTFMalEzT0RNMU5DSWdlVDBpTlM0MElpQnBaRDBpZEhOd1lXNHhNVFkxSWo1V2IzVmphR1Z5SURFOEwzUnpjR0Z1UGp3dmRHVjRkRDQ4ZEdWNGRDQjRiV3c2YzNCaFkyVTlJbkJ5WlhObGNuWmxJaUJqYkdGemN6MGljMjFoYkd3aUlIZzlJakVpSUhrOUlqRXdJaUIwY21GdWMyWnZjbTA5SW0xaGRISnBlQ2d4Tmk0ME9URTJMREFzTUN3eE5TNDJNamMxTkRjc055NDFPRGszTnpJc05pNDVPVFEzT1RBektTSStNUWw0SUFsU2IyRnpkR1ZrSUdKbFlXNXpJREkxTUdjSklDMGdDVEV3Q2UrOGhEd3ZkR1Y0ZEQ0OGRHVjRkQ0I0Yld3NmMzQmhZMlU5SW5CeVpYTmxjblpsSWlCamJHRnpjejBpYzIxaGJHd2lJSGc5SWpFaUlIazlJakV4SWlCMGNtRnVjMlp2Y20wOUltMWhkSEpwZUNneE5pNDBPVEUyTERBc01Dd3hOUzQyTWpjMU5EY3NOeTQxT0RrM056SXNOaTQ1T1RRM09UQXpLU0krTkFsNElBbFNiMkZ6ZEdWa0lHSmxZVzV6SURVd01HY0pJQzBnQ1RJd0NlKzhoRHd2ZEdWNGRENDhkR1Y0ZENCNGJXdzZjM0JoWTJVOUluQnlaWE5sY25abElpQmpiR0Z6Y3owaWMyMWhiR3dpSUhnOUlqRWlJSGs5SWpFeUlpQjBjbUZ1YzJadmNtMDlJbTFoZEhKcGVDZ3hOaTQwT1RFMkxEQXNNQ3d4TlM0Mk1qYzFORGNzTnk0MU9EazNOeklzTmk0NU9UUTNPVEF6S1NJK013bDRJQWxTYjJGemRHVmtJR0psWVc1eklERkxad2tnTFNBSk1qVUo3N3lFUEM5MFpYaDBQangwWlhoMElIaHRiRHB6Y0dGalpUMGljSEpsYzJWeWRtVWlJR05zWVhOelBTSnpiV0ZzYkNJZ2VEMGlNU0lnZVQwaU1UTWlJSFJ5WVc1elptOXliVDBpYldGMGNtbDRLREUyTGpRNU1UWXNNQ3d3TERFMUxqWXlOelUwTnl3M0xqVTRPVGMzTWl3MkxqazVORGM1TURNcElqNHhDWGdnQ1ZKdllYTjBaV1FnWW1WaGJuTWdNa3RuQ1NBdElBa3lNREFKNzd5RVBDOTBaWGgwUGp4MFpYaDBJSGh0YkRwemNHRmpaVDBpY0hKbGMyVnlkbVVpSUdOc1lYTnpQU0p6YldGc2JDSWdlRDBpTWlJZ2VUMGlNVFVpSUhSeVlXNXpabTl5YlQwaWJXRjBjbWw0S0RFMkxqUTVNVFlzTUN3d0xERTFMall5TnpVME55dzNMalU0T1RjM01pdzJMams1TkRjNU1ETXBJajVVYjNSaGJDRHZ2SVF6TmpVOEwzUmxlSFErUEhSbGVIUWdlRzFzT25Od1lXTmxQU0p3Y21WelpYSjJaU0lnWTJ4aGMzTTlJbVp2YjNSbGNpSWdlRDBpT0RVaUlIazlJak00TUNJZ2RISmhibk5tYjNKdFBTSnpZMkZzWlNneExqQXlOekkzTXpNc01DNDVOek0wTlRBNE1Ta2lQbFJvYVhNZ2RtOTFZMmhsY2lCcGN5QnViM1FnZG1Gc2FXUWdZWE1nWVc0Z2FXNTJiMmxqWlM0OEwzUmxlSFErUEM5blBqeHpkSGxzWlQ0dWMzWm5RbTlrZVNCN1ptOXVkQzFtWVcxcGJIazZJQ0pJWld4MlpYUnBZMkVpSUgwdWRHbHVlU0I3Wm05dWRDMXpkSEpsZEdOb09tNXZjbTFoYkR0bWIyNTBMWE5wZW1VNk1DNDFNalUyTWpSd2VEdHNhVzVsTFdobGFXZG9kRG94TGpJMU8zUmxlSFF0WVc1amFHOXlPbVZ1WkR0M2FHbDBaUzF6Y0dGalpUcHdjbVU3Wm1sc2JEb2paamxtT1dZNU8zMHVabTl2ZEdWeUlIdG1iMjUwTFhOMGNtVjBZMmc2Ym05eWJXRnNPMlp2Ym5RdGMybDZaVG8zY0hnN2JHbHVaUzFvWldsbmFIUTZMakkxTzNkb2FYUmxMWE53WVdObE9uQnlaVHRtYVd4c09pTm1PV1k1WmprN2ZTNXpiV0ZzYkNCN1ptOXVkQzF6YVhwbE9qQXVOWEI0TzNSbGVIUXRZV3hwWjI0NmMzUmhjblE3ZEdWNGRDMWhibU5vYjNJNmMzUmhjblE3ZDJocGRHVXRjM0JoWTJVNmNISmxPMlpwYkd3NkkyWTVaamxtT1R0OUxtMWxaR2wxYlNCN1ptOXVkQzF6YVhwbE9qQXVPVEp3ZUR0bWIyNTBMV1poYldsc2VUcElaV3gyWlhScFkyRTdkR1Y0ZEMxaGJHbG5ianBsYm1RN2RHVjRkQzFoYm1Ob2IzSTZaVzVrTzNkb2FYUmxMWE53WVdObE9uQnlaVHRtYVd4c09pTm1PV1k1WmprN2ZUd3ZjM1I1YkdVK1BHeHBibVZoY2tkeVlXUnBaVzUwSUhneFBTY3dKU2NnZVRFOUp6TXdKU2NnZURJOUp6WXdKU2NnZVRJOUp6a3dKU2NnWjNKaFpHbGxiblJWYm1sMGN6MG5kWE5sY2xOd1lXTmxUMjVWYzJVbklHbGtQU2RUZG1kcWMweHBibVZoY2tkeVlXUnBaVzUwTWpVMk1TYytQSE4wYjNBZ2MzUnZjQzFqYjJ4dmNqMG5jbWRpWVNneU1Dd2dNVEV3TENBeE5qQXNJREV3TUNrbklHOW1abk5sZEQwbk1DNHdNaWMrUEM5emRHOXdQanh6ZEc5d0lITjBiM0F0WTI5c2IzSTlKM0puWW1Fb01qVXNJRFU1TENBNU1Dd2dNVEF3S1NjZ2IyWm1jMlYwUFNjeEp6NDhMM04wYjNBK1BDOXNhVzVsWVhKSGNtRmthV1Z1ZEQ0OEwzTjJaejQ9In0="
        );
        /*solhint-enable max-line-length*/
    }
}

contract Vouchers721FailureTester is VouchersTest {
    function testFailTransferDuringFundingState() public {
        metadataService = IMetadataService(address(1));
        address crowdtainerAddress;

        (crowdtainerAddress, ) = createCrowdtainer(address(0));

        uint256[] memory quantities = new uint256[](4);
        quantities[3] = 100;

        uint256 tokenId = alice.doJoin({
            _crowdtainerAddress: crowdtainerAddress,
            _quantities: quantities,
            _enableReferral: false,
            _referrer: address(0)
        });

        alice.doApprove(address(bob), tokenId);

        try alice.doSafeTransferTo(address(bob), tokenId) {} catch (
            bytes memory lowLevelData
        ) {
            bool failed = this.isEqualSignature(
                makeError(Errors.TransferNotAllowed.selector),
                lowLevelData
            );
            if (failed) fail();
        }
    }
}

contract Vouchers721CreateInvalidTester is VouchersTest {
    function testFailUseInvalidMetadataServiceAddress() public {
        string[] memory productDescription = new string[](4);
        try
            vouchers.createCrowdtainer({
                _campaignData: CampaignData(
                    address(agent),
                    address(0),
                    openingTime,
                    closingTime,
                    targetMinimum,
                    targetMaximum,
                    unitPricePerType,
                    referralRate,
                    referralEligibilityValue,
                    address(iERC20Token),
                    ""
                ),
                _productDescription: productDescription,
                _metadataService: address(metadataService)
            })
        {} catch (bytes memory lowLevelData) {
            bool failed = this.isEqualSignature(
                makeError(Errors.MetadataServiceAddressIsZero.selector),
                lowLevelData
            );
            if (failed) fail();
        }
    }

    function testFailErrorBubblesUpToVouchers721() public {
        // Equivalent to Crowdtainer's test 'testFailJoinWithValueRaisedAboveMaximumTarget'
        // This test is to make sure that the 'external' contract call (into Crowdtainer.sol), has its
        // custom errors propagating correctly in Vouchers721.sol.
        metadataService = IMetadataService(address(1));

        createCrowdtainer(address(0));

        uint256[] memory quantities = new uint256[](4);
        quantities[0] = 1;
        quantities[1] = 4;
        quantities[2] = 300;
        quantities[3] = 100;

        try
            alice.doJoin({
                _crowdtainerAddress: address(defaultCrowdtainer),
                _quantities: quantities,
                _enableReferral: true,
                _referrer: address(0)
            })
        {} catch (bytes memory lowLevelData) {
            bool failed = this.isEqualSignature(
                makeError(Errors.ExceededNumberOfItemsAllowed.selector),
                lowLevelData
            );
            if (failed) fail();
        }
    }
}

/* solhint-enable no-empty-blocks */
