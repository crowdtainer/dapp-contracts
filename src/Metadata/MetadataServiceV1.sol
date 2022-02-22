// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

import "./IMetadataService.sol";

import "../../lib/openzeppelin-contracts/contracts/utils/Strings.sol";

import "./Base64.sol";

/* solhint-disable quotes */

library HexStrings {
    bytes16 internal constant ALPHABET = '0123456789abcdef';

    /// @notice Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
    /// @dev Credit to Open Zeppelin under MIT license https://github.com/OpenZeppelin/openzeppelin-contracts/blob/243adff49ce1700e0ecb99fe522fb16cff1d1ddc/contracts/utils/Strings.sol#L55
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = '0';
        buffer[1] = 'x';
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = ALPHABET[value & 0xf];
            value >>= 4;
        }
        require(value == 0, 'Strings: hex length insufficient');
        return string(buffer);
    }

    function toHexStringNoPrefix(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length);
        for (uint256 i = buffer.length; i > 0; i--) {
            buffer[i - 1] = ALPHABET[value & 0xf];
            value >>= 4;
        }
        return string(buffer);
    }
}

contract MetadataServiceV1 is IMetadataService {
    using Strings for uint256;
    using Strings for uint128;
    using Strings for uint24;

    using HexStrings for uint256;

    uint24 internal constant yIncrement = 1;
    uint24 internal constant yStartingPoint = 7;
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

    function generateProductList(Metadata calldata _metadata, string memory _unitSymbol) internal pure returns (string memory productList, uint256 totalCost) {
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
                    '<svg width="90mm" height="130mm" viewBox="0 0 210 300" version="1.1" id="svg5" '
                    'class="svgBody" xmlns="http://www.w3.org/2000/svg">'
                    '<g id="layer1">'
                    '<path id="path2" style="color:#000000;fill:#182037;fill-opacity:0.899193;fill-rule:evenodd;stroke-width:1.54543;-inkscape-stroke:none"'
                    ' d="m 52.098698,28.744619 c -24.080972,0.08726 -26.421348,12.110483 -26.448072,26.983029 -2.62e-4,0.146101 -2.35e-4,0.382998 -2.35e-4,0.529123 '
                    "l 0,361.738419 c 0,0.14612 -0.0033,0.38301 -0.0038,0.52913 -0.03656,10.43881 13.648488,11.65623 15.726948,11.78093 0.145285,0.009 0.381667,"
                    "0.0131 0.527792,0.0131 h 76.797008 c 0.14612,0 0.25,-0.11758 0.23656,-0.26308 -0.16092,-1.74183 -0.67343,-11.52906 8.19084,-11.06787 0.14532,"
                    "0.008 0.38142,0.0165 0.52754,0.0165 h 90.80678 c 0.14612,0 0.38298,-0.005 0.5291,-0.005 6.70155,-0.006 7.70834,9.35542 7.83595,11.05613 0.0109,0.14534"
                    " 0.13518,0.26336 0.2813,0.26336 l 80.09307,0 a 12.294694,12.294694 135 0 0 12.29469,-12.29469 v -361.766899 c 0,-0.146125 2e-5,-0.383041 -1.4e-4,"
                    "-0.529166 -0.0206,-19.207972 -2.33499,-26.927341 -26.4482,-26.983159 -0.14611,-3.38e-4 -0.38301,-3.05e-4 -0.52913,-3.05e-4 h -66.27943 a "
                    "0.24833051,0.24833051 133.18506 0 0 -0.24783,0.264053 c 0.005,0.0753 0.009,0.254795 0.009,0.40092 0.003,12.631469 0.0504,9.55588 -54.72796,9.545988 "
                    "-0.14595,-2.6e-5 -0.38273,-2.7e-5 -0.52885,5e-6 -48.34799,0.0106 -49.84409,2.914724 -51.55903,-9.548747 -0.0199,-0.144585 -0.0352,-0.380285 -0.0344,"
                    '-0.526409 a 0.20573828,0.20573828 25.188555 0 0 -0.26394,-0.124138 l -66.256046,-0.01163 c -0.146125,-2.5e-5 -0.383041,-9.7e-5 -0.529166,4.32e-4 z" '
                    'transform="matrix(0.61736113,0,0,0.61736113,0,-3.166674)"  />'
                    '<path style="fill: grey; " transform="matrix(0.61736113,0,0,0.61736113,30,30.166674)" d="M11.944 17.97 4.58 13.62 11.943 24l7.37-10.38-7.372 '
                    '4.35h.003zM12.056 0 4.69 12.223l7.365 4.354 7.365-4.35L12.056 0z"/>'
                    '<text xml:space="preserve" class="medium" x="10.478354" y="0" id="text16280-6-9" transform="matrix(16.4916,0,0,15.627547,7.1325211,54.664932)">',
                    '<tspan x="10.478354" y="0">Crowdtainer # '
                )
            );
    }

    function getSVGFooter() internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<style>.svgBody {font-family: "Helvetica" }'
                    ".tiny {font-stretch:normal;font-size:0.425624px;line-height:1.25;text-anchor:end;white-space:pre;fill:#f9f9f9;}"
                    ".footer {font-stretch:normal;font-size:6px;line-height:.25;white-space:pre;fill:#f9f9f9;}"
                    ".small {font-size:0.49px;text-align:start;text-anchor:start;white-space:pre;fill:#f9f9f9;}"
                    ".medium {font-size:0.729642px;font-family:Helvetica;text-align:end;text-anchor:end;white-space:pre;fill:#f9f9f9;}</style>"
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
                    'x="1.9551024" y="',
                    totalCostYShift.toString(),
                    '" transform="matrix(16.4916,0,0,15.627547,7.589772,6.9947903)">',
                    "Total ",
                    unicode"＄",
                    totalCost.toString(),
                    "</text>"
                )
            );
    }

    function getSVGClaimedInformation() internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '</tspan></text>'
                    '<text xml:space="preserve" class="tiny" x="10.478354" y="0" id="text16280-6-9-7" '
                    'transform="matrix(16.4916,0,0,15.627547,5.7282884,90.160098)">'
                    '<tspan x="10.478354" y="0" id="tspan1163">Claimed: No</tspan></text>'
                    '<text xml:space="preserve" class="medium" x="13.478354" y="14.1689944" id="text16280-6" '
                    'transform="matrix(16.4916,0,0,15.627547,7.589772,6.9947903)">'
                    '<tspan x="10.478354" y="4.1689944" id="tspan1165">Voucher # '
                )
            );
    }

    function generateImage(Metadata calldata _metadata, string memory _ticketFootnotes)
        internal
        view
        returns (string memory)
    {
        string memory description;
        uint256 totalCost;

        (description, totalCost) = generateProductList(_metadata, unitSymbol);

        return
            string(
                abi.encodePacked(
                    getSVGHeader(),
                    uint128(_metadata.crowdtainerId).toString(),
                    getSVGClaimedInformation(),
                    uint128(_metadata.tokenId).toString(),
                    '</tspan></text>',
                    description,
                    getSVGTotalCost(totalCost, _metadata.numberOfProducts),
                    '<text xml:space="preserve" class="footer" x="50" y="249.63843" transform="scale(1.0272733,0.97345081)">',
                    _ticketFootnotes,
                    '</text></g>',
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

        string memory image = Base64.encode(bytes(generateImage(_metadata, ticketFootnotes)));

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"crowdtainerId":"',
                                uint128(_metadata.crowdtainerId).toString(),
                                '", "voucherId":"',
                                uint128(_metadata.tokenId).toString(),
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

    function addressToString(address _address) internal pure returns (string memory) {
        return HexStrings.toHexString( uint256(uint160(_address)), 20);
    }
}
/* solhint-enable quotes */
