// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import "../../contracts/external/Coin.sol";

import "./CrowdtainerTestHelpers.sol";
import "../../contracts/Vouchers721.sol";
import "../../contracts/Constants.sol";
import "../../contracts/Crowdtainer.sol";

// This file contains the basic setup to test the Vouchers721 contract.

// VoucherParticipant represents a user that joins / interacts with a Crowdtainer
// (created by the ShippingAgent) via the Voucher contract.
contract VoucherParticipant {
    Vouchers721 internal vouchers;
    IERC20 internal token;

    constructor(address _vouchers721, address _token) {
        vouchers = Vouchers721(_vouchers721);
        token = IERC20(_token);
    }

    function doJoinSimple(
        address _crowdtainerAddress,
        uint256[MAX_NUMBER_OF_PRODUCTS] calldata _quantities
    ) public returns (uint256) {
        return vouchers.join(_crowdtainerAddress, _quantities);
    }

    function doJoin(
        address _crowdtainerAddress,
        uint256[MAX_NUMBER_OF_PRODUCTS] calldata _quantities,
        bool _enableReferral,
        address _referrer
    ) public returns (uint256) {
        return
            vouchers.join(
                _crowdtainerAddress,
                _quantities,
                _enableReferral,
                _referrer
            );
    }

    function doJoinWithSignature(
        bytes calldata result, // off-chain signed payload
        bytes calldata extraData // retained by client, passed for verification in this function
    ) public returns (uint256) {
        return vouchers.joinWithSignature(result, extraData);
    }

    // Comply with IERC721Receiver
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function doLeave(uint256 _tokenId) public {
        vouchers.leave(_tokenId);
    }

    function getTokenURI(uint256 _tokenId) public view returns (string memory) {
        return vouchers.tokenURI(_tokenId);
    }

    // ERC20 (payment)
    function doApprovePayment(address _contract, uint256 amount) public {
        token.approve(_contract, amount);
    }

    // ERC721 functions
    function doApprove(address to, uint256 tokenId) public {
        vouchers.approve(to, tokenId);
    }

    function goGetBalanceOf(address owner) public view returns (uint256) {
        return vouchers.balanceOf(owner);
    }

    function doSafeTransferTo(address to, uint256 tokenId) public {
        vouchers.safeTransferFrom(address(this), to, tokenId);
    }
}

// ShippingAgent represents the creator/responsible for a crowdtainer.
contract VoucherShippingAgent {
    Vouchers721 internal vouchersContract;

    constructor(address _vouchersContract) {
        vouchersContract = Vouchers721(_vouchersContract);
    }

    function doGetPaidAndDeliver(uint256 _crowdtainerId) public {
        Crowdtainer(vouchersContract.crowdtainerForId(_crowdtainerId))
            .getPaidAndDeliver();
    }

    function doAbortProject(uint256 _crowdtainerId) public {
        Crowdtainer(vouchersContract.crowdtainerForId(_crowdtainerId))
            .abortProject();
    }

    function doSetClaimStatus(uint256 tokenId, bool value) public {
        vouchersContract.setClaimStatus(tokenId, value);
    }
}

contract VouchersTest is CrowdtainerTestHelpers {
    // contracts
    Vouchers721 internal vouchers;
    IMetadataService internal metadataService;

    // "default" crowdtainer used in tests
    Crowdtainer internal defaultCrowdtainer;
    uint256 internal defaultCrowdtainerId;

    // shipping agent
    VoucherShippingAgent internal agent;

    // users
    VoucherParticipant internal alice;
    VoucherParticipant internal bob;

    // Default valid constructor values
    uint256 internal openingTime;
    uint256 internal closingTime;
    uint256 internal targetMinimum = 20000 * ONE;
    uint256 internal targetMaximum = 26000 * ONE;

    string[MAX_NUMBER_OF_PRODUCTS] internal productDescription = [
        "",
        "",
        "",
        ""
    ];

    uint256[MAX_NUMBER_OF_PRODUCTS] internal unitPricePerType = [
        10 * ONE,
        20 * ONE,
        25 * ONE,
        200 * ONE
    ];

    uint256 internal discountRate = 10;
    uint256 internal referralRate = 10;
    uint256 internal referralEligibilityValue = 50 * ONE;

    // Create a token
    uint8 internal numberOfDecimals = 6;
    Coin internal erc20Token = new Coin("StableToken", "STK", numberOfDecimals);
    IERC20 internal iERC20Token = IERC20(erc20Token);

    address internal owner = address(this);

    function createCrowdtainer(address signer)
        internal
        returns (address, uint256)
    {
        uint256 crowdtainerId;
        address crowdtainerAddress;
        (crowdtainerAddress, crowdtainerId) = vouchers.createCrowdtainer({
            _campaignData: CampaignData(
                address(agent),
                address(signer),
                openingTime,
                closingTime,
                targetMinimum,
                targetMaximum,
                unitPricePerType,
                referralRate,
                referralEligibilityValue,
                address(iERC20Token),
                ""
            ),
            _productDescription: productDescription,
            _metadataService: address(metadataService)
        });

        // Alice allows Crowdtainer to pull the value
        defaultCrowdtainerId = crowdtainerId;
        defaultCrowdtainer = Crowdtainer(
            vouchers.crowdtainerForId(crowdtainerId)
        );
        alice.doApprovePayment(
            address(defaultCrowdtainer),
            type(uint256).max - 1000 * ONE
        );

        // Bob allows Crowdtainer to pull the value
        bob.doApprovePayment(address(defaultCrowdtainer), 100000 * ONE);

        return (crowdtainerAddress, crowdtainerId);
    }

    function setUp() public virtual {
        hevm.warp(1642429224); // 17.01.2022
        emit log_named_address("CrowdtainerTest address", owner);

        openingTime = block.timestamp;
        closingTime = block.timestamp + 2 hours;

        // This is the implementation used by proxy/clone pattern
        Crowdtainer crowdtainer = new Crowdtainer();

        vouchers = new Vouchers721(address(crowdtainer));

        agent = new VoucherShippingAgent(address(vouchers));

        alice = new VoucherParticipant(address(vouchers), address(erc20Token));
        bob = new VoucherParticipant(address(vouchers), address(erc20Token));

        // Note: The labels below can only be enabled if using `forge test` (helpful for debugging)
        vm.label(address(bob), "bob");
        vm.label(address(alice), "alice");
        vm.label(address(agent), "agent");
        vm.label(address(0), "none");
        vm.label(address(erc20Token), "Erc20Token");
        vm.label(address(vouchers), "Vouchers721");

        // Give lots of ERC20 tokens to alice
        erc20Token.mint(address(alice), type(uint256).max - 1000000000 * ONE);

        // Give 1000 ERC20 tokens to bob
        erc20Token.mint(address(bob), 1000000 * ONE);
    }
}
