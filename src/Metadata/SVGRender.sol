// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./Base64.sol";

// import "../../lib/openzeppelin-contracts/contracts/utils/Strings.sol";

library SVGRender {
    // using Strings for uint160;

    /*address crowdtainer, uint256 tokenId, string[] memory productDescription, uint256[] memory quantities, address owner*/
    function generateImage() internal pure returns (string memory) {
        /* solhint-disable quotes */
        return
            string(
                abi.encodePacked(
                    '<svg class="svgBody" width="350" height="350" viewBox="0 0 350 350" xmlns="http://www.w3.org/2000/svg">',
                    '<text x="215" y="80" class="small">Crowdtainer</text>',
                    '<text x="15" y="80" class="medium">Voucher</text>',
                    '<text x="15" y="100" class="medium">ID #242</text>',
                    '<text x="15" y="120" class="medium">Owner:</text>',
                    '<text x="15" y="140" style="font-size:12px">0x2345523474abacsadf2423</text>',
                    '<text x="15" y="160" class="medium">Contract Address:</text>',
                    '<text x="15" y="180" style="font-size:12px">0x22234415ddadd2</text>',
                    '<text x="15" y="215" class="medium">Product list:</text>',
                    '<text x="15" y="240" class="small">1x Item 1 - 10 usd</text>',
                    '<text x="15" y="260" class="small">2x Item 2 - 20 usd</text>',
                    '<text x="15" y="280" class="small">1x Item 3 - 60 usd</text>',
                    '<style>.svgBody {font-family: "Courier New" } .tiny {font-size:6px; } .small {font-size: 12px;}.medium {font-size: 18px;}</style>',
                    "</svg>"
                )
            );
        /* solhint-enable quotes */
    }
}
