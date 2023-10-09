// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.21;

import "./Constants.sol";
import "./States.sol";

// Data defining all rules and values of a Crowdtainer instance.
struct CampaignData {
    // Ethereum Address that represents the product or service provider.
    address shippingAgent;
    // Address used for signing authorizations.
    address signer;
    // Funding opening time.
    uint256 openingTime;
    // Time after which the owner can no longer withdraw funds.
    uint256 expireTime;
    // Amount in ERC20 units required for project to be considered to be successful.
    uint256 targetMinimum;
    // Amount in ERC20 units after which no further participation is possible.
    uint256 targetMaximum;
    // Array with price of each item, in ERC2O units. Zero is an invalid value and will throw.
    uint256[] unitPricePerType;
    // Percentage used for incentivising participation. Half the amount goes to the referee, and the other half to the referrer.
    uint256 referralRate;
    // The minimum purchase value required to be eligible to participate in referral rewards.
    uint256 referralEligibilityValue;
    // Address of the ERC20 token used for payment.
    address token;
    // URI string pointing to the legal terms and conditions ruling this project.
    string legalContractURI;
}

/**
 * @dev Interface for Crowdtainer instances.
 */
interface ICrowdtainer {
    /**
     * @dev Initializes a Crowdtainer.
     * @param _campaignData Data defining all rules and values of this Crowdtainer instance.
     */
    function initialize(address owner, CampaignData calldata _campaignData)
        external;

    function crowdtainerState() external view returns (CrowdtainerState);

    function shippingAgent() external view returns (address);

    function numberOfProducts() external view returns (uint256);

    function unitPricePerType(uint256) external view returns (uint256);

    /**
     * @notice Join the Crowdtainer project.
     * @param _wallet The wallet that is joining the Crowdtainer. Must be the msg.sender if Crowdtainer owner is address(0x0).
     * @param _quantities Array with the number of units desired for each product.
     *
     * @dev This method is present to make wallet interactions more friendly, by requiring fewer parameters for projects with referral system disabled.
     * @dev Requires IERC20 permit.
     */
    function join(
        address _wallet,
        uint256[] calldata _quantities
    ) external;

    /**
     * @notice Join the Crowdtainer project with optional referral and discount.
     * @param _wallet The wallet that is joining the Crowdtainer. Must be the msg.sender if Crowdtainer owner is address(0x0).
     * @param _quantities Array with the number of units desired for each product.
     * @param _enableReferral Informs whether the user would like to be eligible to collect rewards for being referred.
     * @param _referrer Optional referral code to be used to claim a discount.
     *
     * @dev Requires IERC20 permit.
     * @dev referrer is the wallet address of a previous participant.
     * @dev if `enableReferral` is true, and the user decides to leave after the wallet has been used to claim a discount,
     *       then the full value can't be claimed if deciding to leave the project.
     * @dev A same user is not allowed to increase the order amounts (i.e., by calling join multiple times).
     *      To 'update' an order, the user must first 'leave' then join again with the new values.
     */
    function join(
        address _wallet,
        uint256[] calldata _quantities,
        bool _enableReferral,
        address _referrer
    ) external;

    /*
     * @dev Leave the Crowdtainer and withdraw deposited funds given when joining.
     * @note Calling this method signals that the user is no longer interested in participating.
     * @note Only allowed if the respective Crowdtainer is in active `Funding` state.
     * @param _wallet The wallet that is leaving the Crowdtainer.
     */
    function leave(address _wallet) external;
}
