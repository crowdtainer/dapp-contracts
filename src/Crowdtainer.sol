// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

// @dev External dependencies
import "../lib/openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import "../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

// @dev Internal dependencies
import "./ICrowdtainer.sol";
import "./Errors.sol";
import "./Constants.sol";

/**
 * @title Crowdtainer contract
 */
contract Crowdtainer is ICrowdtainer, ReentrancyGuard, Initializable {
    using SafeERC20 for IERC20;

    // -----------------------------------------------
    //  Main project state
    // -----------------------------------------------
    CrowdtainerState public crowdtainerState;

    // @dev Owner of this contract.
    // @notice Has permissions to call: initialize(), join() and leave() functions. These functions are gated so
    // that an owner contract can do special accounting (such as an EIP1155 compliant contract).
    address public owner;

    // @dev The entity or person responsible for the delivery of this crowdtainer project.
    // @notice Allowed to call getPaidAndDeliver().
    address public shippingAgent;

    // @dev Maps wallets that joined this Crowdtainer to the values they paid to join.
    mapping(address => uint256) private costForWallet;

    // @dev Maps accounts to accumulated referral rewards.
    mapping(address => uint256) public accumulatedRewardsOf;

    // @dev Total rewards claimable for project.
    uint256 public accumulatedRewards;

    // @dev Maps referee to referrer.
    mapping(address => address) public referrerOfReferee;

    uint256 public referralEligibilityValue;

    // @dev Wether an account has opted into being elibible for referral rewards.
    mapping(address => bool) private enableReferral;

    // @dev Maps the total discount for each user.
    mapping(address => uint256) public discountForUser;

    // @dev The total value raised/accumulated by this contract.
    uint256 public totalValueRaised;

    // -----------------------------------------------
    //  Modifiers
    // -----------------------------------------------
    /**
     * @dev Throws if msg.sender != owner, except when owner is address(0), in which case no restriction is applied.
     */
    modifier onlyAddress(address requiredAddress) {
        if (owner == address(0)) {
            // This branch means this contract is being used as a stand-alone contract (e.g., not managed by EIP-1155 owning it)
            // E.g.: A Crowdtainer instance interacted directly by an EOA.
            _;
            return;
        }
        requireAddress(requiredAddress);
        _;
    }

    /**
     * @dev Throws if called in state other than the specified.
     */
    modifier onlyInState(CrowdtainerState requiredState) {
        requireState(requiredState);
        _;
    }

    modifier onlyActive() {
        requireActive();
        _;
    }

    // Auxiliary modifier functions, used to save deployment cost.
    function requireState(CrowdtainerState requiredState) internal view {
        if (crowdtainerState != requiredState)
            revert Errors.InvalidOperationFor({state: crowdtainerState});
        require(crowdtainerState == requiredState);
    }

    function requireAddress(address requiredAddress) internal view {
        if (msg.sender != requiredAddress)
            revert Errors.CallerNotAllowed({
                expected: msg.sender,
                actual: requiredAddress
            });
        require(msg.sender == requiredAddress);
    }

    function requireActive() internal view {
        if (block.timestamp < openingTime)
            revert Errors.OpeningTimeNotReachedYet(
                block.timestamp,
                openingTime
            );
        if (block.timestamp > expireTime)
            revert Errors.CrowdtainerExpired(block.timestamp, expireTime);
    }

    // -----------------------------------------------
    //  Values set by initialize function
    // -----------------------------------------------
    // @note Time after which it is possible to join this Crowdtainer.
    uint256 public openingTime;
    // @note Time after which it is no longer possible for the service or product provider to withdraw funds.
    uint256 public expireTime;
    // @note Minimum amount in ERC20 units required for Crowdtainer to be considered to be successful.
    uint256 public targetMinimum;
    // @note Amount in ERC20 units after which no further participation is possible.
    uint256 public targetMaximum;
    // @note Number of products/services variations offered by this project.
    uint256 public numberOfProducts;
    // @note The price for each unit type.
    // @dev The price should be given in the number of smallest unit for precision (e.g 10^18 == 1 DAI).
    uint256[MAX_NUMBER_OF_PRODUCTS] public unitPricePerType;
    // @note Half of the value act as a discount for a new participant using an existing referral code, and the other
    // half is given for the participant making a referral. The former is similar to the 'cash discount device' in stamp era,
    // while the latter is a reward for contributing to the Crowdtainer by incentivising participation from others.
    uint256 public referralRate;
    // @note Address of the ERC20 token used for payment.
    IERC20 public token;

    // -----------------------------------------------
    //  Events
    // -----------------------------------------------

    // @note Emmited when a Crowdtainer is created.
    event CrowdtainerCreated(
        address indexed owner,
        address indexed shippingAgent
    );

    // @note Emmited when a Crowdtainer is initialized.
    event CrowdtainerInitialized(
        IERC20 indexed _token,
        uint256 _openingTime,
        uint256 _expireTime,
        uint256 _targetMinimum,
        uint256 _targetMaximum,
        uint256[MAX_NUMBER_OF_PRODUCTS] _unitPricePerType,
        uint256 _referralRate
    );

    // @note Emmited when a user joins, signalling participation intent.
    event Joined(
        address indexed wallet,
        uint256[MAX_NUMBER_OF_PRODUCTS] quantities,
        address indexed referrer,
        uint256 finalCost, // @dev with discount applied
        uint256 appliedDiscount,
        bool referralEnabled
    );

    event Left(address indexed wallet, uint256 withdrawnAmount);

    event RewardsClaimed(address indexed wallet, uint256 withdrawnAmount);

    event FundsClaimed(address indexed wallet, uint256 withdrawnAmount);

    event CrowdtainerInDeliveryStage(
        address indexed shippingAgent,
        uint256 totalValueRaised
    );

    // -----------------------------------------------
    // Contract functions
    // -----------------------------------------------

    /**
     * @dev Initializes a Crowdtainer.
     * @param _campaignData Data defining all rules and values of this Crowdtainer instance.
     */
    function initialize(address _owner, CampaignData calldata _campaignData)
        external
        initializer
        onlyInState(CrowdtainerState.Uninitialized)
    {
        owner = _owner;

        // @dev: Sanity checks
        if (address(_campaignData.token) == address(0))
            revert Errors.TokenAddressIsZero();

        if (address(_campaignData.shippingAgent) == address(0))
            revert Errors.ShippingAgentAddressIsZero();

        if (
            _campaignData.referralEligibilityValue > _campaignData.targetMinimum
        )
            revert Errors.ReferralMinimumValueTooHigh({
                received: _campaignData.referralEligibilityValue,
                maximum: _campaignData.targetMinimum
            });

        if (_campaignData.referralRate % 2 != 0)
            revert Errors.ReferralRateNotMultipleOfTwo();

        // @dev: Expiration time should not be too close to the opening time
        if (
            _campaignData.expireTime <
            _campaignData.openingTime + SAFETY_TIME_RANGE
        ) revert Errors.ClosingTimeTooEarly();

        if (_campaignData.targetMaximum == 0)
            revert Errors.InvalidMaximumTarget();

        if (_campaignData.targetMinimum == 0)
            revert Errors.InvalidMinimumTarget();

        if (_campaignData.targetMinimum > _campaignData.targetMaximum)
            revert Errors.MinimumTargetHigherThanMaximum();

        // @dev The first price of zero indicates the end of price list.
        for (uint256 i = 0; i < MAX_NUMBER_OF_PRODUCTS; i++) {
            if (_campaignData.unitPricePerType[i] == 0) {
                break;
            }
            numberOfProducts++;
        }

        if (_campaignData.referralRate > SAFETY_MAX_REFERRAL_RATE)
            revert Errors.InvalidReferralRate({
                received: _campaignData.referralRate,
                maximum: SAFETY_MAX_REFERRAL_RATE
            });

        shippingAgent = _campaignData.shippingAgent;
        openingTime = _campaignData.openingTime;
        expireTime = _campaignData.expireTime;
        targetMinimum = _campaignData.targetMinimum;
        targetMaximum = _campaignData.targetMaximum;
        unitPricePerType = _campaignData.unitPricePerType;
        referralRate = _campaignData.referralRate;
        referralEligibilityValue = _campaignData.referralEligibilityValue;
        token = _campaignData.token;

        crowdtainerState = CrowdtainerState.Funding;

        emit CrowdtainerInitialized(
            token,
            openingTime,
            expireTime,
            targetMinimum,
            targetMaximum,
            unitPricePerType,
            referralRate
        );
    }

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
    )
        external
        onlyAddress(owner)
        onlyInState(CrowdtainerState.Funding)
        onlyActive
        nonReentrant
    {
        enableReferral[_wallet] = _enableReferral;

        // @dev Check if wallet didn't already join
        if (costForWallet[_wallet] != 0) revert Errors.UserAlreadyJoined();

        // @dev Calculate cost
        uint256 finalCost;

        for (uint256 i = 0; i < numberOfProducts; i++) {
            if (_quantities[i] > MAX_NUMBER_OF_PURCHASED_ITEMS)
                revert Errors.ExceededNumberOfItemsAllowed({
                    received: _quantities[i],
                    maximum: MAX_NUMBER_OF_PURCHASED_ITEMS
                });

            finalCost += unitPricePerType[i] * _quantities[i];
        }

        if (_enableReferral && finalCost < referralEligibilityValue)
            revert Errors.MinimumPurchaseValueForReferralNotMet({
                received: finalCost,
                minimum: referralEligibilityValue
            });

        // @dev Apply discounts to `finalCost` if applicable.
        bool eligibleForDiscount;
        // @dev Verify validity of given `referrer`
        if (_referrer != address(0)) {
            // @dev Check if referrer participated
            if (costForWallet[_referrer] == 0) {
                revert Errors.ReferralInexistent();
            }

            if (!enableReferral[_referrer]) {
                revert Errors.ReferralDisabledForProvidedCode();
            }

            eligibleForDiscount = true;
        }

        uint256 discount;

        if (eligibleForDiscount) {
            // @dev Two things happens when a valid referral code is given:
            //    1 - Half of the referral rate is applied as a discount to the current order.
            //    2 - Half of the referral rate is credited to the referrer.

            // @dev Calculate the discount value
            discount = ((finalCost * referralRate) / 100) / 2;

            // @dev 1- Apply discount
            assert(discount < finalCost);
            finalCost -= discount;
            discountForUser[_wallet] += discount;

            // @dev 2- Apply reward for referrer
            accumulatedRewardsOf[_referrer] += discount;
            accumulatedRewards += discount;

            referrerOfReferee[_wallet] = _referrer;

            assert(discount != 0);
        }

        costForWallet[_wallet] = finalCost;

        // increase total value accumulated by this contract
        totalValueRaised += finalCost;

        // @dev Check if the purchase order doesn't exceed the goal's `targetMaximum`.
        if ((totalValueRaised - accumulatedRewards) > targetMaximum)
            revert Errors.PurchaseExceedsMaximumTarget({
                received: totalValueRaised,
                maximum: targetMaximum
            });

        // @dev transfer required funds into this contract
        token.safeTransferFrom(_wallet, address(this), finalCost);

        emit Joined(
            _wallet,
            _quantities,
            _referrer,
            finalCost,
            discount,
            _enableReferral
        );
    }

    /*
     * @dev Leave the Crowdtainer and withdraw deposited funds given when joining.
     * @note Calling this method signals that the user is no longer interested in participating.
     * @note Only allowed if the respective Crowdtainer is in active `Funding` state.
     * @param _wallet The wallet that is leaving the Crowdtainer.
     */
    function leave(address _wallet)
        external
        onlyAddress(owner)
        onlyInState(CrowdtainerState.Funding)
        onlyActive
        nonReentrant
    {
        uint256 withdrawalTotal = costForWallet[_wallet];

        // @dev Subtract formerly given referral rewards originating from this account.
        address referrer = referrerOfReferee[_wallet];
        accumulatedRewardsOf[referrer] -= discountForUser[_wallet];

        /* @dev If this wallet's referral was used, then it is no longer possible to leave().
         *      This is to discourage users from joining just to generate discount codes.
         *      E.g.: A user uses two different wallets, the first joins to generate a discount code for him/herself to be used in
         *      the second wallet, and then immediatelly leaves the pool from the first wallet, leaving the second wallet with a full discount. */
        if (accumulatedRewardsOf[_wallet] > 0) {
            revert Errors.CannotLeaveDueAccumulatedReferralCredits();
        }

        totalValueRaised -= costForWallet[_wallet];
        costForWallet[_wallet] = 0;
        discountForUser[_wallet] = 0;
        referrerOfReferee[_wallet] = address(0);
        enableReferral[_wallet] = false;

        // @dev transfer the owed funds from this contract back to the user.
        token.safeTransferFrom(address(this), _wallet, withdrawalTotal);

        emit Left(_wallet, withdrawalTotal);
    }

    /**
     * @notice Function used by project deployer to signal commitment to ship service or product by withdrawing/receiving the payment.
     */
    function getPaidAndDeliver()
        public
        onlyAddress(shippingAgent)
        onlyInState(CrowdtainerState.Funding)
        nonReentrant
    {
        assert(accumulatedRewards < totalValueRaised);

        uint256 availableForAgent = totalValueRaised - accumulatedRewards;

        if (availableForAgent < targetMinimum) {
            revert Errors.MinimumTargetNotReached(
                targetMinimum,
                totalValueRaised
            );
        }

        crowdtainerState = CrowdtainerState.Delivery;

        // @dev transfer the owed funds from this contract to the service provider.
        token.safeTransferFrom(address(this), shippingAgent, availableForAgent);

        emit CrowdtainerInDeliveryStage(shippingAgent, availableForAgent);
    }

    /**
     * @notice Function used by project deployer to signal that it is no longer possible to the ship service or product.
     *         This puts the project into `Failed` state and participants can withdraw their funds.
     */
    function abortProject()
        public
        onlyAddress(shippingAgent)
        onlyInState(CrowdtainerState.Funding)
        nonReentrant
    {
        crowdtainerState = CrowdtainerState.Failed;
    }

    /**
     * @notice Function used by participants to withdrawl funds from a failed/expired project.
     */
    function claimFunds() public nonReentrant {
        if (block.timestamp < openingTime)
            revert Errors.OpeningTimeNotReachedYet(
                block.timestamp,
                openingTime
            );

        if (crowdtainerState == CrowdtainerState.Uninitialized)
            revert Errors.InvalidOperationFor({state: crowdtainerState});

        if (crowdtainerState == CrowdtainerState.Delivery)
            revert Errors.InvalidOperationFor({state: crowdtainerState});

        assert(accumulatedRewards < totalValueRaised);

        // The first interaction with this function 'nudges' the state to `Failed` if
        // the project didn't reach the goal in time.
        if (
            block.timestamp > expireTime &&
            (totalValueRaised - accumulatedRewards) < targetMinimum
        ) crowdtainerState = CrowdtainerState.Failed;

        if (crowdtainerState != CrowdtainerState.Failed)
            revert Errors.CantClaimFundsOnActiveProject();

        // Reaching this line means the project failed either due expiration or explicit transition from `abortProject()`.
        uint256 withdrawalTotal = costForWallet[msg.sender];

        costForWallet[msg.sender] = 0;
        discountForUser[msg.sender] = 0;
        referrerOfReferee[msg.sender] = address(0);

        // @dev transfer the owed funds from this contract back to the user.
        token.safeTransferFrom(address(this), msg.sender, withdrawalTotal);

        emit FundsClaimed(msg.sender, withdrawalTotal);
    }

    /**
     * @notice Function used by participants to withdrawl referral rewards from a successful project.
     */
    function claimRewards()
        public
        nonReentrant
        onlyInState(CrowdtainerState.Delivery)
    {
        uint256 totalRewards = accumulatedRewardsOf[msg.sender];
        accumulatedRewardsOf[msg.sender] = 0;

        token.safeTransferFrom(address(this), msg.sender, totalRewards);

        emit RewardsClaimed(msg.sender, totalRewards);
    }

    // @dev This method is only used for Formal Verification with SMTChecker.
    // @dev It is executed with `make solcheck` command provided with the project's scripts.
    function invariant() public view {
        if (crowdtainerState != CrowdtainerState.Uninitialized) {
            assert(expireTime >= (openingTime + SAFETY_TIME_RANGE));
            assert(targetMaximum > 0);
            assert(targetMinimum <= targetMaximum);
            assert(referralRate <= SAFETY_MAX_REFERRAL_RATE);
        }
    }
}
