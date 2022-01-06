// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

import "../Crowdtainer.sol";
import "../Metadata/IMetadataService.sol";
import "../Metadata/VoucherRender.sol";

import "../../lib/openzeppelin-contracts/contracts/utils/Strings.sol";

contract DataURIMetadataService is IMetadataService {

    using Strings for uint256;

    /**
     * @dev Return a DATAURI containing a voucher SVG representation of the given tokenId.
     * @param _metadata Address that represents the product or service provider.
     * @return The voucher image in SVG, in data URI scheme.
     */
    function uri(Metadata memory _metadata)
    public view returns (string memory) {

        string memory name = string(abi.encodePacked("Crowdtainer VoucherID #", _metadata.tokenId.toString(), " owner:", _metadata.owner));

        Crowdtainer crowdtainer = Crowdtainer(_metadata.crowdtainer);
        string memory productList;
        uint256 totalCost;
        for (uint256 i = 0; i < crowdtainer.numberOfProducts(); i++) {
            productList = string(abi.encodePacked(productList, _metadata.productDescription[i], " x ", _metadata.quantities[i], "\n"));
            totalCost += crowdtainer.unitPricePerType(i) * _metadata.quantities[i];
        }

        address currentOwner = address(0);
        return
            VoucherRender.generateMetadata(
                name,
                string(
                    abi.encodePacked(
                        "(",
                        productList,
                        "/",
                        crowdtainer.expireTime().toString(),
                        "/",
                        crowdtainer.openingTime().toString(),
                        "/",
                        totalCost.toString(),
                        ")"
                    )
                ),
                currentOwner,
                "date",
                "collectionInfo"
            );
    }
}