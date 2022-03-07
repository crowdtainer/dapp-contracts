// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

import "./IMetadataService.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

/* solhint-disable quotes */

contract MetadataServiceV1 is IMetadataService {
    using Strings for uint256;
    using Strings for uint24;

    uint24 internal constant yIncrement = 1;
    uint24 internal constant yStartingPoint = 10;
    uint24 internal constant anchorX = 2;

    string private unitSymbol;
    string private ticketFootnotes;

    function generateSVGProductDescription(
        uint256 quantities,
        uint256 price,
        string memory _unitSymbol,
        string memory description
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    quantities.toString(),
                    "  x  ",
                    description,
                    " - ",
                    _unitSymbol,
                    price.toString()
                )
            );
    }

    function generateProductList(
        Metadata calldata _metadata,
        string memory _unitSymbol
    ) internal pure returns (string memory productList, uint256 totalCost) {
        uint256 newY = yStartingPoint;

        for (uint24 i = 0; i < _metadata.numberOfProducts; i++) {
            if (_metadata.quantities[i] == 0) {
                continue;
            }

            productList = string(
                abi.encodePacked(
                    productList,
                    '<text xml:space="preserve" class="small" x="',
                    anchorX.toString(),
                    '" y="',
                    newY.toString(),
                    '" transform="matrix(16.4916,0,0,15.627547,7.589772,6.9947903)">',
                    generateSVGProductDescription(
                        _metadata.quantities[i],
                        _metadata.unitPricePerType[i],
                        _unitSymbol,
                        _metadata.productDescription[i]
                    ),
                    "</text>"
                )
            );

            if (i < _metadata.numberOfProducts) {
                newY += yIncrement;
            }

            totalCost +=
                _metadata.unitPricePerType[i] *
                _metadata.quantities[i];
        }

        return (productList, totalCost);
    }

    function getSVGHeader() internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<svg width="100mm" height="130mm" viewBox="0 0 300 430" version="1.1" id="svg5" '
                    'class="svgBody" xmlns="http://www.w3.org/2000/svg">'
                    '<g id="layer1">'
                    '<path id="path2" style="color:#000000;fill:url(#SvgjsLinearGradient2561);fill-opacity:0.899193;fill-rule:evenodd;stroke-width:1.54543;-inkscape-stroke:none" '
                    'd="m32.202 12.58q-26.5047-.0216-26.4481 26.983l0 361.7384q.0114 11.831 15.7269 11.7809h76.797c-.1609-1.7418-.6734-11.5291 '
                    '8.1908-11.0679.1453.008.3814.0165.5275.0165h90.8068c.1461 0 .383-.005.5291-.005 6.7016-.006 7.7083 9.3554 '
                    '7.836 11.0561.0109.1453.1352.2634.2813.2634l80.0931 0q12.2849.02 12.2947-12.2947v-361.7669q-.1068-26.9614-26.4482-26.9832h-66.2794c.003 '
                    '12.6315.0504 9.5559-54.728 9.546-48.348.0106-51.5854 2.1768-51.8044-9.7542z"/>'
                    '<text xml:space="preserve" class="medium" x="10.478354" y="0" id="text16280-6-9" transform="matrix(16.4916,0,0,15.627547,7.1325211,54.664932)">',
                    '<tspan x="15.478354" y="1">Crowdtainer '
                )
            );
    }

    function getSVGFooter() internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<style>.svgBody {font-family: "Helvetica" }'
                    '.tiny {font-stretch:normal;font-size:0.525624px;line-height:1.25;text-anchor:end;white-space:pre;fill:#f9f9f9;}'
                    '.footer {font-stretch:normal;font-size:7px;line-height:.25;white-space:pre;fill:#f9f9f9;}'
                    '.small {font-size:0.65px;text-align:start;text-anchor:start;white-space:pre;fill:#f9f9f9;}'
                    '.medium {font-size:0.92px;'
                    'font-family:Helvetica;text-align:end;text-anchor:end;white-space:pre;'
                    'fill:#f9f9f9;}</style>'
                    "<linearGradient x1='0%' y1='30%' x2='60%' y2='90%' gradientUnits='userSpaceOnUse' id='SvgjsLinearGradient2561'>"
                    "<stop stop-color='rgba(0, 52, 11, 111)' offset='0.02'></stop>"
                    "<stop stop-color='rgba(90, 43, 30, 2)' offset='1'></stop></linearGradient>"
                    "</svg>"
                )
            );
    }

    function getSVGTotalCost(uint256 totalCost, uint256 numberOfProuducts)
        internal
        pure
        returns (string memory)
    {
        uint256 totalCostYShift = yStartingPoint +
            yIncrement *
            numberOfProuducts +
            anchorX; // constant just to give a bit of extra spacing

        return
            string(
                abi.encodePacked(
                    '<text xml:space="preserve" class="small" ',
                    'x="2" y="',
                    totalCostYShift.toString(),
                    '" transform="matrix(16.4916,0,0,15.627547,7.589772,6.9947903)">',
                    "Total ",
                    unicode"＄",
                    totalCost.toString(),
                    "</text>"
                )
            );
    }

    function getSVGClaimedInformation(bool claimedStatus) internal pure returns (string memory) {
        string memory part1 = '<text xml:space="preserve" class="tiny" x="10.478354" y="0" id="text16280-6-9-7" '
                    'transform="matrix(16.4916,0,0,15.627547,5.7282884,90.160098)"><tspan x="15.478354" '
                    'y="1.5" id="tspan1163">Claimed: ';
        string memory part2 = '</tspan></text><text xml:space="preserve" class="medium" '
                    'x="13.478354" y="14.1689944" id="text16280-6" transform="matrix(16.4916,0,0,15.627547,7.589772,6.9947903)">'
                    '<tspan x="15.478354" y="5.4" id="tspan1165">Voucher ';
        if(claimedStatus) {
            return string(abi.encodePacked(part1, 'Yes', part2));
        }
        else {
            return string(abi.encodePacked(part1, 'No', part2));
        }
    }

    function generateImage(
        Metadata calldata _metadata,
        string memory _ticketFootnotes
    ) internal view returns (string memory) {
        string memory description;
        uint256 totalCost;

        (description, totalCost) = generateProductList(_metadata, unitSymbol);

        return
            string(
                abi.encodePacked(
                    getSVGHeader(),
                    _metadata.crowdtainerId.toString(),
                    "</tspan></text>",
                    getSVGClaimedInformation(_metadata.claimed),
                    _metadata.tokenId.toString(),
                    "</tspan></text>",
                    description,
                    getSVGTotalCost(totalCost, _metadata.numberOfProducts),
                    '<text xml:space="preserve" class="footer" x="85" y="380" transform="scale(1.0272733,0.97345081)">',
                    _ticketFootnotes,
                    "</text></g>",
                    getSVGFooter()
                )
            );
    }

    constructor(string memory _unitSymbol, string memory _ticketFootnotes) {
        unitSymbol = _unitSymbol;
        ticketFootnotes = _ticketFootnotes;
    }

    /**
     * @dev Return a DATAURI containing a voucher SVG representation of the given tokenId.
     * @param _metadata Address that represents the product or service provider.
     * @return The voucher image in SVG, in data URI scheme.
     */
    function uri(Metadata calldata _metadata)
        external
        view
        returns (string memory)
    {
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
            bytes(generateImage(_metadata, ticketFootnotes))
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"crowdtainerId":"',
                                _metadata.crowdtainerId.toString(),
                                '", "voucherId":"',
                                _metadata.tokenId.toString(),
                                '", "currentOwner":"0x',
                                addressToString(_metadata.currentOwner),
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

    function addressToString(address _address)
        internal
        pure
        returns (string memory)
    {
        return Strings.toHexString(uint256(uint160(_address)), 20);
    }
}
/* solhint-enable quotes */
