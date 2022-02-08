// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

uint256 constant _MAX_NUMBER_OF_PRODUCTS = 4;

struct Metadata {
    uint256 crowdtainerId;
    uint256 tokenId;
    address currentOwner;
    bool claimed;
    uint256[_MAX_NUMBER_OF_PRODUCTS] unitPricePerType;
    uint256[_MAX_NUMBER_OF_PRODUCTS] quantities;
    string[_MAX_NUMBER_OF_PRODUCTS] productDescription;
    uint256 numberOfProducts;
}

/**
 * @dev Metadata service used to provide URI for a voucher / token id.
 */
interface IMetadataService {
    function uri(Metadata memory) external view returns (string memory);
}
