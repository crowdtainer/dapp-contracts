// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";


import "forge-std/Test.sol";

import "../utils/Vouchers721Test.sol";
import "./VoucherHandler.t.sol";

contract Invariants is Test {

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
        alice,
        bob,
        charlie,
        dave,
        erin,
        frank
    ];

    Vouchers721 vouchers;
    IMetadataService metadataService;

    Crowdtainer defaultCrowdtainer;
    uint256 defaultCrowdtainerId;

    VoucherHandler handler;

    function setUp() public {
        vm.label(signer, "signer");
        vm.label(shippingAgent, "shippingAgent");
        vm.label(alice, "alice");
        vm.label(bob, "bob");
        vm.label(charlie, "charlie");
        vm.label(dave, "dave");
        vm.label(erin, "erin");
        vm.label(frank, "frank");

        address usdcAddress = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        IERC20Metadata token = IERC20Metadata(usdcAddress);

        uint tokenDecimals = token.decimals();

        uint256[] memory unitPricePerType = new uint[](4);
        unitPricePerType[0] = 10 ** tokenDecimals;
        unitPricePerType[1] = 20 ** tokenDecimals;
        unitPricePerType[2] = 25 ** tokenDecimals;
        unitPricePerType[3] = 30 ** tokenDecimals;

        string[] memory productDescription = new string[](4);
        productDescription[0] = "";
        productDescription[1] = "";
        productDescription[2] = "";
        productDescription[3] = "";

        uint256 targetMinimum = 20000 ** tokenDecimals;
        uint256 targetMaximum = 26000 ** tokenDecimals;
        uint256 referralRate = 1000; // 10% in basis points
        uint256 referralEligibilityValue = 50 ** tokenDecimals;

        vouchers = new Vouchers721(address(new Crowdtainer()));

        (address crowdtainerAddress, uint crowdtainerId) = vouchers.createCrowdtainer({
            _campaignData: CampaignData(
                address(shippingAgent),
                address(signer),
                block.timestamp,
                block.timestamp + 2 hours,
                targetMinimum,
                targetMaximum,
                unitPricePerType,
                referralRate,
                referralEligibilityValue,
                address(token),
                ""
            ),
            _productDescription: productDescription,
            _metadataService: address(metadataService)
        });

        defaultCrowdtainerId = crowdtainerId;
        defaultCrowdtainer = Crowdtainer(
            vouchers.crowdtainerForId(crowdtainerId)
        );

        handler = new VoucherHandler(
            participants,
            vouchers,
            defaultCrowdtainer,
            defaultCrowdtainerId
        );
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = VoucherHandler.join.selector;

        targetSelector(FuzzSelector({
            addr: address(handler),
            selectors: selectors
        }));

        targetContract(address(handler));

        // Work around bug https://github.com/foundry-rs/foundry/issues/2963#issuecomment-1403730126
        // It says the issue was fixed but I still faced it sometimes.
        targetSender(address(0x1234));
    }

    // I-1: Crowdtainer active and state.funding must always go together.

    function invariant_totalCashMatchesBalance() external {
        // for (uint i; i < markets.length; ++i ) {
        //     assertEq(
        //         supplyHandler.totalCash(markets[i]),
        //         markets[i].balanceOf(address(ib))
        //     );
        // }
    }
}