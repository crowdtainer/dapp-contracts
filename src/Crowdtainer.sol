// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

// @dev External dependencies
import "../lib/openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import "../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

// @dev Internal dependencies
import "./States.sol";
import "./Errors.sol";
import "./Constants.sol";

/**
 * @title Crowdtainer contract
 */
contract Crowdtainer is ReentrancyGuard, Initializable {
    using SafeERC20 for IERC20;

    // -----------------------------------------------
    //  Main project state
    // -----------------------------------------------
    CrowdtainerState public crowdtainerState;

    // @dev Owner of this contract.
    // @notice Has permissions to call: initialize(), join() and leave() functions. These functions are gated so
    // that an owner contract can do special accounting (such as for being EIP1155 compatible).
    // If set to address(0), no restriction is applied.
    address public immutable owner;

    // @dev The entity or person responsible for the delivery of this crowdtainer project.
    // @notice Allowed to call getPaidAndDeliver().
    address private shippingAgent;

    // // @dev Starting token id claimed by this Crowdtainer.
    // uint256 private tokenId;

    // // @dev Equals the number of products or services available to choose from when joining the project.
    // uint256 private numberOfItems;

    // @dev Maps wallets that joined this Crowdtainer to the values they paid to join.
    mapping(address => uint256) private costForWallet;

    // @dev Maps accounts to accumulated referral rewards.
    mapping(address => uint256) public accumulatedRewardsOf;

    // @dev Total rewards claimable for project.
    uint256 public accumulatedRewards;

    // @dev Maps referee to referrer.
    mapping(address => address) public referrerOfReferee;

    // @dev Wether an account has opted into being elibible for referral rewards
    mapping(address => bool) private enableReferral;

    // @dev Maps the total discount for each user.
    mapping(address => uint256) public discountForUser;

    // @dev The total value raised or accumulated by this contract.
    uint256 public totalValue;

    // -----------------------------------------------
    //  Modifiers
    // -----------------------------------------------
    /**
     * @dev Throws if msg.sender != owner, except when owner is address(0), in which case no restriction is applied.
     */
    modifier onlyAddress(address requiredAddress) {
        if (owner == address(0)) {
            _;
            return;
        }
        if (msg.sender != requiredAddress)
            revert Errors.CallerNotAllowed({
                expected: msg.sender,
                actual: requiredAddress
            });
        require(msg.sender == requiredAddress);
        _;
    }

    /**
     * @dev Throws if called in state other than the specified.
     */
    modifier onlyInState(CrowdtainerState requiredState) {
        if (crowdtainerState != requiredState)
            revert Errors.InvalidOperationFor({state: crowdtainerState});
        require(crowdtainerState == requiredState);
        _;
    }

    modifier onlyActive() {
        if (block.timestamp < openingTime)
            revert Errors.OpeningTimeNotReachedYet(
                block.timestamp,
                openingTime
            );
        if (block.timestamp > expireTime)
            revert Errors.CrowdtainerExpired(block.timestamp, expireTime);
        _;
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
    // @note The price for each unit type.
    // @dev The price should be given in the number of smallest unit for precision (e.g 10^18 == 1 DAI).
    uint256[MAX_NUMBER_OF_PRODUCTS] public unitPricePerType;
    // @note Half of the value act as a discount for a new participant using an existing referral code, and the other
    // half is given for the participant making a referral. The former is similar to the 'cash discount device' in stamp era,
    // while the latter is a reward for contributing to the Crowdtainer by incentivising participation from others.
    uint256 public referralRate;
    // @note Address of the ERC20 token used for payment.
    IERC20 public token;

    constructor(address _owner) {
        owner = _owner;
    }

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
        uint256 finalCost // @dev with discount applied
    );

    event Left(address indexed wallet, uint256 withdrawnAmount);

    event PaidRewards(address indexed wallet, uint256 withdrawnAmount);

    event FundsClaimed(address indexed wallet, uint256 withdrawnAmount);

    event CrowdtainerInDeliveryStage();

    // -----------------------------------------------
    // Contract functions
    // -----------------------------------------------

    /**
     * @dev Initializes a Crowdtainer.
     * @param _shippingAgent Address that represents the product or service provider.
     * @param _openingTime Funding opening time.
     * @param _expireTime Time after which the owner can no longer withdraw funds.
     * @param _targetMinimum Amount in ERC20 units required for the Crowdtainer to be considered to be successful.
     * @param _targetMaximum Amount in ERC20 units after which no further participation is possible.
     * @param _unitPricePerType Array with price of each item, in ERC2O units. Zero indicates end of product list.
     * @param _referralRate Percentage used for incentivising participation. Half the amount goes to the referee, and the other half to the referrer.
     * @param _token Address of the ERC20 token used for payment.
     */
    function initialize(
        address _shippingAgent,
        uint256 _openingTime,
        uint256 _expireTime,
        uint256 _targetMinimum,
        uint256 _targetMaximum,
        uint256[MAX_NUMBER_OF_PRODUCTS] memory _unitPricePerType,
        uint256 _referralRate,
        IERC20 _token
    )
        public
        initializer
        onlyAddress(owner)
        onlyInState(CrowdtainerState.Uninitialized)
    {
        // @dev: Sanity checks
        if (address(_token) == address(0)) revert Errors.TokenAddressIsZero();

        shippingAgent = _shippingAgent;

        if (_referralRate % 2 != 0)
            revert Errors.ReferralRateNotMultipleOfTwo();

        // @dev: Expiration time should not be too close to the opening time
        if (_expireTime < _openingTime + SAFETY_TIME_RANGE)
            revert Errors.ClosingTimeTooEarly();

        if (_targetMaximum == 0) revert Errors.InvalidMaximumTarget();

        if (_targetMinimum == 0) revert Errors.InvalidMinimumTarget();

        if (_targetMinimum > _targetMaximum)
            revert Errors.InvalidMinimumTarget();

        // Ensure that there are no prices set to zero and input lengths are correct
        for (uint256 i = 0; i < MAX_NUMBER_OF_PRODUCTS; i++) {
            // @dev The first price of zero indicates the end of price list.
            if (_unitPricePerType[i] == 0)
                break;
        }

        if (_referralRate > SAFETY_MAX_REFERRAL_RATE)
            revert Errors.InvalidReferralRate({
                received: _referralRate,
                maximum: SAFETY_MAX_REFERRAL_RATE
            });

        openingTime = _openingTime;
        expireTime = _expireTime;
        targetMinimum = _targetMinimum;
        targetMaximum = _targetMaximum;
        unitPricePerType = _unitPricePerType;
        referralRate = _referralRate;
        token = _token;

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
     * @param _enableReferral Informs whether the user would like to be elible to collect rewards for being referred.
     * @param _referrer Optional referral code to be used to claim a discount.
     *
     * @note referrer is the wallet address of a previous participant.
     *
     * @note if `enableReferral` is true, and the user decides to leave after the wallet has been used to claim a discount,
     *       then the full value can't be claimed if deciding to leave the project.
     *
     * @note A same user is not allowed to increase the order amounts (i.e., by calling join multiple times).
     *       To 'update' an order, the user must first 'leave' then join again with the new values.
     *
     * @dev State variables manipulated by this function:
     *
     *       accumulatedRewardsOf[referrer]         (+= discount)
     *       discountForUser[msg.sender]            (+= discount)
     *       totalValue                            (+= finalCost)
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
        // @dev Check if wallet didn't already join
        if (costForWallet[_wallet] != 0) revert Errors.UserAlreadyJoined();

        // @dev Calculate cost
        uint256 finalCost;

        for (uint256 i = 0; i < MAX_NUMBER_OF_PRODUCTS; i++) {
            // @dev The first price of zero indicates the end of price list.
            if(unitPricePerType[i] == 0) {
                break;
            }

            if (_quantities[i] > MAX_NUMBER_OF_PURCHASED_ITEMS)
                revert Errors.ExceededNumberOfItemsAllowed({
                    received: _quantities[i],
                    maximum: MAX_NUMBER_OF_PURCHASED_ITEMS
                });

            finalCost += unitPricePerType[i] * _quantities[i];
        }

        // @dev Apply discounts to `finalCost` if applicable.
        bool eligibleForDiscount;
        // @dev Verify validity of given `referrer`
        if (_referrer != address(0)) {
            // @dev Check if referrer participated
            if (costForWallet[_referrer] == 0)
                revert Errors.ReferralInexistent();

            // // @dev Check if account is not referencing itself
            // if (_referrer == _wallet) revert Errors.CannotReferItself();

            if (!enableReferral[_referrer]) revert Errors.ReferralDisabled();

            eligibleForDiscount = true;
        }

        if (eligibleForDiscount) {
            // @dev Two things happens when a valid referral code is given:
            //       1 - Half of the referral rate is applied as a discount to the current order.
            //       2 - Half of the referral rate is credited to the referrer.

            // @dev Calculate the discount value
            uint256 discount = finalCost * ((referralRate / 100) / 2);

            // @dev 1- Apply discount
            finalCost -= discount;
            discountForUser[_wallet] += discount;

            // @dev 2- Apply reward for referrer
            accumulatedRewardsOf[_referrer] += discount;
            accumulatedRewards += discount;

            referrerOfReferee[_wallet] = _referrer;
        }

        costForWallet[_wallet] = finalCost;

        totalValue += finalCost;

        enableReferral[_wallet] = _enableReferral;

        // @dev Check if the purchase order doesn't exceed the goal's `targetMaximum`.
        if ((totalValue - accumulatedRewards) > targetMaximum)
            revert Errors.PurchaseExceedsMaximumTarget({
                received: totalValue,
                maximum: targetMaximum
            });

        // @dev transfer required funds into this contract
        token.safeTransferFrom(_wallet, address(this), finalCost);

        emit Joined(_wallet, _quantities, _referrer, finalCost);
    }

    /*
     * @dev Leave the Crowdtainer and withdraw deposited funds given when joining.
     * @note Calling this method signals that the user is no longer interested in participating.
     * @note Only allowed if the respective Crowdtainer is in active funding state.
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

        // @dev Subtract formerly given referral rewards originating from this account
        address referrer = referrerOfReferee[_wallet];
        accumulatedRewardsOf[referrer] -= discountForUser[_wallet];

        /* @dev   If this wallet's referral was used, then a value equal to the discount is kept.
         *        This is to discourage users from joining just to generate discount codes.
         *        E.g.: A user uses two different wallets, the first joins to generate a discount code for him/herself to be used in
         *        the second wallet, and then immediatelly leaves the pool from the first wallet, leaving the second wallet with a full discount.
         */
        if (accumulatedRewardsOf[_wallet] > 0) {
            withdrawalTotal -= discountForUser[_wallet];
            accumulatedRewards -= discountForUser[_wallet];
        }

        totalValue -= costForWallet[_wallet];
        costForWallet[_wallet] = 0;
        discountForUser[_wallet] = 0;
        referrerOfReferee[_wallet] = address(0);
        enableReferral[_wallet] = false;

        // @dev transfer the owed funds from this contract back to the user.
        token.safeTransferFrom(address(this), _wallet, withdrawalTotal);

        emit Left(_wallet, withdrawalTotal);
    }

    /**
     * @notice Function used by project deployer to signal intent to ship service or product
     * by withdrawing the funds.
     */
    function getPaidAndDeliver()
        public
        onlyAddress(shippingAgent)
        onlyInState(CrowdtainerState.Funding)
        onlyActive
    {
        if (totalValue < targetMinimum) {
            revert Errors.MinimumTargetNotReached(targetMinimum, totalValue);
        }

        crowdtainerState = CrowdtainerState.Delivery;

        // @dev transfer the owed funds from this contract back to the service provider.
        token.safeTransferFrom(address(this), shippingAgent, totalValue);

        emit CrowdtainerInDeliveryStage();
    }

    /**
     * @notice Function used by participants to withdrawl funds from a failed/expired project.
     */
    function claimFunds() public {
        if (crowdtainerState == CrowdtainerState.Uninitialized)
            revert Errors.InvalidOperationFor({state: crowdtainerState});

        if (crowdtainerState == CrowdtainerState.Delivery)
            revert Errors.InvalidOperationFor({state: crowdtainerState});

        // The first person interacting with this function 'nudges' the state to `Failed` if
        // the project didn't reach the goal in time.
        if (block.timestamp > expireTime && totalValue < targetMinimum) {
            crowdtainerState = CrowdtainerState.Failed;
        } else {
            revert Errors.CantClaimFundsOnActiveProject();
        }

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
    function claimRewards() public onlyInState(CrowdtainerState.Delivery) {
        uint256 totalRewards = accumulatedRewardsOf[msg.sender];
        accumulatedRewardsOf[msg.sender] = 0;

        token.safeTransferFrom(address(this), msg.sender, totalRewards);

        emit PaidRewards(msg.sender, totalRewards);
    }

    // @dev This method is only used for Formal Verification with SMTChecker
    // @dev It is executed with `make solcheck` command provided with the project's scripts
    function invariant() public view {
        if (crowdtainerState != CrowdtainerState.Uninitialized) {
            assert(expireTime >= (openingTime + SAFETY_TIME_RANGE));
            assert(targetMaximum > 0);
            assert(targetMinimum <= targetMaximum);
            assert(referralRate <= SAFETY_MAX_REFERRAL_RATE);
        }
    }
}
