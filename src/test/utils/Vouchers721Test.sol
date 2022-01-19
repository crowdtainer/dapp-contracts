// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

import "../external/Coin.sol";

import "./CrowdtainerTestHelpers.sol";
import "../../Vouchers721.sol";
import "../../Constants.sol";

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

    // Comply with IERC721Receiver
    function onERC721Received(
    address, 
    address, 
    uint256, 
    bytes memory
    ) external pure returns(bytes4) {
        return this.onERC721Received.selector;
    } 

    function doJoin(
        uint128 _crowdtainerId,
        uint256[MAX_NUMBER_OF_PRODUCTS] calldata _quantities,
        bool _enableReferral,
        address _referrer
    ) public returns (uint256) {
        return
            vouchers.join(
                _crowdtainerId,
                _quantities,
                _enableReferral,
                _referrer
            );
    }

    function doLeave(uint128 _tokenId) public {
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

    function doSafeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        vouchers.safeTransferFrom(from, to, tokenId);
    }
}

// ShippingAgent represents the creator/responsible for a crowdtainer.
contract VoucherShippingAgent {
    Vouchers721 internal vouchersContract;
    uint128 internal crowdtainerId;

    constructor(address _vouchersContract) {
        vouchersContract = Vouchers721(_vouchersContract);
    }

    function doCreateCrowdtainer(
        CampaignData calldata _campaignData,
        string[MAX_NUMBER_OF_PRODUCTS] memory _productDescription,
        address _metadataService
    ) public returns (uint128) {
        crowdtainerId = vouchersContract.createCrowdtainer(
            _campaignData,
            _productDescription,
            _metadataService
        );
    }

    function doGetPaidAndDeliver() public {
        Crowdtainer(vouchersContract.crowdtainerForId(crowdtainerId))
            .getPaidAndDeliver();
    }

    function doAbortProject() public {
        Crowdtainer(vouchersContract.crowdtainerForId(crowdtainerId))
            .abortProject();
    }
}

contract VouchersTest is CrowdtainerTestHelpers {
    // contracts
    Vouchers721 internal vouchers;
    IMetadataService internal metadataService;

    // shipping agent
    VoucherShippingAgent internal agent;

    // users
    VoucherParticipant internal alice;
    VoucherParticipant internal bob;

    // Default valid constructor values
    uint256 internal openingTime;
    uint256 internal closingTime;
    uint256 internal targetMinimum = 20000;
    uint256 internal targetMaximum = 26000;

    uint256[MAX_NUMBER_OF_PRODUCTS] internal unitPricePerType = [10, 20, 25];

    uint256 internal discountRate = 10;
    uint256 internal referralRate = 10;
    uint256 internal referralEligibilityValue = 50;

    // Create a token
    uint8 internal numberOfDecimals = 18;
    uint256 internal multiplier = (10**uint256(numberOfDecimals));

    Coin internal erc20Token = new Coin("StableToken", "STK", 1);
    IERC20 internal iERC20Token = IERC20(erc20Token);

    address internal owner = address(this);

    function createCrowdtainer(
        string[MAX_NUMBER_OF_PRODUCTS] memory _productDescription
    ) internal returns (uint128) {
        uint128 crowdtainerId = vouchers.createCrowdtainer({
            _campaignData: CampaignData(
                address(agent),
                openingTime,
                closingTime,
                targetMinimum,
                targetMaximum,
                unitPricePerType,
                referralRate,
                referralEligibilityValue,
                iERC20Token
            ),
            _productDescription: _productDescription,
            _metadataService: address(metadataService)
        });

        // Alice allows Crowdtainer to pull the value
        address crowdtainer = vouchers.crowdtainerForId(crowdtainerId);
        alice.doApprovePayment(crowdtainer, type(uint256).max - 1000);

        // Bob allows Crowdtainer to pull the value
        bob.doApprovePayment(crowdtainer, 1000);

        return crowdtainerId;
    }

    function setUp() public virtual {
        hevm.warp(1642429224); // 17.01.2022
        emit log_named_address("CrowdtainerTest address", owner);

        openingTime = block.timestamp;
        closingTime = block.timestamp + 2 hours;

        vouchers = new Vouchers721();

        agent = new VoucherShippingAgent(address(vouchers));

        alice = new VoucherParticipant(address(vouchers), address(erc20Token));
        bob = new VoucherParticipant(address(vouchers), address(erc20Token));

        // Give lots of ERC20 tokens to alice
        erc20Token.mint(address(alice), type(uint256).max - 1000);

        // Give 1000 ERC20 tokens to bob
        erc20Token.mint(address(bob), 1000);
    }
}
