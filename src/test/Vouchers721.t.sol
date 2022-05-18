// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

import "./utils/Vouchers721Test.sol";
import {Errors} from "../contracts/Crowdtainer.sol";

import "../contracts/Metadata/MetadataServiceV1.sol";

/* solhint-disable no-empty-blocks */

contract Vouchers721CreateTester is VouchersTest {
    function testCreateCrowdtainerMustSucceed() public {
        metadataService = IMetadataService(address(1));

        uint256 crowdtainerId1;
        address crowdtainerAddress1;
        (crowdtainerAddress1, crowdtainerId1) = createCrowdtainer();

        assert(
            vouchers.crowdtainerForId(crowdtainerId1) == crowdtainerAddress1
        );
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

        (crowdtainerAddress, ) = createCrowdtainer();
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

    function testTokenIdToCrowdtainerIdMustSucceed(uint256 randomTokenId)
        public
    {
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

        neo.doApprovePayment(
            crowdtainerAddress2,
            type(uint256).max - 1000 * ONE
        );

        uint256 neoCrowdtainer2TokenId = neo.doJoin({
            _crowdtainerAddress: crowdtainerAddress2,
            _quantities: [uint256(1), 4, 3, 1],
            _enableReferral: false,
            _referrer: address(0)
        });

        uint256 crowdtainerId3;
        address crowdtainerAddress3;
        (crowdtainerAddress3, crowdtainerId3) = createCrowdtainer();

        georg.doApprovePayment(
            crowdtainerAddress3,
            type(uint256).max - 1000 * ONE
        );

        uint256 georgCrowdtainer3TokenId = georg.doJoin({
            _crowdtainerAddress: crowdtainerAddress3,
            _quantities: [uint256(1), 4, 3, 1],
            _enableReferral: false,
            _referrer: address(0)
        });

        alice.doApprovePayment(
            crowdtainerAddress3,
            type(uint256).max - 1000 * ONE
        );

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

        createCrowdtainer();

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
        try
            alice.doSafeTransferTo(address(11), aliceCrowdtainerTokenId)
        {} catch (
            bytes memory /*lowLevelData*/
        ) {
            failed = false;
        }
    }

    function testShippingAgentAbleToSetVoucherClaimStatus() public {
        metadataService = IMetadataService(address(1));

        createCrowdtainer();

        // Bob purchases enough to make project succeed its target
        uint256 aliceCrowdtainerTokenId = alice.doJoin({
            _crowdtainerAddress: address(defaultCrowdtainer),
            _quantities: [uint256(1), 4, 3, 100],
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
        try
            alice.doJoin({
                _crowdtainerAddress: address(0x111),
                _quantities: [uint256(1), 4, 3, 1],
                _enableReferral: false,
                _referrer: address(0)
            })
        {} catch (bytes memory lowLevelData) {
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

        (crowdtainerAddress, ) = createCrowdtainer();

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
            "data:application/json;base64,eyJjcm93ZHRhaW5lcklkIjoiMSIsICJ2b3VjaGVySWQiOiIxIiwgImN1cnJlbnRPd25lciI6IjB4MHg0Mjk5N2FjOTI1MWU1YmIwYTYxZjRmZjc5MGU1Yjk5MWVhMDdmZDliIiwgImRlc2NyaXB0aW9uIjpbeyJkZXNjcmlwdGlvbiI6IlJvYXN0ZWQgYmVhbnMgMjUwZyIsImFtb3VudCI6IjEiLCJwcmljZVBlclVuaXQiOiIxMDAwMDAwMCJ9LCB7ImRlc2NyaXB0aW9uIjoiUm9hc3RlZCBiZWFucyA1MDBnIiwiYW1vdW50IjoiNCIsInByaWNlUGVyVW5pdCI6IjIwMDAwMDAwIn0sIHsiZGVzY3JpcHRpb24iOiJSb2FzdGVkIGJlYW5zIDFLZyIsImFtb3VudCI6IjMiLCJwcmljZVBlclVuaXQiOiIyNTAwMDAwMCJ9LCB7ImRlc2NyaXB0aW9uIjoiUm9hc3RlZCBiZWFucyAyS2ciLCJhbW91bnQiOiIxIiwicHJpY2VQZXJVbml0IjoiMjAwMDAwMDAwIn1dLCAiVG90YWxDb3N0IjoiMzY1MDAwMDAwIiwgImltYWdlIjogImRhdGE6aW1hZ2Uvc3ZnK3htbDtiYXNlNjQsUEhOMlp5QjNhV1IwYUQwaU1UQXdiVzBpSUdobGFXZG9kRDBpTVRNd2JXMGlJSFpwWlhkQ2IzZzlJakFnTUNBek1EQWdORE13SWlCMlpYSnphVzl1UFNJeExqRWlJR2xrUFNKemRtYzFJaUJqYkdGemN6MGljM1puUW05a2VTSWdlRzFzYm5NOUltaDBkSEE2THk5M2QzY3Vkek11YjNKbkx6SXdNREF2YzNabklqNDhaeUJwWkQwaWJHRjVaWEl4SWo0OGNHRjBhQ0JwWkQwaWNHRjBhRElpSUhOMGVXeGxQU0pqYjJ4dmNqb2pNREF3TURBd08yWnBiR3c2ZFhKc0tDTlRkbWRxYzB4cGJtVmhja2R5WVdScFpXNTBNalUyTVNrN1ptbHNiQzF2Y0dGamFYUjVPakF1T0RrNU1Ua3pPMlpwYkd3dGNuVnNaVHBsZG1WdWIyUmtPM04wY205clpTMTNhV1IwYURveExqVTBOVFF6T3kxcGJtdHpZMkZ3WlMxemRISnZhMlU2Ym05dVpTSWdaRDBpYlRNeUxqSXdNaUF4TWk0MU9IRXRNall1TlRBME55MHVNREl4TmkweU5pNDBORGd4SURJMkxqazRNMnd3SURNMk1TNDNNemcwY1M0d01URTBJREV4TGpnek1TQXhOUzQzTWpZNUlERXhMamM0TURsb056WXVOemszWXkwdU1UWXdPUzB4TGpjME1UZ3RMalkzTXpRdE1URXVOVEk1TVNBNExqRTVNRGd0TVRFdU1EWTNPUzR4TkRVekxqQXdPQzR6T0RFMExqQXhOalV1TlRJM05TNHdNVFkxYURrd0xqZ3dOamhqTGpFME5qRWdNQ0F1TXpnekxTNHdNRFV1TlRJNU1TMHVNREExSURZdU56QXhOaTB1TURBMklEY3VOekE0TXlBNUxqTTFOVFFnTnk0NE16WWdNVEV1TURVMk1TNHdNVEE1TGpFME5UTXVNVE0xTWk0eU5qTTBMakk0TVRNdU1qWXpOR3c0TUM0d09UTXhJREJ4TVRJdU1qZzBPUzR3TWlBeE1pNHlPVFEzTFRFeUxqSTVORGQyTFRNMk1TNDNOalk1Y1MwdU1UQTJPQzB5Tmk0NU5qRTBMVEkyTGpRME9ESXRNall1T1Rnek1tZ3ROall1TWpjNU5HTXVNREF6SURFeUxqWXpNVFV1TURVd05DQTVMalUxTlRrdE5UUXVOekk0SURrdU5UUTJMVFE0TGpNME9DNHdNVEEyTFRVeExqVTROVFFnTWk0eE56WTRMVFV4TGpnd05EUXRPUzQzTlRReWVpSXZQangwWlhoMElIaHRiRHB6Y0dGalpUMGljSEpsYzJWeWRtVWlJR05zWVhOelBTSnRaV1JwZFcwaUlIZzlJakV3TGpRM09ETTFOQ0lnZVQwaU1DSWdhV1E5SW5SbGVIUXhOakk0TUMwMkxUa2lJSFJ5WVc1elptOXliVDBpYldGMGNtbDRLREUyTGpRNU1UWXNNQ3d3TERFMUxqWXlOelUwTnl3M0xqRXpNalV5TVRFc05UUXVOalkwT1RNeUtTSStQSFJ6Y0dGdUlIZzlJakUxTGpRM09ETTFOQ0lnZVQwaU1TSStRM0p2ZDJSMFlXbHVaWElnTVR3dmRITndZVzQrUEM5MFpYaDBQangwWlhoMElIaHRiRHB6Y0dGalpUMGljSEpsYzJWeWRtVWlJR05zWVhOelBTSjBhVzU1SWlCNFBTSXhNQzQwTnpnek5UUWlJSGs5SWpBaUlHbGtQU0owWlhoME1UWXlPREF0TmkwNUxUY2lJSFJ5WVc1elptOXliVDBpYldGMGNtbDRLREUyTGpRNU1UWXNNQ3d3TERFMUxqWXlOelUwTnl3MUxqY3lPREk0T0RRc09UQXVNVFl3TURrNEtTSStQSFJ6Y0dGdUlIZzlJakUxTGpRM09ETTFOQ0lnZVQwaU1TNDFJaUJwWkQwaWRITndZVzR4TVRZeklqNURiR0ZwYldWa09pQk9iend2ZEhOd1lXNCtQQzkwWlhoMFBqeDBaWGgwSUhodGJEcHpjR0ZqWlQwaWNISmxjMlZ5ZG1VaUlHTnNZWE56UFNKdFpXUnBkVzBpSUhnOUlqRXpMalEzT0RNMU5DSWdlVDBpTVRRdU1UWTRPVGswTkNJZ2FXUTlJblJsZUhReE5qSTRNQzAySWlCMGNtRnVjMlp2Y20wOUltMWhkSEpwZUNneE5pNDBPVEUyTERBc01Dd3hOUzQyTWpjMU5EY3NOeTQxT0RrM056SXNOaTQ1T1RRM09UQXpLU0krUEhSemNHRnVJSGc5SWpFMUxqUTNPRE0xTkNJZ2VUMGlOUzQwSWlCcFpEMGlkSE53WVc0eE1UWTFJajVXYjNWamFHVnlJREU4TDNSemNHRnVQand2ZEdWNGRENDhkR1Y0ZENCNGJXdzZjM0JoWTJVOUluQnlaWE5sY25abElpQmpiR0Z6Y3owaWMyMWhiR3dpSUhnOUlqSWlJSGs5SWpFd0lpQjBjbUZ1YzJadmNtMDlJbTFoZEhKcGVDZ3hOaTQwT1RFMkxEQXNNQ3d4TlM0Mk1qYzFORGNzTnk0MU9EazNOeklzTmk0NU9UUTNPVEF6S1NJK01TQWdlQ0FnVW05aGMzUmxaQ0JpWldGdWN5QXlOVEJuSUMwZzc3eUVNVEE4TDNSbGVIUStQSFJsZUhRZ2VHMXNPbk53WVdObFBTSndjbVZ6WlhKMlpTSWdZMnhoYzNNOUluTnRZV3hzSWlCNFBTSXlJaUI1UFNJeE1TSWdkSEpoYm5ObWIzSnRQU0p0WVhSeWFYZ29NVFl1TkRreE5pd3dMREFzTVRVdU5qSTNOVFEzTERjdU5UZzVOemN5TERZdU9UazBOemt3TXlraVBqUWdJSGdnSUZKdllYTjBaV1FnWW1WaGJuTWdOVEF3WnlBdElPKzhoREl3UEM5MFpYaDBQangwWlhoMElIaHRiRHB6Y0dGalpUMGljSEpsYzJWeWRtVWlJR05zWVhOelBTSnpiV0ZzYkNJZ2VEMGlNaUlnZVQwaU1USWlJSFJ5WVc1elptOXliVDBpYldGMGNtbDRLREUyTGpRNU1UWXNNQ3d3TERFMUxqWXlOelUwTnl3M0xqVTRPVGMzTWl3MkxqazVORGM1TURNcElqNHpJQ0I0SUNCU2IyRnpkR1ZrSUdKbFlXNXpJREZMWnlBdElPKzhoREkxUEM5MFpYaDBQangwWlhoMElIaHRiRHB6Y0dGalpUMGljSEpsYzJWeWRtVWlJR05zWVhOelBTSnpiV0ZzYkNJZ2VEMGlNaUlnZVQwaU1UTWlJSFJ5WVc1elptOXliVDBpYldGMGNtbDRLREUyTGpRNU1UWXNNQ3d3TERFMUxqWXlOelUwTnl3M0xqVTRPVGMzTWl3MkxqazVORGM1TURNcElqNHhJQ0I0SUNCU2IyRnpkR1ZrSUdKbFlXNXpJREpMWnlBdElPKzhoREl3TUR3dmRHVjRkRDQ4ZEdWNGRDQjRiV3c2YzNCaFkyVTlJbkJ5WlhObGNuWmxJaUJqYkdGemN6MGljMjFoYkd3aUlIZzlJaklpSUhrOUlqRTJJaUIwY21GdWMyWnZjbTA5SW0xaGRISnBlQ2d4Tmk0ME9URTJMREFzTUN3eE5TNDJNamMxTkRjc055NDFPRGszTnpJc05pNDVPVFEzT1RBektTSStWRzkwWVd3Zzc3eUVNelkxUEM5MFpYaDBQangwWlhoMElIaHRiRHB6Y0dGalpUMGljSEpsYzJWeWRtVWlJR05zWVhOelBTSm1iMjkwWlhJaUlIZzlJamcxSWlCNVBTSXpPREFpSUhSeVlXNXpabTl5YlQwaWMyTmhiR1VvTVM0d01qY3lOek16TERBdU9UY3pORFV3T0RFcElqNVVhR2x6SUhadmRXTm9aWElnYVhNZ2JtOTBJSFpoYkdsa0lHRnpJR0Z1SUdsdWRtOXBZMlV1UEM5MFpYaDBQand2Wno0OGMzUjViR1UrTG5OMlowSnZaSGtnZTJadmJuUXRabUZ0YVd4NU9pQWlTR1ZzZG1WMGFXTmhJaUI5TG5ScGJua2dlMlp2Ym5RdGMzUnlaWFJqYURwdWIzSnRZV3c3Wm05dWRDMXphWHBsT2pBdU5USTFOakkwY0hnN2JHbHVaUzFvWldsbmFIUTZNUzR5TlR0MFpYaDBMV0Z1WTJodmNqcGxibVE3ZDJocGRHVXRjM0JoWTJVNmNISmxPMlpwYkd3NkkyWTVaamxtT1R0OUxtWnZiM1JsY2lCN1ptOXVkQzF6ZEhKbGRHTm9PbTV2Y20xaGJEdG1iMjUwTFhOcGVtVTZOM0I0TzJ4cGJtVXRhR1ZwWjJoME9pNHlOVHQzYUdsMFpTMXpjR0ZqWlRwd2NtVTdabWxzYkRvalpqbG1PV1k1TzMwdWMyMWhiR3dnZTJadmJuUXRjMmw2WlRvd0xqWTFjSGc3ZEdWNGRDMWhiR2xuYmpwemRHRnlkRHQwWlhoMExXRnVZMmh2Y2pwemRHRnlkRHQzYUdsMFpTMXpjR0ZqWlRwd2NtVTdabWxzYkRvalpqbG1PV1k1TzMwdWJXVmthWFZ0SUh0bWIyNTBMWE5wZW1VNk1DNDVNbkI0TzJadmJuUXRabUZ0YVd4NU9raGxiSFpsZEdsallUdDBaWGgwTFdGc2FXZHVPbVZ1WkR0MFpYaDBMV0Z1WTJodmNqcGxibVE3ZDJocGRHVXRjM0JoWTJVNmNISmxPMlpwYkd3NkkyWTVaamxtT1R0OVBDOXpkSGxzWlQ0OGJHbHVaV0Z5UjNKaFpHbGxiblFnZURFOUp6QWxKeUI1TVQwbk16QWxKeUI0TWowbk5qQWxKeUI1TWowbk9UQWxKeUJuY21Ga2FXVnVkRlZ1YVhSelBTZDFjMlZ5VTNCaFkyVlBibFZ6WlNjZ2FXUTlKMU4yWjJwelRHbHVaV0Z5UjNKaFpHbGxiblF5TlRZeEp6NDhjM1J2Y0NCemRHOXdMV052Ykc5eVBTZHlaMkpoS0RBc0lEVXlMQ0F4TVN3Z01URXhLU2NnYjJabWMyVjBQU2N3TGpBeUp6NDhMM04wYjNBK1BITjBiM0FnYzNSdmNDMWpiMnh2Y2owbmNtZGlZU2c1TUN3Z05ETXNJRE13TENBeUtTY2diMlptYzJWMFBTY3hKejQ4TDNOMGIzQStQQzlzYVc1bFlYSkhjbUZrYVdWdWRENDhMM04yWno0PSJ9"
        );
        /*solhint-enable max-line-length*/
    }
}

contract Vouchers721FailureTester is VouchersTest {
    function testFailTransferDuringFundingState() public {
        metadataService = IMetadataService(address(1));
        address crowdtainerAddress;

        (crowdtainerAddress, ) = createCrowdtainer();

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
                    address(iERC20Token)
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
