// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

// @dev External dependencies
import "../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

// @dev Internal dependencies
import "./States.sol";
import "./Errors.sol";
import "./Constants.sol";

/**
 * @title Crowdtainer contract
 */
contract Crowdtainer is ReentrancyGuard {
    // using SafeERC20 for IERC20;

    // @dev Only the owner is able to initialize the system.
    address public immutable owner;

    // -----------------------------------------------
    //  Main contract state
    // -----------------------------------------------
    CrowdtainerState public crowdtainerState;

    // @dev Maps referral codes to its owner.
    mapping(bytes32 => address) public ownerOfReferralCode;
    // @dev Maps account to accumulated referral rewards.
    mapping(address => uint256) public accumulatedRewards;

    // @dev The total number of unique wallets that participated.
    uint256 public numberOfParticipants;

    // @dev The total currency raised, given in the specified ERC20.
    uint256 public amountRaised;

    // -----------------------------------------------
    //  Modifiers
    // -----------------------------------------------
    /**
     * @dev Throws if called by any account other than the specified.
     */
    modifier onlyAddress(address requiredAddress) {
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

    // -----------------------------------------------
    //  Values set by initialize function
    // -----------------------------------------------
    // @note Time after which it is possible to join this Crowdtainer.
    uint256 public openingTime;
    // @note Time after which it is no longer possible for the service or product provider to withdraw funds.
    uint256 public expireTime;
    // @note The minimum units of the service or product required for the funding to be successful.
    uint256 public targetMinimum;
    // @note The maximum units of the service or product available.
    uint256 public targetMaximum;
    // @note The price for each unit type.
    // @dev The price should be given in the number of smallest unit for precision (e.g 10^18 == 1 DAI).
    uint256[MAX_NUMBER_OF_PRODUCTS] public unitPricePerType;
    // @note Half of the value act as a discount for a new participant using an existing referral code, and the other
    // half is given for the participant making a referral. The former is similar to the 'cash discount device' in stamp era,
    // while the latter is a reward for contributing to the project by incentivising participation from others.
    uint256 public referralRate;
    // @note Address of the ERC20 token used for payment.
    IERC20 public token;

    // -----------------------------------------------
    //  Events
    // -----------------------------------------------

    event CrowdtainerCreated(address indexed owner);
    event CrowdtainerInitialized(
        IERC20 indexed _token,
        address indexed owner,
        uint256 _openingTime,
        uint256 _expireTime,
        uint256 _targetMinimum,
        uint256 _targetMaximum,
        uint256[MAX_NUMBER_OF_PRODUCTS] _unitPricePerType,
        uint256 _referralRate
    );
    event CrowdtainerInDeliveryStage();

    // -----------------------------------------------
    // Contract functions
    // -----------------------------------------------

    // @dev The contract is fully initialized outside the constructor so that we can do more extensive hevm symbolic testing.
    // @param _owner Address entitled to initialize the contract. Represents the product or service provider.
    constructor(address _owner) {
        if (_owner == address(0)) revert Errors.OwnerAddressIsZero();
        owner = _owner;
        emit CrowdtainerCreated(owner);
    }

    /**
     * @dev Initializes a Crowdtainer.
     * @param _openingTime Funding opening time.
     * @param _expireTime Time after which the owner can no longer withdraw funds.
     * @param _targetMinimum Amount in ERC20 units required for project to be considered to be successful.
     * @param _targetMaximum Amount in ERC20 units after which no further participation is possible.
     * @param _unitPricePerType Array with price of each item, in ERC2O units.
     * @param _referralRate Percentage used for incentivising participation. Half the amount goes to the referee, and the other half to the referrer.
     * @param _token Address of the ERC20 token used for payment.
     */
    function initialize(
        uint256 _openingTime,
        uint256 _expireTime,
        uint256 _targetMinimum,
        uint256 _targetMaximum,
        uint256[MAX_NUMBER_OF_PRODUCTS] memory _unitPricePerType,
        uint256 _referralRate,
        IERC20 _token
    ) public onlyAddress(owner) onlyInState(CrowdtainerState.Uninitialized) {
        // @dev: Sanity checks
        if (address(_token) == address(0)) revert Errors.TokenAddressIsZero();

        // @dev: revert statements are not filtered by Solidity's SMTChecker, so we add require as well.
        require(!(address(_token) == address(0)));

        // @dev: Expiration time should not be too close to the opening time
        if (_expireTime < _openingTime + SAFETY_TIME_RANGE)
            revert Errors.ClosingTimeTooEarly();

        require(!(_expireTime < _openingTime + SAFETY_TIME_RANGE));

        if (_targetMaximum == 0) revert Errors.InvalidMaximumTarget();

        require(!(_targetMaximum == 0));

        if (_targetMinimum == 0) revert Errors.InvalidMinimumTarget();

        require(!(_targetMinimum == 0));

        if (_targetMinimum > _targetMaximum)
            revert Errors.InvalidMinimumTarget();

        require(!(_targetMinimum > _targetMaximum));

        if (_referralRate > SAFETY_MAX_REFERRAL_RATE)
            revert Errors.InvalidReferralRate({
                received: _referralRate,
                maximum: SAFETY_MAX_REFERRAL_RATE
            });

        require(!(_referralRate > SAFETY_MAX_REFERRAL_RATE));

        openingTime = _openingTime;
        expireTime = _expireTime;
        targetMinimum = _targetMinimum;
        targetMaximum = _targetMaximum;
        unitPricePerType = _unitPricePerType;
        referralRate = _referralRate;
        token = _token;

        crowdtainerState = CrowdtainerState.Initialized;

        emit CrowdtainerInitialized(
            token,
            owner,
            openingTime,
            expireTime,
            targetMinimum,
            targetMaximum,
            unitPricePerType,
            referralRate
        );
    }

    /*
     * @dev Join the pool.
     * @param quantities Array with the number of units desired for each product.
     * @param referralCode Optional referral code to be used to claim a discount.
     * @param newReferralCode Optional identifier to generate a new referral code.
     *
     * @note referralCode and newReferralCode both accept values of 0x0, which means no current or future
     * discounts will be available for the participant joining the pool.
     *
     * @note referralCode and newReferralCode are expected to only contain printable ASCII characters,
     * which means the characters between and including 0x1F .. 0x7E, and be in total up to 32 characters.
     * The frontend can normalize all characters to lower-case before interacting with this contract to
     * avoid user typing mistakes.
     */
    function join(
        uint256[MAX_NUMBER_OF_PRODUCTS] calldata quantities,
        bytes32 referralCode,
        bytes32 newReferralCode
    ) external onlyInState(CrowdtainerState.Initialized) nonReentrant {
        bool hasDiscount;
        address referrer;

        // @dev Verify validity of given `referralCode`
        if (referralCode != 0x0) {
            // @dev Check if referral code exists
            referrer = ownerOfReferralCode[referralCode];
            if (referrer == address(0x0))
                revert Errors.ReferralCodeInexistent();
            require(referrer != address(0x0));

            // @dev Check if account is not referencing itself
            if (referrer == msg.sender) revert Errors.CannotReferItself();
            require(referrer != msg.sender);

            hasDiscount = true;
        }

        // @dev Check validity of referral code
        if (newReferralCode != 0x0) {
            // @dev Check if the new referral code is not already taken by another account
            if (ownerOfReferralCode[newReferralCode] != address(0x0)) {
                revert Errors.ReferralCodeAlreadyUsed();
            }
            require(ownerOfReferralCode[newReferralCode] == address(0x0));
            // @dev Create new referral code.
            ownerOfReferralCode[newReferralCode] = msg.sender;
        }

        // @dev Calculate total cost and apply discounts, if any.
        uint256 totalCost;

        for (uint256 i = 0; i < MAX_NUMBER_OF_PRODUCTS; i++) {
            // @dev Check if number of items isn't beyond the allowed.
            if(quantities[i] > MAX_NUMBER_OF_PURCHASED_ITEMS)
                revert Errors.ExceededNumberOfItemsAllowed({received: quantities[i], maximum: MAX_NUMBER_OF_PURCHASED_ITEMS});
            require(quantities[i] <= MAX_NUMBER_OF_PURCHASED_ITEMS);

            totalCost += unitPricePerType[i] * quantities[i];
        }

        uint256 discount;
        if (hasDiscount) {
            // @dev apply discount for referee (msg.sender)
            discount = totalCost * ((referralRate / 2) / 100);
            totalCost -= discount;

            // @dev update reward for referrer
            accumulatedRewards[referrer] += discount;
        }

        // @dev Check if the purchase doesn't exceed the goal's `targetMaximum`.
        if (totalCost > targetMaximum)
            revert Errors.PurchaseExceedsMaximumTarget();
        require(totalCost < targetMaximum);

        // @dev withdraw required funds into this contract
        //token.safeTransferFrom(msg.sender, address(this), totalCost);
        token.transferFrom(msg.sender, address(this), totalCost);

        numberOfParticipants += 1;
    }

    function getPaidAndDeliver()
        public
        onlyAddress(owner)
        onlyInState(CrowdtainerState.Initialized)
    {
        // TODO: implementation

        crowdtainerState = CrowdtainerState.Delivery;

        emit CrowdtainerInDeliveryStage();
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
