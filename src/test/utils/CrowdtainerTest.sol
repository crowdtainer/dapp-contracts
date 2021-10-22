// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/mocks/ERC20Mock.sol";
import "./CrowdtainerTestHelpers.sol";
import "../../Crowdtainer.sol";
import "../../Constants.sol";

contract User {
    Crowdtainer internal crowdtainer;

    constructor(address _owner) {
        crowdtainer = Crowdtainer(_owner);
    }

    function getPaidAndDeliver() public {
        crowdtainer.getPaidAndDeliver();
    }
}

contract BaseTest is CrowdtainerTestHelpers {
    // contracts
    Crowdtainer internal crowdtainer;

    // users
    User internal alice;
    User internal bob;

    // Default valid constructor values
    uint256 internal openingTime;
    uint256 internal closingTime;
    uint256 internal targetMinimum = 100;
    uint256 internal targetMaximum = 1000;

    uint256[MAX_NUMBER_OF_PRODUCTS] internal unitPricePerType = [10, 20, 25];

    uint256 internal discountRate = 10;
    uint256 internal referralRate = 10;

    // Create a token stub
    uint8 internal numberOfDecimals = 18;
    uint256 internal multiplier = (10**uint256(numberOfDecimals));
    uint256 internal initialBalance = 30000 * multiplier;

    ERC20Mock internal token =
        new ERC20Mock("StableToken", "STK", msg.sender, initialBalance);

    // Give some tokens to alice
    token.transferFrom(msg.sender, alice, 100 * multiplier);

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
