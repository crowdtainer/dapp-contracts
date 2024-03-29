// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import "../../contracts/external/MockERC20.sol";
import "./CrowdtainerTestHelpers.sol";
import "../../contracts/Crowdtainer.sol";
import "../../contracts/Constants.sol";

uint256 constant ONE = 1e6; // 6 decimal places

// Participant represents a user that joins / interacts directly with a Crowdtainer (created by the ShippingAgent)
contract Participant {
    Crowdtainer internal crowdtainer;
    IERC20 internal token;

    constructor(address _crowdtainer, address _token) {
        crowdtainer = Crowdtainer(_crowdtainer);
        token = IERC20(_token);
    }

    function doJoinSimple(uint256[] calldata quantities)
        public
    {
        crowdtainer.join(address(this), quantities);
    }

    function doJoin(
        uint256[] calldata quantities,
        bool enableReferral,
        address referrer
    ) public {
        crowdtainer.join(address(this), quantities, enableReferral, referrer);
    }

    function doJoinWithSignature(
        bytes calldata result, // off-chain signed payload
        bytes calldata extraData // retained by client, passed for verification in this function
    ) public {
        crowdtainer.joinWithSignature(result, extraData);
    }

    function doLeave() public {
        crowdtainer.leave(address(this));
    }

    // Method `doGetPaidAndDeliver()` not possible by participant (only used for testing)
    function doGetPaidAndDeliver() public {
        crowdtainer.getPaidAndDeliver();
    }

    function doClaimFunds() public {
        crowdtainer.claimFunds();
    }

    function doClaimRewards() public {
        crowdtainer.claimRewards();
    }

    // ERC20 (payment)
    function doApprovePayment(address _contract, uint256 amount) public {
        token.approve(_contract, amount);
    }
}

// ShippingAgent represents the creator/responsible for a crowdtainer.
contract ShippingAgent {
    Crowdtainer internal crowdtainer;

    constructor(address _crowdtainer) {
        crowdtainer = Crowdtainer(_crowdtainer);
    }

    function doGetPaidAndDeliver() public {
        crowdtainer.getPaidAndDeliver();
    }

    function doAbortProject() public {
        crowdtainer.abortProject();
    }

    // Only for testing, function not allowed for shippingAgent
    function doJoin(
        uint256[] calldata quantities,
        bool enableReferral,
        address referrer
    ) public {
        crowdtainer.join(address(this), quantities, enableReferral, referrer);
    }
}

contract CrowdtainerTest is CrowdtainerTestHelpers {
    // contracts
    Crowdtainer internal crowdtainer;

    // shipping agent
    ShippingAgent internal agent;

    // users
    Participant internal alice;
    Participant internal bob;

    // Default valid constructor values
    uint256 internal openingTime;
    uint256 internal closingTime;
    uint256 internal targetMinimum = 20000 * ONE;
    uint256 internal targetMaximum = 26000 * ONE;

    uint256[] internal unitPricePerType = [
        10 * ONE,
        20 * ONE,
        25 * ONE,
        30 * ONE
    ];

    uint256 internal referralRate = 10;
    uint256 internal referralEligibilityValue = 50;

    // Create a token
    uint8 internal numberOfDecimals = 6;
    MockERC20 internal erc20Token = new MockERC20("StableToken", "STK", numberOfDecimals);
    IERC20 internal iERC20Token = IERC20(address(erc20Token));

    address internal owner = address(this);

    function init() internal {
        crowdtainer.initialize(
            address(0),
            CampaignData(
                address(agent),
                address(0),
                openingTime,
                closingTime,
                targetMinimum,
                targetMaximum,
                unitPricePerType,
                referralRate,
                referralEligibilityValue,
                address(iERC20Token),
                ""
            )
        );
    }

    function initWithSignature(address signer) internal {
        crowdtainer.initialize(
            address(0),
            CampaignData(
                address(agent),
                signer,
                openingTime,
                closingTime,
                targetMinimum,
                targetMaximum,
                unitPricePerType,
                referralRate,
                referralEligibilityValue,
                address(iERC20Token),
                ""
            )
        );
    }

    function setUp() public virtual {
        hevm.warp(1634151199); // 13.10.2021
        emit log_named_address("CrowdtainerTest address", owner);

        openingTime = block.timestamp;
        closingTime = block.timestamp + 2 hours;

        crowdtainer = new Crowdtainer();

        agent = new ShippingAgent(address(crowdtainer));

        alice = new Participant(address(crowdtainer), address(erc20Token));
        bob = new Participant(address(crowdtainer), address(erc20Token));

        // Note: The labels below can only be enabled if using `forge test` (helpful for debugging)
        vm.label(address(bob), "bob");
        vm.label(address(alice), "alice");
        vm.label(address(0), "none");

        // Give lots of tokens to alice
        uint256 tokenAmount = type(uint256).max - 1000 * ONE;
        erc20Token.mint(address(alice), tokenAmount);
        emit log_named_uint("Minted for Alice: ", tokenAmount);
        // Alice allows Crowdtainer to pull the value
        alice.doApprovePayment(
            address(crowdtainer),
            tokenAmount
        );

        // Give 1000 tokens to bob
        tokenAmount = 1000 * ONE;
        erc20Token.mint(address(bob), tokenAmount);
        emit log_named_uint("Minted for Bob: ", tokenAmount);
        // Bob allows Crowdtainer to pull the value
        bob.doApprovePayment(address(crowdtainer), tokenAmount);
    }
}
