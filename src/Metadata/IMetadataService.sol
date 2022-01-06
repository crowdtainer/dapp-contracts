// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

struct Metadata {
        address crowdtainer;
                         uint256 tokenId;
      string[] productDescription;
             uint256[] quantities;
                           address owner;
}

/**
 * @dev Metadata service used to provide URI for a voucher / token id.
 */
 interface IMetadataService {
    function uri(Metadata memory) external view returns (string memory);
}