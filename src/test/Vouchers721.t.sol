// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

import "./utils/Vouchers721Test.sol";
import {Errors} from "../Crowdtainer.sol";

import "../Metadata/MetadataServiceV1.sol";

/* solhint-disable no-empty-blocks */

contract Vouchers721CreateTester is VouchersTest {
    function testCreateCrowdtainerMustSucceed() public {
        metadataService = IMetadataService(address(1));

        uint128 crowdtainerId = createCrowdtainer({
            _productDescription: ["", "", "", ""]
        });

        assert(vouchers.crowdtainerForId(crowdtainerId) != address(0));
    }

    function testTokenURIOfExistingTokenIdMustSucceed() public {
        metadataService = IMetadataService(
            new MetadataServiceV1({
                _unitSymbol: unicode"＄",
                _ticketFootnotes: "This voucher is not valid as an invoice."
            })
        );
        uint128 crowdtainerId = createCrowdtainer({
            _productDescription: [
                "Roasted beans 250g",
                "Roasted beans 500g",
                "Roasted beans 1Kg",
                "Roasted beans 2Kg"
            ]
        });
        uint256 tokenID = alice.doJoin({
            _crowdtainerId: crowdtainerId,
            _quantities: [uint256(1), 4, 3, 1],
            _enableReferral: false,
            _referrer: address(0)
        });
        string memory metadata = vouchers.tokenURI(tokenID);
        /*solhint-disable max-line-length*/
        assertEq(
            metadata,
            "data:application/json;base64,eyJjcm93ZHRhaW5lcklkIjoiMSIsICJ2b3VjaGVySWQiOiIxIiwgImN1cnJlbnRPd25lciI6IjB4MHg0Mjk5N2FjOTI1MWU1YmIwYTYxZjRmZjc5MGU1Yjk5MWVhMDdmZDliIiwgImRlc2NyaXB0aW9uIjpbeyJkZXNjcmlwdGlvbiI6IlJvYXN0ZWQgYmVhbnMgMjUwZyIsImFtb3VudCI6IjEiLCJwcmljZVBlclVuaXQiOiIxMCJ9LCB7ImRlc2NyaXB0aW9uIjoiUm9hc3RlZCBiZWFucyA1MDBnIiwiYW1vdW50IjoiNCIsInByaWNlUGVyVW5pdCI6IjIwIn0sIHsiZGVzY3JpcHRpb24iOiJSb2FzdGVkIGJlYW5zIDFLZyIsImFtb3VudCI6IjMiLCJwcmljZVBlclVuaXQiOiIyNSJ9LCB7ImRlc2NyaXB0aW9uIjoiUm9hc3RlZCBiZWFucyAyS2ciLCJhbW91bnQiOiIxIiwicHJpY2VQZXJVbml0IjoiNDAifV0sICJUb3RhbENvc3QiOiIyMDUiLCAiaW1hZ2UiOiAiZGF0YTppbWFnZS9zdmcreG1sO2Jhc2U2NCxQSE4yWnlCM2FXUjBhRDBpT1RCdGJTSWdhR1ZwWjJoMFBTSXhNekJ0YlNJZ2RtbGxkMEp2ZUQwaU1DQXdJREl4TUNBek1EQWlJSFpsY25OcGIyNDlJakV1TVNJZ2FXUTlJbk4yWnpVaUlHTnNZWE56UFNKemRtZENiMlI1SWlCNGJXeHVjejBpYUhSMGNEb3ZMM2QzZHk1M015NXZjbWN2TWpBd01DOXpkbWNpUGp4bklHbGtQU0pzWVhsbGNqRWlQanh3WVhSb0lHbGtQU0p3WVhSb01pSWdjM1I1YkdVOUltTnZiRzl5T2lNd01EQXdNREE3Wm1sc2JEb2pNVGd5TURNM08yWnBiR3d0YjNCaFkybDBlVG93TGpnNU9URTVNenRtYVd4c0xYSjFiR1U2WlhabGJtOWtaRHR6ZEhKdmEyVXRkMmxrZEdnNk1TNDFORFUwTXpzdGFXNXJjMk5oY0dVdGMzUnliMnRsT201dmJtVWlJR1E5SW0wZ05USXVNRGs0TmprNExESTRMamMwTkRZeE9TQmpJQzB5TkM0d09EQTVOeklzTUM0d09EY3lOaUF0TWpZdU5ESXhNelE0TERFeUxqRXhNRFE0TXlBdE1qWXVORFE0TURjeUxESTJMams0TXpBeU9TQXRNaTQyTW1VdE5Dd3dMakUwTmpFd01TQXRNaTR6TldVdE5Dd3dMak00TWprNU9DQXRNaTR6TldVdE5Dd3dMalV5T1RFeU15QnNJREFzTXpZeExqY3pPRFF4T1NCaklEQXNNQzR4TkRZeE1pQXRNQzR3TURNekxEQXVNemd6TURFZ0xUQXVNREF6T0N3d0xqVXlPVEV6SUMwd0xqQXpOalUyTERFd0xqUXpPRGd4SURFekxqWTBPRFE0T0N3eE1TNDJOVFl5TXlBeE5TNDNNalk1TkRnc01URXVOemd3T1RNZ01DNHhORFV5T0RVc01DNHdNRGtnTUM0ek9ERTJOamNzTUM0d01UTXhJREF1TlRJM056a3lMREF1TURFek1TQm9JRGMyTGpjNU56QXdPQ0JqSURBdU1UUTJNVElzTUNBd0xqSTFMQzB3TGpFeE56VTRJREF1TWpNMk5UWXNMVEF1TWpZek1EZ2dMVEF1TVRZd09USXNMVEV1TnpReE9ETWdMVEF1Tmpjek5ETXNMVEV4TGpVeU9UQTJJRGd1TVRrd09EUXNMVEV4TGpBMk56ZzNJREF1TVRRMU16SXNNQzR3TURnZ01DNHpPREUwTWl3d0xqQXhOalVnTUM0MU1qYzFOQ3d3TGpBeE5qVWdhQ0E1TUM0NE1EWTNPQ0JqSURBdU1UUTJNVElzTUNBd0xqTTRNams0TEMwd0xqQXdOU0F3TGpVeU9URXNMVEF1TURBMUlEWXVOekF4TlRVc0xUQXVNREEySURjdU56QTRNelFzT1M0ek5UVTBNaUEzTGpnek5UazFMREV4TGpBMU5qRXpJREF1TURFd09Td3dMakUwTlRNMElEQXVNVE0xTVRnc01DNHlOak16TmlBd0xqSTRNVE1zTUM0eU5qTXpOaUJzSURnd0xqQTVNekEzTERBZ1lTQXhNaTR5T1RRMk9UUXNNVEl1TWprME5qazBJREV6TlNBd0lEQWdNVEl1TWprME5qa3NMVEV5TGpJNU5EWTVJSFlnTFRNMk1TNDNOalk0T1RrZ1l5QXdMQzB3TGpFME5qRXlOU0F5WlMwMUxDMHdMak00TXpBME1TQXRNUzQwWlMwMExDMHdMalV5T1RFMk5pQXRNQzR3TWpBMkxDMHhPUzR5TURjNU56SWdMVEl1TXpNME9Ua3NMVEkyTGpreU56TTBNU0F0TWpZdU5EUTRNaXd0TWpZdU9UZ3pNVFU1SUMwd0xqRTBOakV4TEMwekxqTTRaUzAwSUMwd0xqTTRNekF4TEMwekxqQTFaUzAwSUMwd0xqVXlPVEV6TEMwekxqQTFaUzAwSUdnZ0xUWTJMakkzT1RReklHRWdNQzR5TkRnek16QTFNU3d3TGpJME9ETXpNRFV4SURFek15NHhPRFV3TmlBd0lEQWdMVEF1TWpRM09ETXNNQzR5TmpRd05UTWdZeUF3TGpBd05Td3dMakEzTlRNZ01DNHdNRGtzTUM0eU5UUTNPVFVnTUM0d01Ea3NNQzQwTURBNU1pQXdMakF3TXl3eE1pNDJNekUwTmprZ01DNHdOVEEwTERrdU5UVTFPRGdnTFRVMExqY3lOemsyTERrdU5UUTFPVGc0SUMwd0xqRTBOVGsxTEMweUxqWmxMVFVnTFRBdU16Z3lOek1zTFRJdU4yVXROU0F0TUM0MU1qZzROU3cxWlMwMklDMDBPQzR6TkRjNU9Td3dMakF4TURZZ0xUUTVMamcwTkRBNUxESXVPVEUwTnpJMElDMDFNUzQxTlRrd015d3RPUzQxTkRnM05EY2dMVEF1TURFNU9Td3RNQzR4TkRRMU9EVWdMVEF1TURNMU1pd3RNQzR6T0RBeU9EVWdMVEF1TURNME5Dd3RNQzQxTWpZME1Ea2dZU0F3TGpJd05UY3pPREk0TERBdU1qQTFOek00TWpnZ01qVXVNVGc0TlRVMUlEQWdNQ0F0TUM0eU5qTTVOQ3d0TUM0eE1qUXhNemdnYkNBdE5qWXVNalUyTURRMkxDMHdMakF4TVRZeklHTWdMVEF1TVRRMk1USTFMQzB5TGpWbExUVWdMVEF1TXpnek1EUXhMQzA1TGpkbExUVWdMVEF1TlRJNU1UWTJMRFF1TXpKbExUUWdlaUlnZEhKaGJuTm1iM0p0UFNKdFlYUnlhWGdvTUM0Mk1UY3pOakV4TXl3d0xEQXNNQzQyTVRjek5qRXhNeXd3TEMwekxqRTJOalkzTkNraUlDQXZQanh3WVhSb0lITjBlV3hsUFNKbWFXeHNPaUJuY21WNU95QWlJSFJ5WVc1elptOXliVDBpYldGMGNtbDRLREF1TmpFM016WXhNVE1zTUN3d0xEQXVOakUzTXpZeE1UTXNNekFzTXpBdU1UWTJOamMwS1NJZ1pEMGlUVEV4TGprME5DQXhOeTQ1TnlBMExqVTRJREV6TGpZeUlERXhMamswTXlBeU5HdzNMak0zTFRFd0xqTTRMVGN1TXpjeUlEUXVNelZvTGpBd00zcE5NVEl1TURVMklEQWdOQzQyT1NBeE1pNHlNak5zTnk0ek5qVWdOQzR6TlRRZ055NHpOalV0TkM0ek5Vd3hNaTR3TlRZZ01Ib2lMejQ4ZEdWNGRDQjRiV3c2YzNCaFkyVTlJbkJ5WlhObGNuWmxJaUJqYkdGemN6MGliV1ZrYVhWdElpQjRQU0l4TUM0ME56Z3pOVFFpSUhrOUlqQWlJR2xrUFNKMFpYaDBNVFl5T0RBdE5pMDVJaUIwY21GdWMyWnZjbTA5SW0xaGRISnBlQ2d4Tmk0ME9URTJMREFzTUN3eE5TNDJNamMxTkRjc055NHhNekkxTWpFeExEVTBMalkyTkRrek1pa2lQangwYzNCaGJpQjRQU0l4TUM0ME56Z3pOVFFpSUhrOUlqQWlQa055YjNka2RHRnBibVZ5SUNNZ01Ud3ZkSE53WVc0K1BDOTBaWGgwUGp4MFpYaDBJSGh0YkRwemNHRmpaVDBpY0hKbGMyVnlkbVVpSUdOc1lYTnpQU0owYVc1NUlpQjRQU0l4TUM0ME56Z3pOVFFpSUhrOUlqQWlJR2xrUFNKMFpYaDBNVFl5T0RBdE5pMDVMVGNpSUhSeVlXNXpabTl5YlQwaWJXRjBjbWw0S0RFMkxqUTVNVFlzTUN3d0xERTFMall5TnpVME55dzFMamN5T0RJNE9EUXNPVEF1TVRZd01EazRLU0krUEhSemNHRnVJSGc5SWpFd0xqUTNPRE0xTkNJZ2VUMGlNQ0lnYVdROUluUnpjR0Z1TVRFMk15SStRMnhoYVcxbFpEb2dUbTg4TDNSemNHRnVQand2ZEdWNGRENDhkR1Y0ZENCNGJXdzZjM0JoWTJVOUluQnlaWE5sY25abElpQmpiR0Z6Y3owaWJXVmthWFZ0SWlCNFBTSXhNeTQwTnpnek5UUWlJSGs5SWpFMExqRTJPRGs1TkRRaUlHbGtQU0owWlhoME1UWXlPREF0TmlJZ2RISmhibk5tYjNKdFBTSnRZWFJ5YVhnb01UWXVORGt4Tml3d0xEQXNNVFV1TmpJM05UUTNMRGN1TlRnNU56Y3lMRFl1T1RrME56a3dNeWtpUGp4MGMzQmhiaUI0UFNJeE1DNDBOemd6TlRRaUlIazlJalF1TVRZNE9UazBOQ0lnYVdROUluUnpjR0Z1TVRFMk5TSStWbTkxWTJobGNpQWpJREU4TDNSemNHRnVQand2ZEdWNGRENDhkR1Y0ZENCNGJXdzZjM0JoWTJVOUluQnlaWE5sY25abElpQmpiR0Z6Y3owaWMyMWhiR3dpSUhnOUlqSWlJSGs5SWpjaUlIUnlZVzV6Wm05eWJUMGliV0YwY21sNEtERTJMalE1TVRZc01Dd3dMREUxTGpZeU56VTBOeXczTGpVNE9UYzNNaXcyTGprNU5EYzVNRE1wSWo0eElDQjRJQ0JTYjJGemRHVmtJR0psWVc1eklESTFNR2NnTFNEdnZJUXhNRHd2ZEdWNGRENDhkR1Y0ZENCNGJXdzZjM0JoWTJVOUluQnlaWE5sY25abElpQmpiR0Z6Y3owaWMyMWhiR3dpSUhnOUlqSWlJSGs5SWpnaUlIUnlZVzV6Wm05eWJUMGliV0YwY21sNEtERTJMalE1TVRZc01Dd3dMREUxTGpZeU56VTBOeXczTGpVNE9UYzNNaXcyTGprNU5EYzVNRE1wSWo0MElDQjRJQ0JTYjJGemRHVmtJR0psWVc1eklEVXdNR2NnTFNEdnZJUXlNRHd2ZEdWNGRENDhkR1Y0ZENCNGJXdzZjM0JoWTJVOUluQnlaWE5sY25abElpQmpiR0Z6Y3owaWMyMWhiR3dpSUhnOUlqSWlJSGs5SWpraUlIUnlZVzV6Wm05eWJUMGliV0YwY21sNEtERTJMalE1TVRZc01Dd3dMREUxTGpZeU56VTBOeXczTGpVNE9UYzNNaXcyTGprNU5EYzVNRE1wSWo0eklDQjRJQ0JTYjJGemRHVmtJR0psWVc1eklERkxaeUF0SU8rOGhESTFQQzkwWlhoMFBqeDBaWGgwSUhodGJEcHpjR0ZqWlQwaWNISmxjMlZ5ZG1VaUlHTnNZWE56UFNKemJXRnNiQ0lnZUQwaU1pSWdlVDBpTVRBaUlIUnlZVzV6Wm05eWJUMGliV0YwY21sNEtERTJMalE1TVRZc01Dd3dMREUxTGpZeU56VTBOeXczTGpVNE9UYzNNaXcyTGprNU5EYzVNRE1wSWo0eElDQjRJQ0JTYjJGemRHVmtJR0psWVc1eklESkxaeUF0SU8rOGhEUXdQQzkwWlhoMFBqeDBaWGgwSUhodGJEcHpjR0ZqWlQwaWNISmxjMlZ5ZG1VaUlHTnNZWE56UFNKemJXRnNiQ0lnZUQwaU1TNDVOVFV4TURJMElpQjVQU0l4TXlJZ2RISmhibk5tYjNKdFBTSnRZWFJ5YVhnb01UWXVORGt4Tml3d0xEQXNNVFV1TmpJM05UUTNMRGN1TlRnNU56Y3lMRFl1T1RrME56a3dNeWtpUGxSdmRHRnNJTys4aERJd05Ud3ZkR1Y0ZEQ0OGRHVjRkQ0I0Yld3NmMzQmhZMlU5SW5CeVpYTmxjblpsSWlCamJHRnpjejBpWm05dmRHVnlJaUI0UFNJMU1DSWdlVDBpTWpRNUxqWXpPRFF6SWlCMGNtRnVjMlp2Y20wOUluTmpZV3hsS0RFdU1ESTNNamN6TXl3d0xqazNNelExTURneEtTSStWR2hwY3lCMmIzVmphR1Z5SUdseklHNXZkQ0IyWVd4cFpDQmhjeUJoYmlCcGJuWnZhV05sTGp3dmRHVjRkRDQ4TDJjK1BITjBlV3hsUGk1emRtZENiMlI1SUh0bWIyNTBMV1poYldsc2VUb2dJa2hsYkhabGRHbGpZU0lnZlM1MGFXNTVJSHRtYjI1MExYTjBjbVYwWTJnNmJtOXliV0ZzTzJadmJuUXRjMmw2WlRvd0xqUXlOVFl5TkhCNE8yeHBibVV0YUdWcFoyaDBPakV1TWpVN2RHVjRkQzFoYm1Ob2IzSTZaVzVrTzNkb2FYUmxMWE53WVdObE9uQnlaVHRtYVd4c09pTm1PV1k1WmprN2ZTNW1iMjkwWlhJZ2UyWnZiblF0YzNSeVpYUmphRHB1YjNKdFlXdzdabTl1ZEMxemFYcGxPalp3ZUR0c2FXNWxMV2hsYVdkb2REb3VNalU3ZDJocGRHVXRjM0JoWTJVNmNISmxPMlpwYkd3NkkyWTVaamxtT1R0OUxuTnRZV3hzSUh0bWIyNTBMWE5wZW1VNk1DNDBPWEI0TzNSbGVIUXRZV3hwWjI0NmMzUmhjblE3ZEdWNGRDMWhibU5vYjNJNmMzUmhjblE3ZDJocGRHVXRjM0JoWTJVNmNISmxPMlpwYkd3NkkyWTVaamxtT1R0OUxtMWxaR2wxYlNCN1ptOXVkQzF6YVhwbE9qQXVOekk1TmpReWNIZzdabTl1ZEMxbVlXMXBiSGs2U0dWc2RtVjBhV05oTzNSbGVIUXRZV3hwWjI0NlpXNWtPM1JsZUhRdFlXNWphRzl5T21WdVpEdDNhR2wwWlMxemNHRmpaVHB3Y21VN1ptbHNiRG9qWmpsbU9XWTVPMzA4TDNOMGVXeGxQand2YzNablBnPT0ifQ=="
        );
        /*solhint-enable max-line-length*/
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
