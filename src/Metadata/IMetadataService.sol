// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

import "../Constants.sol";

struct Metadata {
    address crowdtainer;
    uint256 tokenId;
    uint256 numberOfProducts;
    string[MAX_NUMBER_OF_PRODUCTS] productDescription;
    uint256[MAX_NUMBER_OF_PRODUCTS] unitPricePerType;
    uint256[MAX_NUMBER_OF_PRODUCTS] quantities;
    address owner;
}

/**
 * @dev Metadata service used to provide URI for a voucher / token id.
 */
interface IMetadataService {
    function uri(Metadata memory) external view returns (string memory);
}
