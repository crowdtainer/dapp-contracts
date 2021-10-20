// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;
import "./CrowdtainerTestHelpers.sol";

import "../../Crowdtainer.sol";
import "@openzeppelin/contracts/mocks/ERC20Mock.sol";

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
    // contracts
    Crowdtainer internal crowdtainer;

    // users
    User internal alice;
    User internal bob;

    // Default valid constructor values
    uint256 internal openingTime;
    uint256 internal closingTime;
    uint256 internal minimumSoldUnits = 100;
    uint256 internal maximumSoldUnits = 1000;
    uint256 internal numberOfProductTypes = 3;

    uint256[10] internal unitPricePerType = [10, 20, 30];

    uint256 internal discountRate = 10;
    uint256 internal referralRate = 10;

    // Create a token stub
    uint8 internal numberOfDecimals = 18;
    uint256 internal initialBalance = 30000 * (10**uint256(numberOfDecimals));
    ERC20Mock internal token =
        new ERC20Mock("StableToken", "STK", msg.sender, initialBalance);
    address internal owner = address(this);

    function setUp() public virtual {
        hevm.warp(1634151199); // 13.10.2021
        emit log_named_address("CrowdtainerTest address", owner);

        openingTime = block.timestamp;
        closingTime = block.timestamp + 2 hours;

        crowdtainer = new Crowdtainer(owner);

        alice = new User(address(crowdtainer));
        bob = new User(address(crowdtainer));
    }
}
