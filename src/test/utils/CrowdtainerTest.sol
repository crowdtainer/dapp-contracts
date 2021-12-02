// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

//import "@openzeppelin/contracts/mocks/ERC20Mock.sol";
import "../external/Coin.sol";

import "./CrowdtainerTestHelpers.sol";
import "../../Crowdtainer.sol";
import "../../Constants.sol";

contract User {
    Crowdtainer internal crowdtainer;
    IERC20 internal token;

    constructor(address _crowdtainer, address _token) {
        crowdtainer = Crowdtainer(_crowdtainer);
        token = IERC20(_token);
    }

    function doJoin(
        uint256[MAX_NUMBER_OF_PRODUCTS] calldata quantities,
        bool enableReferral,
        address referrer
    ) public {
        crowdtainer.join(address(this), quantities, enableReferral, referrer);
    }

    function getPaidAndDeliver() public {
        crowdtainer.getPaidAndDeliver();
    }

    function doApprove(address _contract, uint256 amount) public {
        token.approve(_contract, amount);
    }
}

contract ShippingAgent {
    Crowdtainer internal crowdtainer;

    constructor(address _crowdtainer) {
        crowdtainer = Crowdtainer(_crowdtainer);
    }

    function getPaidAndDeliver() public {
        crowdtainer.getPaidAndDeliver();
    }
}

contract BaseTest is CrowdtainerTestHelpers {
    // contracts
    Crowdtainer internal crowdtainer;

    // shipping agent
    ShippingAgent internal agent;

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

    Coin internal erc20Token = new Coin("StableToken", "STK", 1);
    IERC20 internal iERC20Token = IERC20(erc20Token);

    address internal owner = address(this);

    function init() internal {
        crowdtainer.initialize(
            address(agent),
            openingTime,
            closingTime,
            targetMinimum,
            targetMaximum,
            unitPricePerType,
            referralRate,
            iERC20Token
        );
    }

    function setUp() public virtual {
        hevm.warp(1634151199); // 13.10.2021
        emit log_named_address("CrowdtainerTest address", owner);

        openingTime = block.timestamp;
        closingTime = block.timestamp + 2 hours;

        crowdtainer = new Crowdtainer(address(0));

        agent = new ShippingAgent(address(crowdtainer));

        alice = new User(address(crowdtainer), address(erc20Token));
        bob = new User(address(crowdtainer), address(erc20Token));

        // Give lots of tokens to alice
        erc20Token.mint(address(alice), type(uint256).max - 1000);
        // Alice allows Crowdtainer to pull the value
        alice.doApprove(address(crowdtainer), type(uint256).max - 1000);

        // Give 1000 tokens to bob
        erc20Token.mint(address(bob), 1000);
        // Bob allows Crowdtainer to pull the value
        bob.doApprove(address(crowdtainer), 1000);
    }
}
