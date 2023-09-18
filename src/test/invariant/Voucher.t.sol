// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import "../utils/Vouchers721Test.sol";
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

    Vouchers721 vouchers;
    IMetadataService metadataService;

    Crowdtainer defaultCrowdtainer;
    uint256 defaultCrowdtainerId;

    Handler handler;

    function setUp() public {
        vm.label(signer, "signer");
        vm.label(shippingAgent, "shippingAgent");
        vm.label(alice, "alice");
        vm.label(bob, "bob");
        vm.label(charlie, "charlie");
        vm.label(dave, "dave");
        vm.label(erin, "erin");
        vm.label(frank, "frank");

        address usdcAddress = address(0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48);
        IERC20 token = IERC20(usdcAddress);

        uint tokenDecimals = token.decimals();

        uint256[MAX_NUMBER_OF_PRODUCTS] unitPricePerType = [
            10 ** tokenDecimals,
            20 ** tokenDecimals,
            25 ** tokenDecimals,
            30 ** tokenDecimals
        ];
        string[MAX_NUMBER_OF_PRODUCTS] productDescription = [
            "",
            "",
            "",
            ""
        ];

        uint256 targetMinimum = 20000 ** tokenDecimals;
        uint256 targetMaximum = 26000 ** tokenDecimals;
        uint256 referralRate = 1000; // 10% in basis points
        uint256 referralEligibilityValue = 50 ** tokenDecimals;

        vouchers = new Vouchers721(address(new Crowdtainer()));

        (address crowdtainerAddress, uint crowdtainerId) = vouchers.createCrowdtainer({
            _campaignData: CampaignData(
                address(shippingAgent),
                address(signer),
                openingTime,
                closingTime,
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

        handler = new Handler(
            vouchers,
            participants
            defaultCrowdtainerId,
            defaultCrowdtainer,
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