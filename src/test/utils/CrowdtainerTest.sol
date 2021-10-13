// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;
import "./CrowdtainerTestHelpers.sol";

import "../../Crowdtainer.sol";
import "./Hevm.sol";

contract User {
    Crowdtainer internal crowdtainer;

    constructor(address _owner) {
        crowdtainer = Crowdtainer(_owner);
    }

    function getPaidAndDeliver() public {
        crowdtainer.getPaidAndDeliver();
    }
}

contract CrowdtainerTest is CrowdtainerTestHelpers {
    Hevm internal constant hevm = Hevm(HEVM_ADDRESS);

    // contracts
    Crowdtainer internal crowdtainer;

    // users
    User internal alice;
    User internal bob;

    function setUp() public virtual {
        uint256 openingTime = block.timestamp;
        uint256 closingTime = block.timestamp + 2 hours;
        uint256 minimumSoldUnits = 100;
        uint256 maximumSoldUnits = 1000;
        uint256 numberOfProductTypes = 3;

        uint256[] memory unitPricePerType = new uint256[](3);
        unitPricePerType[0] = 10;
        unitPricePerType[1] = 20;
        unitPricePerType[2] = 30;

        uint256 discountRate = 10;
        uint256 referralRate = 10;
        address token = address(1); // TODO

        crowdtainer = new Crowdtainer(
            openingTime,
            closingTime,
            minimumSoldUnits,
            maximumSoldUnits,
            numberOfProductTypes,
            unitPricePerType,
            discountRate,
            referralRate,
            IERC20(token)
        );

        alice = new User(address(crowdtainer));
        bob = new User(address(crowdtainer));
    }
}
