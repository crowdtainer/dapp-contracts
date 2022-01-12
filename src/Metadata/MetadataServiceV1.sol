// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

import "./IMetadataService.sol";
import "./SVGRender.sol";

import "../../lib/openzeppelin-contracts/contracts/utils/Strings.sol";

contract MetadataServiceV1 is IMetadataService {
    using Strings for uint256;

    /**
     * @dev Return a DATAURI containing a voucher SVG representation of the given tokenId.
     * @param _metadata Address that represents the product or service provider.
     * @return The voucher image in SVG, in data URI scheme.
     */
    function uri(Metadata memory _metadata)
        external
        pure
        returns (string memory)
    {
        string memory name = string(
            abi.encodePacked(
                "Crowdtainer VoucherID #",
                _metadata.tokenId.toString(),
                " owner:",
                _metadata.owner
            )
        );

        string memory productList;
        uint256 totalCost;
        for (uint256 i = 0; i < _metadata.numberOfProducts; i++) {
            productList = string(
                abi.encodePacked(
                    productList,
                    _metadata.productDescription[i],
                    " x ",
                    _metadata.quantities[i],
                    "\n"
                )
            );
            totalCost +=
                _metadata.unitPricePerType[i] *
                _metadata.quantities[i];
        }

        string memory description = string(
            abi.encodePacked(
                "Items:\n",
                productList,
                "\nTotalCost:",
                totalCost.toString()
            )
        );

        string memory image = Base64.encode(bytes(SVGRender.generateImage()));
        /* solhint-disable quotes */
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name,
                                '", "description":"',
                                description,
                                '", "image": "',
                                "data:image/svg+xml;base64,",
                                image,
                                '"}'
                            )
                        )
                    )
                )
            );
    }
    /* solhint-enable quotes */
}
