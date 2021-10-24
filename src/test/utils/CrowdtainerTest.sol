// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

//import "@openzeppelin/contracts/mocks/ERC20Mock.sol";
import "../external/Coin.sol";

import "./CrowdtainerTestHelpers.sol";
import "../../Crowdtainer.sol";
import "../../Constants.sol";

contract User {
    Crowdtainer internal crowdtainer;
    IERC20 internal token;

    constructor(address _owner, address _token) {
        crowdtainer = Crowdtainer(_owner);
        token = IERC20(_token);
    }

    function doJoin(
        uint256[MAX_NUMBER_OF_PRODUCTS] calldata quantities,
        bytes32 referralCode,
        bytes32 newReferralCode) public
    {
        crowdtainer.join(quantities, referralCode, newReferralCode);
    }

    function getPaidAndDeliver() public {
        crowdtainer.getPaidAndDeliver();
    }

    function doApprove(address _contract, uint256 amount) public
    {
        token.approve(_contract, amount);
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
    uint256 internal targetMinimum = 20000;
    uint256 internal targetMaximum = 26000;

    uint256[MAX_NUMBER_OF_PRODUCTS] internal unitPricePerType = [10, 20, 25];

    uint256 internal discountRate = 10;
    uint256 internal referralRate = 10;

    // Create a token
    uint8 internal numberOfDecimals = 18;
    uint256 internal multiplier = (10**uint256(numberOfDecimals));

    Coin internal coin = new Coin("StableToken", "STK", 1);
    IERC20 internal erc20Token = IERC20(coin);

    address internal owner = address(this);

    function init() internal {
        crowdtainer.initialize(
            openingTime,
            closingTime,
            targetMinimum,
            targetMaximum,
            unitPricePerType,
            referralRate,
            erc20Token
        );
    }

    function setUp() public virtual {
        hevm.warp(1634151199); // 13.10.2021
        emit log_named_address("CrowdtainerTest address", owner);

        openingTime = block.timestamp;
        closingTime = block.timestamp + 2 hours;

        crowdtainer = new Crowdtainer(owner);

        alice = new User(address(crowdtainer), address(erc20Token));
        bob = new User(address(crowdtainer), address(erc20Token));

        // Give lots of tokens to alice
        coin.mint(address(alice), type(uint256).max - 1000);
        // Alice allows Crowdtainer to pull the value
        alice.doApprove(address(crowdtainer), type(uint256).max - 1000);

        // Give 1000 tokens to bob
        coin.mint(address(bob), 1000);
        // Bob allows Crowdtainer to pull the value
        bob.doApprove(address(crowdtainer), 1000);
    }
}
