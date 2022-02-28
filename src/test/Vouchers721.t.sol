// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

import "./utils/Vouchers721Test.sol";
import {Errors} from "../Crowdtainer.sol";

import "../Metadata/MetadataServiceV1.sol";

/* solhint-disable no-empty-blocks */

contract Vouchers721CreateTester is VouchersTest {
    function testCreateCrowdtainerMustSucceed() public {
        metadataService = IMetadataService(address(1));

        uint256 crowdtainerId1;
        address crowdtainerAddress1;
        (crowdtainerAddress1, crowdtainerId1) = createCrowdtainer();

        assert(vouchers.crowdtainerForId(crowdtainerId1) == crowdtainerAddress1);
        assert(crowdtainerAddress1 != address(0));

        assertEq(crowdtainerId1, 1);

        uint256 crowdtainerId2;
        address crowdtainerAddress2;
        (crowdtainerAddress2, crowdtainerId2) = createCrowdtainer();

        assertEq(crowdtainerId2, 2);
        assertTrue(crowdtainerAddress1 != crowdtainerAddress2);
    }

    function testTokenIdMustBeSequential() public {
        metadataService = IMetadataService(address(1));
        address crowdtainerAddress;

        (crowdtainerAddress,) = createCrowdtainer();
        uint256 tokenId = alice.doJoin({
            _crowdtainerAddress: crowdtainerAddress,
            _quantities: [uint256(1), 4, 3, 1],
            _enableReferral: false,
            _referrer: address(0)
        });

       assertEq(tokenId, vouchers.ID_MULTIPLE() + 1);

        tokenId = bob.doJoin({
            _crowdtainerAddress: crowdtainerAddress,
            _quantities: [uint256(1), 4, 3, 1],
            _enableReferral: false,
            _referrer: address(0)
        });

        assertEq(tokenId, vouchers.ID_MULTIPLE() + 2);
    }

    function testTokenIdToCrowdtainerIdMustSucceed(uint256 randomTokenId) public {

        if(randomTokenId == 0
           || randomTokenId < vouchers.ID_MULTIPLE()) {
            return;
        }
        // for any tokenId, the crowdtainer Id must be the following:
        uint256 derivedCrowdtainerId = vouchers.tokenIdToCrowdtainerId(randomTokenId);
        assertEq(randomTokenId / vouchers.ID_MULTIPLE(), derivedCrowdtainerId);
    }

    function testTokenIdMatchesCrowdtainerId() public {
        metadataService = IMetadataService(address(1));

        // setup
        VoucherParticipant neo = new VoucherParticipant(address(vouchers), address(erc20Token));
        VoucherParticipant georg = new VoucherParticipant(address(vouchers), address(erc20Token));
        erc20Token.mint(address(neo), 100000);
        erc20Token.mint(address(georg), 100000);

        uint256 crowdtainerId1;
        address crowdtainerAddress1;
        (crowdtainerAddress1, crowdtainerId1) = createCrowdtainer();

        uint256 aliceCrowdtainer1TokenId = alice.doJoin({
            _crowdtainerAddress: crowdtainerAddress1,
            _quantities: [uint256(1), 4, 3, 1],
            _enableReferral: false,
            _referrer: address(0)
        });

        uint256 crowdtainerId2;
        address crowdtainerAddress2;
        (crowdtainerAddress2, crowdtainerId2) = createCrowdtainer();

        uint256 bobCrowdtainer2TokenId = bob.doJoin({
            _crowdtainerAddress: crowdtainerAddress2,
            _quantities: [uint256(1), 4, 3, 1],
            _enableReferral: false,
            _referrer: address(0)
        });

        neo.doApprovePayment(crowdtainerAddress2, type(uint256).max - 1000);

        uint256 neoCrowdtainer2TokenId = neo.doJoin({
            _crowdtainerAddress: crowdtainerAddress2,
            _quantities: [uint256(1), 4, 3, 1],
            _enableReferral: false,
            _referrer: address(0)
        });

        uint256 crowdtainerId3;
        address crowdtainerAddress3;
        (crowdtainerAddress3, crowdtainerId3) = createCrowdtainer();

        georg.doApprovePayment(crowdtainerAddress3, type(uint256).max - 1000);

        uint256 georgCrowdtainer3TokenId = georg.doJoin({
            _crowdtainerAddress: crowdtainerAddress3,
            _quantities: [uint256(1), 4, 3, 1],
            _enableReferral: false,
            _referrer: address(0)
        });

        alice.doApprovePayment(crowdtainerAddress3, type(uint256).max - 1000);

        uint256 aliceCrowdtainer3TokenId = alice.doJoin({
            _crowdtainerAddress: crowdtainerAddress3,
            _quantities: [uint256(1), 4, 3, 1],
            _enableReferral: false,
            _referrer: address(0)
        });

        assertEq(crowdtainerId1, 1);
        assertEq(crowdtainerId2, 2);
        assertEq(crowdtainerId3, 3);

        // Derive CrowdtainerId from tokenId's and check correctness.

        assertEq(aliceCrowdtainer1TokenId / vouchers.ID_MULTIPLE(), crowdtainerId1);
        assertEq(bobCrowdtainer2TokenId / vouchers.ID_MULTIPLE(), crowdtainerId2);
        assertEq(neoCrowdtainer2TokenId / vouchers.ID_MULTIPLE(), crowdtainerId2);
        assertEq(georgCrowdtainer3TokenId / vouchers.ID_MULTIPLE(), crowdtainerId3);
        assertEq(aliceCrowdtainer3TokenId / vouchers.ID_MULTIPLE(), crowdtainerId3);

    }

    function testUserLeavesAndAttemptsToTransferVoucherMustFail() public {
        // This test is just a 'sanity check' on our ERC721 open zeppelin implementation.
        metadataService = IMetadataService(address(1));

        createCrowdtainer();

        // Bob purchases enough to make project succeed its target
        uint256 aliceCrowdtainerTokenId = alice.doJoin({
            _crowdtainerAddress: address(defaultCrowdtainer),
            _quantities: [uint256(1), 4, 3, 1],
            _enableReferral: false,
            _referrer: address(0)
        });

        // Bob purchases enough to make project succeed its target
        uint256 bobCrowdtainer1TokenId = bob.doJoin({
            _crowdtainerAddress: address(defaultCrowdtainer),
            _quantities: [uint256(1), 4, 3, 100],
            _enableReferral: false,
            _referrer: address(0)
        });

        // Alice decides to leave
        alice.doLeave(aliceCrowdtainerTokenId);

        // Shipping agent deems project successful (because bob purchase enough to hit target)
        agent.doGetPaidAndDeliver(defaultCrowdtainerId);

        // Bob must be able to transfer his voucher to another account.
        bob.doSafeTransferTo(address(10), bobCrowdtainer1TokenId);

        failed = true;
        // Alice attempts transfer her 'non-existent' voucher.
        try alice.doSafeTransferTo(address(11), aliceCrowdtainerTokenId) {} catch (
            bytes memory /*lowLevelData*/
        ) {
            failed = false;
        }
    }

    function testFailJoinInexistentCrowdtainer() public {

        try alice.doJoin({
            _crowdtainerAddress: address(0x111),
            _quantities: [uint256(1), 4, 3, 1],
            _enableReferral: false,
            _referrer: address(0)
        }) {} catch (
            bytes memory lowLevelData
        ) {
            failed = this.assertEqSignature(
                makeError(Errors.CrowdtainerInexistent.selector),
                lowLevelData
                );
        }
    }

    /*
    // To run this test the ID_MULTIPLE must be reduced to avoid test memory usage issues with hevm.
    function testFailGivenParticipantJoinLimitReachedThenErrorMustBeThrown() public {
        metadataService = IMetadataService(address(1));

        address crowdtainerAddress;
        (crowdtainerAddress,) = createCrowdtainer();

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
                failed = this.assertEqSignature(
                makeError(Errors.MaximumNumberOfParticipantsReached.selector),
                lowLevelData
                );
                break;
            }
        }
    }*/

    function testTokenURIOfExistingTokenIdMustSucceed() public {
        metadataService = IMetadataService(
            new MetadataServiceV1({
                _unitSymbol: unicode"＄",
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

        (crowdtainerAddress,) = createCrowdtainer();

        uint256 tokenID = alice.doJoin({
            _crowdtainerAddress: crowdtainerAddress,
            _quantities: [uint256(1), 4, 3, 1],
            _enableReferral: false,
            _referrer: address(0)
        });

        string memory metadata = vouchers.tokenURI(tokenID);
        /*solhint-disable max-line-length*/
        assertEq(
            metadata,
            "data:application/json;base64,eyJjcm93ZHRhaW5lcklkIjoiMSIsICJ2b3VjaGVySWQiOiIxIiwgImN1cnJlbnRPd25lciI6IjB4MHg0Mjk5N2FjOTI1MWU1YmIwYTYxZjRmZjc5MGU1Yjk5MWVhMDdmZDliIiwgImRlc2NyaXB0aW9uIjpbeyJkZXNjcmlwdGlvbiI6IlJvYXN0ZWQgYmVhbnMgMjUwZyIsImFtb3VudCI6IjEiLCJwcmljZVBlclVuaXQiOiIxMCJ9LCB7ImRlc2NyaXB0aW9uIjoiUm9hc3RlZCBiZWFucyA1MDBnIiwiYW1vdW50IjoiNCIsInByaWNlUGVyVW5pdCI6IjIwIn0sIHsiZGVzY3JpcHRpb24iOiJSb2FzdGVkIGJlYW5zIDFLZyIsImFtb3VudCI6IjMiLCJwcmljZVBlclVuaXQiOiIyNSJ9LCB7ImRlc2NyaXB0aW9uIjoiUm9hc3RlZCBiZWFucyAyS2ciLCJhbW91bnQiOiIxIiwicHJpY2VQZXJVbml0IjoiMjAwIn1dLCAiVG90YWxDb3N0IjoiMzY1IiwgImltYWdlIjogImRhdGE6aW1hZ2Uvc3ZnK3htbDtiYXNlNjQsUEhOMlp5QjNhV1IwYUQwaU9UQnRiU0lnYUdWcFoyaDBQU0l4TXpCdGJTSWdkbWxsZDBKdmVEMGlNQ0F3SURJeE1DQXpNREFpSUhabGNuTnBiMjQ5SWpFdU1TSWdhV1E5SW5OMlp6VWlJR05zWVhOelBTSnpkbWRDYjJSNUlpQjRiV3h1Y3owaWFIUjBjRG92TDNkM2R5NTNNeTV2Y21jdk1qQXdNQzl6ZG1jaVBqeG5JR2xrUFNKc1lYbGxjakVpUGp4d1lYUm9JR2xrUFNKd1lYUm9NaUlnYzNSNWJHVTlJbU52Ykc5eU9pTXdNREF3TURBN1ptbHNiRG9qTVRneU1ETTNPMlpwYkd3dGIzQmhZMmwwZVRvd0xqZzVPVEU1TXp0bWFXeHNMWEoxYkdVNlpYWmxibTlrWkR0emRISnZhMlV0ZDJsa2RHZzZNUzQxTkRVME16c3RhVzVyYzJOaGNHVXRjM1J5YjJ0bE9tNXZibVVpSUdROUltMGdOVEl1TURrNE5qazRMREk0TGpjME5EWXhPU0JqSUMweU5DNHdPREE1TnpJc01DNHdPRGN5TmlBdE1qWXVOREl4TXpRNExERXlMakV4TURRNE15QXRNall1TkRRNE1EY3lMREkyTGprNE16QXlPU0F0TWk0Mk1tVXROQ3d3TGpFME5qRXdNU0F0TWk0ek5XVXROQ3d3TGpNNE1qazVPQ0F0TWk0ek5XVXROQ3d3TGpVeU9URXlNeUJzSURBc016WXhMamN6T0RReE9TQmpJREFzTUM0eE5EWXhNaUF0TUM0d01ETXpMREF1TXpnek1ERWdMVEF1TURBek9Dd3dMalV5T1RFeklDMHdMakF6TmpVMkxERXdMalF6T0RneElERXpMalkwT0RRNE9Dd3hNUzQyTlRZeU15QXhOUzQzTWpZNU5EZ3NNVEV1Tnpnd09UTWdNQzR4TkRVeU9EVXNNQzR3TURrZ01DNHpPREUyTmpjc01DNHdNVE14SURBdU5USTNOemt5TERBdU1ERXpNU0JvSURjMkxqYzVOekF3T0NCaklEQXVNVFEyTVRJc01DQXdMakkxTEMwd0xqRXhOelU0SURBdU1qTTJOVFlzTFRBdU1qWXpNRGdnTFRBdU1UWXdPVElzTFRFdU56UXhPRE1nTFRBdU5qY3pORE1zTFRFeExqVXlPVEEySURndU1Ua3dPRFFzTFRFeExqQTJOemczSURBdU1UUTFNeklzTUM0d01EZ2dNQzR6T0RFME1pd3dMakF4TmpVZ01DNDFNamMxTkN3d0xqQXhOalVnYUNBNU1DNDRNRFkzT0NCaklEQXVNVFEyTVRJc01DQXdMak00TWprNExDMHdMakF3TlNBd0xqVXlPVEVzTFRBdU1EQTFJRFl1TnpBeE5UVXNMVEF1TURBMklEY3VOekE0TXpRc09TNHpOVFUwTWlBM0xqZ3pOVGsxTERFeExqQTFOakV6SURBdU1ERXdPU3d3TGpFME5UTTBJREF1TVRNMU1UZ3NNQzR5TmpNek5pQXdMakk0TVRNc01DNHlOak16TmlCc0lEZ3dMakE1TXpBM0xEQWdZU0F4TWk0eU9UUTJPVFFzTVRJdU1qazBOamswSURFek5TQXdJREFnTVRJdU1qazBOamtzTFRFeUxqSTVORFk1SUhZZ0xUTTJNUzQzTmpZNE9Ua2dZeUF3TEMwd0xqRTBOakV5TlNBeVpTMDFMQzB3TGpNNE16QTBNU0F0TVM0MFpTMDBMQzB3TGpVeU9URTJOaUF0TUM0d01qQTJMQzB4T1M0eU1EYzVOeklnTFRJdU16TTBPVGtzTFRJMkxqa3lOek0wTVNBdE1qWXVORFE0TWl3dE1qWXVPVGd6TVRVNUlDMHdMakUwTmpFeExDMHpMak00WlMwMElDMHdMak00TXpBeExDMHpMakExWlMwMElDMHdMalV5T1RFekxDMHpMakExWlMwMElHZ2dMVFkyTGpJM09UUXpJR0VnTUM0eU5EZ3pNekExTVN3d0xqSTBPRE16TURVeElERXpNeTR4T0RVd05pQXdJREFnTFRBdU1qUTNPRE1zTUM0eU5qUXdOVE1nWXlBd0xqQXdOU3d3TGpBM05UTWdNQzR3TURrc01DNHlOVFEzT1RVZ01DNHdNRGtzTUM0ME1EQTVNaUF3TGpBd015d3hNaTQyTXpFME5qa2dNQzR3TlRBMExEa3VOVFUxT0RnZ0xUVTBMamN5TnprMkxEa3VOVFExT1RnNElDMHdMakUwTlRrMUxDMHlMalpsTFRVZ0xUQXVNemd5TnpNc0xUSXVOMlV0TlNBdE1DNDFNamc0TlN3MVpTMDJJQzAwT0M0ek5EYzVPU3d3TGpBeE1EWWdMVFE1TGpnME5EQTVMREl1T1RFME56STBJQzAxTVM0MU5Ua3dNeXd0T1M0MU5EZzNORGNnTFRBdU1ERTVPU3d0TUM0eE5EUTFPRFVnTFRBdU1ETTFNaXd0TUM0ek9EQXlPRFVnTFRBdU1ETTBOQ3d0TUM0MU1qWTBNRGtnWVNBd0xqSXdOVGN6T0RJNExEQXVNakExTnpNNE1qZ2dNalV1TVRnNE5UVTFJREFnTUNBdE1DNHlOak01TkN3dE1DNHhNalF4TXpnZ2JDQXROall1TWpVMk1EUTJMQzB3TGpBeE1UWXpJR01nTFRBdU1UUTJNVEkxTEMweUxqVmxMVFVnTFRBdU16Z3pNRFF4TEMwNUxqZGxMVFVnTFRBdU5USTVNVFkyTERRdU16SmxMVFFnZWlJZ2RISmhibk5tYjNKdFBTSnRZWFJ5YVhnb01DNDJNVGN6TmpFeE15d3dMREFzTUM0Mk1UY3pOakV4TXl3d0xDMHpMakUyTmpZM05Da2lJQ0F2UGp4d1lYUm9JSE4wZVd4bFBTSm1hV3hzT2lCbmNtVjVPeUFpSUhSeVlXNXpabTl5YlQwaWJXRjBjbWw0S0RBdU5qRTNNell4TVRNc01Dd3dMREF1TmpFM016WXhNVE1zTXpBc016QXVNVFkyTmpjMEtTSWdaRDBpVFRFeExqazBOQ0F4Tnk0NU55QTBMalU0SURFekxqWXlJREV4TGprME15QXlOR3czTGpNM0xURXdMak00TFRjdU16Y3lJRFF1TXpWb0xqQXdNM3BOTVRJdU1EVTJJREFnTkM0Mk9TQXhNaTR5TWpOc055NHpOalVnTkM0ek5UUWdOeTR6TmpVdE5DNHpOVXd4TWk0d05UWWdNSG9pTHo0OGRHVjRkQ0I0Yld3NmMzQmhZMlU5SW5CeVpYTmxjblpsSWlCamJHRnpjejBpYldWa2FYVnRJaUI0UFNJeE1DNDBOemd6TlRRaUlIazlJakFpSUdsa1BTSjBaWGgwTVRZeU9EQXROaTA1SWlCMGNtRnVjMlp2Y20wOUltMWhkSEpwZUNneE5pNDBPVEUyTERBc01Dd3hOUzQyTWpjMU5EY3NOeTR4TXpJMU1qRXhMRFUwTGpZMk5Ea3pNaWtpUGp4MGMzQmhiaUI0UFNJeE1DNDBOemd6TlRRaUlIazlJakFpUGtOeWIzZGtkR0ZwYm1WeUlDTWdNVHd2ZEhOd1lXNCtQQzkwWlhoMFBqeDBaWGgwSUhodGJEcHpjR0ZqWlQwaWNISmxjMlZ5ZG1VaUlHTnNZWE56UFNKMGFXNTVJaUI0UFNJeE1DNDBOemd6TlRRaUlIazlJakFpSUdsa1BTSjBaWGgwTVRZeU9EQXROaTA1TFRjaUlIUnlZVzV6Wm05eWJUMGliV0YwY21sNEtERTJMalE1TVRZc01Dd3dMREUxTGpZeU56VTBOeXcxTGpjeU9ESTRPRFFzT1RBdU1UWXdNRGs0S1NJK1BIUnpjR0Z1SUhnOUlqRXdMalEzT0RNMU5DSWdlVDBpTUNJZ2FXUTlJblJ6Y0dGdU1URTJNeUkrUTJ4aGFXMWxaRG9nVG04OEwzUnpjR0Z1UGp3dmRHVjRkRDQ4ZEdWNGRDQjRiV3c2YzNCaFkyVTlJbkJ5WlhObGNuWmxJaUJqYkdGemN6MGliV1ZrYVhWdElpQjRQU0l4TXk0ME56Z3pOVFFpSUhrOUlqRTBMakUyT0RrNU5EUWlJR2xrUFNKMFpYaDBNVFl5T0RBdE5pSWdkSEpoYm5ObWIzSnRQU0p0WVhSeWFYZ29NVFl1TkRreE5pd3dMREFzTVRVdU5qSTNOVFEzTERjdU5UZzVOemN5TERZdU9UazBOemt3TXlraVBqeDBjM0JoYmlCNFBTSXhNQzQwTnpnek5UUWlJSGs5SWpRdU1UWTRPVGswTkNJZ2FXUTlJblJ6Y0dGdU1URTJOU0krVm05MVkyaGxjaUFqSURFOEwzUnpjR0Z1UGp3dmRHVjRkRDQ4ZEdWNGRDQjRiV3c2YzNCaFkyVTlJbkJ5WlhObGNuWmxJaUJqYkdGemN6MGljMjFoYkd3aUlIZzlJaklpSUhrOUlqY2lJSFJ5WVc1elptOXliVDBpYldGMGNtbDRLREUyTGpRNU1UWXNNQ3d3TERFMUxqWXlOelUwTnl3M0xqVTRPVGMzTWl3MkxqazVORGM1TURNcElqNHhJQ0I0SUNCU2IyRnpkR1ZrSUdKbFlXNXpJREkxTUdjZ0xTRHZ2SVF4TUR3dmRHVjRkRDQ4ZEdWNGRDQjRiV3c2YzNCaFkyVTlJbkJ5WlhObGNuWmxJaUJqYkdGemN6MGljMjFoYkd3aUlIZzlJaklpSUhrOUlqZ2lJSFJ5WVc1elptOXliVDBpYldGMGNtbDRLREUyTGpRNU1UWXNNQ3d3TERFMUxqWXlOelUwTnl3M0xqVTRPVGMzTWl3MkxqazVORGM1TURNcElqNDBJQ0I0SUNCU2IyRnpkR1ZrSUdKbFlXNXpJRFV3TUdjZ0xTRHZ2SVF5TUR3dmRHVjRkRDQ4ZEdWNGRDQjRiV3c2YzNCaFkyVTlJbkJ5WlhObGNuWmxJaUJqYkdGemN6MGljMjFoYkd3aUlIZzlJaklpSUhrOUlqa2lJSFJ5WVc1elptOXliVDBpYldGMGNtbDRLREUyTGpRNU1UWXNNQ3d3TERFMUxqWXlOelUwTnl3M0xqVTRPVGMzTWl3MkxqazVORGM1TURNcElqNHpJQ0I0SUNCU2IyRnpkR1ZrSUdKbFlXNXpJREZMWnlBdElPKzhoREkxUEM5MFpYaDBQangwWlhoMElIaHRiRHB6Y0dGalpUMGljSEpsYzJWeWRtVWlJR05zWVhOelBTSnpiV0ZzYkNJZ2VEMGlNaUlnZVQwaU1UQWlJSFJ5WVc1elptOXliVDBpYldGMGNtbDRLREUyTGpRNU1UWXNNQ3d3TERFMUxqWXlOelUwTnl3M0xqVTRPVGMzTWl3MkxqazVORGM1TURNcElqNHhJQ0I0SUNCU2IyRnpkR1ZrSUdKbFlXNXpJREpMWnlBdElPKzhoREl3TUR3dmRHVjRkRDQ4ZEdWNGRDQjRiV3c2YzNCaFkyVTlJbkJ5WlhObGNuWmxJaUJqYkdGemN6MGljMjFoYkd3aUlIZzlJakV1T1RVMU1UQXlOQ0lnZVQwaU1UTWlJSFJ5WVc1elptOXliVDBpYldGMGNtbDRLREUyTGpRNU1UWXNNQ3d3TERFMUxqWXlOelUwTnl3M0xqVTRPVGMzTWl3MkxqazVORGM1TURNcElqNVViM1JoYkNEdnZJUXpOalU4TDNSbGVIUStQSFJsZUhRZ2VHMXNPbk53WVdObFBTSndjbVZ6WlhKMlpTSWdZMnhoYzNNOUltWnZiM1JsY2lJZ2VEMGlOVEFpSUhrOUlqSTBPUzQyTXpnME15SWdkSEpoYm5ObWIzSnRQU0p6WTJGc1pTZ3hMakF5TnpJM016TXNNQzQ1TnpNME5UQTRNU2tpUGxSb2FYTWdkbTkxWTJobGNpQnBjeUJ1YjNRZ2RtRnNhV1FnWVhNZ1lXNGdhVzUyYjJsalpTNDhMM1JsZUhRK1BDOW5Qanh6ZEhsc1pUNHVjM1puUW05a2VTQjdabTl1ZEMxbVlXMXBiSGs2SUNKSVpXeDJaWFJwWTJFaUlIMHVkR2x1ZVNCN1ptOXVkQzF6ZEhKbGRHTm9PbTV2Y20xaGJEdG1iMjUwTFhOcGVtVTZNQzQwTWpVMk1qUndlRHRzYVc1bExXaGxhV2RvZERveExqSTFPM1JsZUhRdFlXNWphRzl5T21WdVpEdDNhR2wwWlMxemNHRmpaVHB3Y21VN1ptbHNiRG9qWmpsbU9XWTVPMzB1Wm05dmRHVnlJSHRtYjI1MExYTjBjbVYwWTJnNmJtOXliV0ZzTzJadmJuUXRjMmw2WlRvMmNIZzdiR2x1WlMxb1pXbG5hSFE2TGpJMU8zZG9hWFJsTFhOd1lXTmxPbkJ5WlR0bWFXeHNPaU5tT1dZNVpqazdmUzV6YldGc2JDQjdabTl1ZEMxemFYcGxPakF1TkRsd2VEdDBaWGgwTFdGc2FXZHVPbk4wWVhKME8zUmxlSFF0WVc1amFHOXlPbk4wWVhKME8zZG9hWFJsTFhOd1lXTmxPbkJ5WlR0bWFXeHNPaU5tT1dZNVpqazdmUzV0WldScGRXMGdlMlp2Ym5RdGMybDZaVG93TGpjeU9UWTBNbkI0TzJadmJuUXRabUZ0YVd4NU9raGxiSFpsZEdsallUdDBaWGgwTFdGc2FXZHVPbVZ1WkR0MFpYaDBMV0Z1WTJodmNqcGxibVE3ZDJocGRHVXRjM0JoWTJVNmNISmxPMlpwYkd3NkkyWTVaamxtT1R0OVBDOXpkSGxzWlQ0OEwzTjJaejQ9In0="
        );
        /*solhint-enable max-line-length*/
    }
}

contract Vouchers721FailureTester is VouchersTest {

    function testFailTransferDuringFundingState() public {
        metadataService = IMetadataService(address(1));
        address crowdtainerAddress;

        (crowdtainerAddress,) = createCrowdtainer();

        uint256 tokenId = alice.doJoin({
            _crowdtainerAddress: crowdtainerAddress,
            _quantities: [uint256(0), 0, 0, 100],
            _enableReferral: false,
            _referrer: address(0)
        });

        alice.doApprove(address(bob), tokenId);

        try alice.doSafeTransferTo(address(bob), tokenId) {} catch (
            bytes memory lowLevelData
        ) {
            failed = this.assertEqSignature(
                makeError(Errors.TransferNotAllowed.selector),
                lowLevelData
            );
        }

    }
}

contract Vouchers721CreateInvalidTester is VouchersTest {
    function testFailUseInvalidMetadataServiceAddress() public {
        try
            vouchers.createCrowdtainer({
                _campaignData: CampaignData(
                    address(agent),
                    openingTime,
                    closingTime,
                    targetMinimum,
                    targetMaximum,
                    unitPricePerType,
                    referralRate,
                    referralEligibilityValue,
                    iERC20Token
                ),
                _productDescription: ["", "", "", ""],
                _metadataService: address(metadataService)
            })
        {} catch (bytes memory lowLevelData) {
            failed = this.assertEqSignature(
                makeError(Errors.MetadataServiceAddressIsZero.selector),
                lowLevelData
            );
        }
    }
}

/* solhint-enable no-empty-blocks */
