// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

// @dev External dependencies
import "../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "../lib/openzeppelin-contracts/contracts/interfaces/IERC1155.sol";

// @dev Internal dependencies
import "./ERC1155.sol";
import "./States.sol";
import "./Errors.sol";
import "./Constants.sol";

/**
 * @title Crowdtainer contract
 */
contract Crowdtainer is ERC1155, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // @dev Only the owner is able to initialize the system.
    address public immutable owner;

    // -----------------------------------------------
    //  Main contract state
    // -----------------------------------------------
    CrowdtainerState public crowdtainerState;

    // @dev Maps referral codes to its owner.
    mapping(bytes32 => address) public ownerOfReferralCode;
    // @dev Maps account to accumulated referral rewards.
    mapping(address => uint256) public accumulatedRewardsOf;

    // @dev Maps referee to referrer.
    mapping(address => address) public referrerOfReferee;
    // @dev Maps referrer to referee.
    mapping(address => address) public refereeOfReferrer;

    // @dev Maps the total discount for each user.
    mapping(address => uint256) public discountForUser;

    // @dev The total accumulated discounts in new purchases plus referral rewards.
    uint256 public discountAndRewards;

    // @dev The total raised by the contract, minus paybacks due referral (in the specified ERC20 units).
    uint256 public totalRaised;

    string private uri_;

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
    // @note Minimum amount in ERC20 units required for project to be considered to be successful.
    uint256 public targetMinimum;
    // @note Amount in ERC20 units after which no further participation is possible.
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

    // @note Emmited when a Crowdtainer is created.
    event CrowdtainerCreated(address indexed owner);

    // @note Emmited when a Crowdtainer is initialized.
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

    // @note Emmited when a user joins, signalling participation intent.
    event Joined(
        address indexed wallet,
        bytes32 indexed referralCode,
        uint256[MAX_NUMBER_OF_PRODUCTS] quantities,
        bytes32 newReferralCode,
        uint256 discount,
        uint256 finalCost // @dev with discount applied
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
     * @param _unitPricePerType Array with price of each item, in ERC2O units. Zero is an invalid value and will throw.
     * @param _referralRate Percentage used for incentivising participation. Half the amount goes to the referee, and the other half to the referrer.
     * @param _token Address of the ERC20 token used for payment.
     * @param _uri URI used to fetch metadata details. See `IERC1155MetadataURI`.
     */
    function initialize(
        uint256 _openingTime,
        uint256 _expireTime,
        uint256 _targetMinimum,
        uint256 _targetMaximum,
        uint256[MAX_NUMBER_OF_PRODUCTS] memory _unitPricePerType,
        uint256 _referralRate,
        IERC20 _token,
        string memory _uri
    ) public onlyAddress(owner) onlyInState(CrowdtainerState.Uninitialized) {
        // @dev: Sanity checks
        if (address(_token) == address(0)) revert Errors.TokenAddressIsZero();

        if (_referralRate % 2 != 0)
            revert Errors.ReferralRateNotMultipleOfTwo();

        // @dev: Expiration time should not be too close to the opening time
        if (_expireTime < _openingTime + SAFETY_TIME_RANGE)
            revert Errors.ClosingTimeTooEarly();

        if (_targetMaximum == 0) revert Errors.InvalidMaximumTarget();

        if (_targetMinimum == 0) revert Errors.InvalidMinimumTarget();

        if (_targetMinimum > _targetMaximum)
            revert Errors.InvalidMinimumTarget();

        // Ensure that there are no prices set to zero
        for (uint256 i = 0; i < MAX_NUMBER_OF_PRODUCTS; i++) {
            // @dev Check if number of items isn't beyond the allowed.
            if (_unitPricePerType[i] == 0)
                revert Errors.InvalidPriceSpecified();
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

        uri_ = _uri;

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
     *
     * @note A same user is allowed to increase the order amounts (i.e., by calling join multiple times).
     *       However, a second call to join() can't provide yet a new referral code (newReferralCode parameter) if
     *       the previous referral code has already been claimed by another account.
     *
     * @dev State variables manipulated by this function:
     *
     *       ownerOfReferralCode[newReferralCode]   (msg.sender)
     *       balanceOf[msg.sender][i]               (+= quantities[i])
     *       accumulatedRewardsOf[referrer]         (+= discount)
     *       discountAndRewards                     (+= discount * 2)
     *       discountForUser[msg.sender]            (+= discount)
     *       totalRaised                            (+= finalCost)
     */
    function join(
        uint256[MAX_NUMBER_OF_PRODUCTS] calldata quantities,
        bytes32 referralCode,
        bytes32 newReferralCode
    ) external onlyInState(CrowdtainerState.Funding) nonReentrant {
        bool hasDiscount;
        address referrer;

        // @dev Verify validity of given `referralCode`
        if (referralCode != 0x0) {
            // @dev Check if referral code exists
            referrer = ownerOfReferralCode[referralCode];
            if (referrer == address(0)) revert Errors.ReferralCodeInexistent();

            // @dev Check if account is not referencing itself
            if (referrer == msg.sender) revert Errors.CannotReferItself();

            hasDiscount = true;
        }

        // @dev Check validity of new referral code
        if (newReferralCode != 0x0) {
            // @dev A user can only crearte or update for a new referral code if either:
            // - A new referral code for this msg.sender was never requested before, or
            // - TODO:: finish this

            // @dev Check if the new referral code is not already taken
            address ownerOfReferral = ownerOfReferralCode[newReferralCode];
            if (ownerOfReferral == msg.sender) {
                // Can it be updated?
            }
            if (ownerOfReferral != address(0)) {
                revert Errors.ReferralCodeAlreadyUsed();
            }

            // @dev Create new referral code.
            ownerOfReferralCode[newReferralCode] = msg.sender;
        }

        // @dev Calculate final cost with discounts applied, if any.
        uint256 finalCost;

        for (uint256 i = 0; i < MAX_NUMBER_OF_PRODUCTS; i++) {
            // @dev Check if number of items isn't beyond the allowed.
            if (quantities[i] > MAX_NUMBER_OF_PURCHASED_ITEMS)
                revert Errors.ExceededNumberOfItemsAllowed({
                    received: quantities[i],
                    maximum: MAX_NUMBER_OF_PURCHASED_ITEMS
                });

            // @dev params: to, id, amount
            _mint(msg.sender, i, quantities[i]);

            finalCost += unitPricePerType[i] * quantities[i];
        }

        uint256 discount;
        if (hasDiscount) {
            // @dev Two things happens when a valid referral code is given:
            //       1 - Half of the referral rate is applied to the current order.
            //       2 - Half of the referral rate is credited to the referrer.

            // @dev Calculate the discount value
            discount = finalCost * ((referralRate / 100) / 2);

            // @dev 1- Apply discount for referee (msg.sender)
            finalCost -= discount;
            discountForUser[msg.sender] += discount;

            // @dev 2- Apply reward for referrer
            accumulatedRewardsOf[referrer] += discount;

            // Required to undo subtract rewards accounting if referee decides to leave participation
            referrerOfReferee[msg.sender] = referrer;
            refereeOfReferrer[referrer] = msg.sender;

            discountAndRewards += discount * 2;
        }

        totalRaised += finalCost;

        // @dev Check if the purchase order doesn't exceed the goal's `targetMaximum`.
        if (totalRaised > targetMaximum)
            revert Errors.PurchaseExceedsMaximumTarget({
                received: totalRaised,
                maximum: targetMaximum
            });

        // @dev transfer required funds into this contract
        token.safeTransferFrom(msg.sender, address(this), finalCost);

        emit Joined(
            msg.sender,
            referralCode,
            quantities,
            newReferralCode,
            discount,
            finalCost
        );
    }

    /*
     * @dev Leave the pool and withdraw deposited funds given when joining.
     * @note Calling this method signals that the user is no longer interested in participating.
     */
    function leave()
        external
        onlyInState(CrowdtainerState.Funding)
        nonReentrant
    {
        /* @dev  If the user generated a referral code when joining, and it has been used for a discount,
         *       then the discount is kept. This is to discourage users from joining just to generate discount codes without
         *       really being referred to. E.g.: A user uses two different wallets, the first joins to generate a
         *       discount code for him/herself to be used in the second wallet, and then immediatelly leaves the pool
         *       from the first wallet, leaving the second wallet with a full discount.
         *       If the account however did not generate a new referral code, or the code was generatated but not used,
         *       then the full amount can be refunded.
         */

        // Calculate total order amount
        uint256 withdrawTotal;
        for (uint256 i = 0; i < MAX_NUMBER_OF_PRODUCTS; i++) {
            withdrawTotal += balanceOf(msg.sender, i) * unitPricePerType[i];
        }

        // subtract discounts used by referee
        uint256 discount = discountForUser[msg.sender];
        withdrawTotal -= discount;

        // undo rewards to referrer related to msg.sender
        // address referrer = referrerOfReferee[msg.sender];
        // if(referrer != 0)
        //     accumulatedRewardsOf[referrer] -= discount;

        // if the user generated a new referral code and the code has been used,
        // keep a fee proportionally.
    }

    /**
     * @notice Get the metadata uri
     * @return String uri of the metadata service
     */
    function uri(uint256) public view override returns (string memory) {
        return uri_;
    }

    function _mint(
        address to,
        uint256 id,
        uint256 amount
    ) internal override {
        super._mint(to, id, amount);
    }

    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal override {
        super._mintBatch(to, ids, amounts);
    }

    function getPaidAndDeliver(uint256 amount)
        public
        onlyAddress(owner)
        onlyInState(CrowdtainerState.Funding)
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
