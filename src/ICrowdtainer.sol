// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

import "./Constants.sol";
import "./States.sol";
import "../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";

// Data defining all rules and values of a Crowdtainer instance.
struct CampaignData {
    // Address that represents the product or service provider.
    address shippingAgent;
    // Funding opening time.
    uint256 openingTime;
    // Time after which the owner can no longer withdraw funds.
    uint256 expireTime;
    // Amount in ERC20 units required for project to be considered to be successful.
    uint256 targetMinimum;
    // Amount in ERC20 units after which no further participation is possible.
    uint256 targetMaximum;
    // Array with price of each item, in ERC2O units. Zero is an invalid value and will throw.
    uint256[MAX_NUMBER_OF_PRODUCTS] unitPricePerType;
    // Percentage used for incentivising participation. Half the amount goes to the referee, and the other half to the referrer.
    uint256 referralRate;
    // The minimum purchase value required to be eligible to participate in referral rewards.
    uint256 referralEligibilityValue;
    // Address of the ERC20 token used for payment.
    IERC20 token;
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

    /*
     * @dev Join the Crowdtainer project.
     * @param _wallet The wallet that is joining the Crowdtainer.
     * @param _quantities Array with the number of units desired for each product.
     * @param _enableReferral Informs whether the user would like to be eligible to collect rewards for being referred.
     * @param _referrer Optional referral code to be used to claim a discount.
     *
     * @note referrer is the wallet address of a previous participant.
     *
     * @note if `enableReferral` is true, and the account has been used to claim a discount, then
     *       it is no longer possible to leave() during the funding phase.
     *
     * @note A same user is not allowed to increase the order amounts (i.e., by calling join multiple times).
     *       To 'update' an order, the user must first 'leave' then join again with the new values.
     */
    function join(
        address _wallet,
        uint256[MAX_NUMBER_OF_PRODUCTS] calldata _quantities,
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
