// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import "../utils/CrowdtainerTest.sol";
import "./Handler.t.sol";

contract Invariants {

    address owner = address(64);
    address shippingAgent = address(65);
    address signer = address(66);

    address alice = address(256);
    address bob = address(257);
    address charlie = address(258);
    address dave = address(259);
    address erin = address(260);
    address frank = address(261);

    address[] participants = [
        alice
        bob
        charlie
        dave
        erin
        frank
    ];

    IERC20 token;

    Handler handler;
    Crowdtainer crowdtainer;

    function setUp() public {
        vm.label(address(alice), "alice");
        vm.label(address(bob), "bob");
        vm.label(address(charlie), "charlie");
        vm.label(address(dave), "dave");
        vm.label(address(erin), "erin");
        vm.label(address(frank), "frank");

        uint tokenDecimals = token.decimals();

        address usdcAddress = address(0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48);
        IERC20 token = IERC20(usdcAddress);

        uint256[MAX_NUMBER_OF_PRODUCTS] internal unitPricePerType = [
            10 ** tokenDecimals,
            20 ** tokenDecimals,
            25 ** tokenDecimals,
            30 ** tokenDecimals
        ];

        uint256 internal referralRate = 10;
        uint256 internal referralEligibilityValue = 50;

        crowdtainer = new Crowdtainer();
        crowdtainer.initialize(
            owner,
            CampaignData(
                shippingAgent,
                signer,
                block.timestamp,
                block.timestamp + 2 hours,
                20000 ** tokenDecimals,
                26000 ** tokenDecimals,
                unitPricePerType,
                referralRate,
                referralEligibilityValue,
                address(token),
                ""
            )
        );

        handler = new Handler(
            crowdtainer,
            participants
        );
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = Handler.join.selector;

        targetSelector(FuzzSelector({
            addr: address(handler),
            selectors: selectors
        }));

        targetContract(address(handler));

        // Work around bug https://github.com/foundry-rs/foundry/issues/2963#issuecomment-1403730126
        // It says the issue was fixed but I still faced it sometimes.
        targetSender(address(0x1234));
    }

    function invariant_totalCashMatchesBalance() external {
        // for (uint i; i < markets.length; ++i ) {
        //     assertEq(
        //         supplyHandler.totalCash(markets[i]),
        //         markets[i].balanceOf(address(ib))
        //     );
        // }
    }
}