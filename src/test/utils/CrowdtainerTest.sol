// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;
import "./CrowdtainerTestHelpers.sol";

import "../../Crowdtainer.sol";
import "./Hevm.sol";

contract User {
    Crowdtainer internal crowdtainer;

    constructor(address _deployer) {
        crowdtainer = Crowdtainer(_deployer);
    }

    function dummyFunction(string memory message) public {
        crowdtainer.dummyFunction(message);
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
        crowdtainer = new Crowdtainer();

        alice = new User(address(crowdtainer));
        bob = new User(address(crowdtainer));
    }
}
