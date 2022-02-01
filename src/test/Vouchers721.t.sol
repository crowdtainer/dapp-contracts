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
        metadataService = IMetadataService(new MetadataServiceV1());

        uint128 crowdtainerId = createCrowdtainer({
            _productDescription: [
                "Coffee 250g",
                "Coffee 500g",
                "Coffee 1Kg",
                "Coffee 2Kg"
            ]
        });

        uint256 tokenID = alice.doJoin({
            _crowdtainerId: crowdtainerId,
            _quantities: [uint256(1), 2, 3, 4],
            _enableReferral: false,
            _referrer: address(0)
        });

        string memory metadata = vouchers.tokenURI(tokenID);
        assertEq(metadata, "blah");
        // assert(vouchers.crowdtainerForId(crowdtainerId) != address(0));
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
