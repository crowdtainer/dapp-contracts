// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

import "./IMetadataService.sol";
import "./SVGRender.sol";

import "../../lib/openzeppelin-contracts/contracts/utils/Strings.sol";

contract MetadataServiceV1 is IMetadataService {
    using Strings for uint256;

    string private unitSymbol;
    string private ticketFootnotes;

    constructor(string memory _unitSymbol, string memory _ticketFootnotes) {
        unitSymbol = _unitSymbol;
        ticketFootnotes = _ticketFootnotes;
    }

    /**
     * @dev Return a DATAURI containing a voucher SVG representation of the given tokenId.
     * @param _metadata Address that represents the product or service provider.
     * @return The voucher image in SVG, in data URI scheme.
     */
    function uri(Metadata memory _metadata)
        external
        view
        returns (string memory)
    {
        string memory crowdtainerId = _metadata.crowdtainerId.toString();

        string memory claimed;
        if (_metadata.claimed) {
            claimed = "Claimed: Yes";
        } else {
            claimed = "Claimed: No";
        }

        /* solhint-disable quotes */

        string memory productList = "[";
        uint256 totalCost;

        for (uint256 i = 0; i < _metadata.numberOfProducts; i++) {
            if (_metadata.quantities[i] == 0) {
                continue;
            }

            productList = string(
                abi.encodePacked(
                    productList,
                    '{"description":"',
                    _metadata.productDescription[i],
                    '","amount":"',
                    _metadata.quantities[i].toString(),
                    '","pricePerUnit":"',
                    _metadata.unitPricePerType[i].toString(),
                    '"}'
                )
            );

            if (i < _metadata.numberOfProducts - 1) {
                productList = string(abi.encodePacked(productList, ", "));
            }
            totalCost +=
                _metadata.unitPricePerType[i] *
                _metadata.quantities[i];
        }

        productList = string(abi.encodePacked(productList, "]"));

        string memory description = string(
            abi.encodePacked(
                productList,
                ', "TotalCost":"',
                totalCost.toString(),
                '"'
            )
        );

        string memory image = Base64.encode(
            bytes(
                SVGRender.generateImage(_metadata, unitSymbol, ticketFootnotes)
            )
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"crowdtainerId":"',
                                crowdtainerId,
                                '", "voucherId":"',
                                _metadata.tokenId.toString(),
                                '", "currentOwner":"0x',
                                toAsciiString(_metadata.currentOwner),
                                '", "description":',
                                description,
                                ', "image": "',
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

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}
