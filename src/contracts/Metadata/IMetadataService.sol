// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.21;

struct Metadata {
    uint256 crowdtainerId;
    uint256 tokenId;
    address currentOwner;
    bool claimed;
    uint256[] unitPricePerType;
    uint256[] quantities;
    string[] productDescription;
    uint256 numberOfProducts;
}

/**
 * @dev Metadata service used to provide URI for a voucher / token id.
 */
interface IMetadataService {
    function uri(Metadata memory) external view returns (string memory);
}
