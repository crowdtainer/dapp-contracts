// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

// import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";

enum CrowdtainerState {
    Uninitialized,
    Initialized,
    Delivery,
    Failed
}

library Errors {
    // -----------------------------------------------
    //  Initialization with invalid parameters
    // -----------------------------------------------
    // @notice: Cannot initialize with owner of address(0)
    error OwnerAddressIsZero();
    // @notice: Cannot initialize with token of address(0)
    error TokenAddressIsZero();
    // @notice: Initialize called with closing time is less than one hour away from the opening time
    error ClosingTimeTooEarly();
    // @notice: Initialize called with invalid number of maximum units to be sold (0)
    error InvalidMaximumSoldUnits();
    // @notice: Initialize called with invalid number of minimum units to be sold (less than maximum sold units)
    error InvalidMinimumSoldUnits();
    // @notice: Initialize called with invalid number of product types: must be > 0 and smaller than `MAX_NUMBER_OF_PRODUCTS`.
    error InvalidNumberOfProductTypes();
    // @notice: Initialize called with invalid referral rate.
    error InvalidReferralRate(uint256 received, uint256 maximum);

    // -----------------------------------------------
    //  Authorization
    // -----------------------------------------------
    // @notice: Method not authorized for caller (message sender)
    error CallerNotAllowed(address expected, address actual);

    // -----------------------------------------------
    //  State transition
    // -----------------------------------------------
    // @notice: Invalid state transition
    error InvalidStateTransition(CrowdtainerState from, CrowdtainerState to);
    // @notice: Method can't be invoked at current state
    error InvalidOperationFor(CrowdtainerState state);

    // -----------------------------------------------
    //  Other Invariants
    // -----------------------------------------------
    // @notice: Payable receive function called, but we don't accept Eth for payment
    error ContractDoesNotAcceptEther();
}

/**
 * @title Crowdtainer contract
 */
contract Crowdtainer {
    // @dev Only the owner is able to initialize the system.
    address public immutable owner;

    // -----------------------------------------------
    //  Main contract state
    // -----------------------------------------------
    CrowdtainerState public crowdtainerState;

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
    //  Safety margins to avoid impractical values
    // -----------------------------------------------
    uint256 public constant SAFETY_TIME_RANGE = 1 hours;
    // @notice Maximum value for referral discounts and rewards
    uint256 public constant SAFETY_MAX_REFERRAL_RATE = 50;
    // @notice Maximum number of different products.
    uint256 public constant MAX_NUMBER_OF_PRODUCTS = 10;

    // -----------------------------------------------
    //  Values set by initialize function
    // -----------------------------------------------
    // @note Time after which it is possible to join this Crowdtainer.
    uint256 public openingTime;
    // @note Time after which it is no longer possible for the service or product provider to withdraw funds.
    uint256 public expireTime;
    // @note The minimum units of the service or product required for the funding to be successful.
    uint256 public minimumSoldUnits;
    // @note The maximum units of the service or product available.
    uint256 public maximumSoldUnits;
    // @note The price for each unit type.
    // @dev The price should be given in the number of smallest unit for precision (e.g 10^18 == 1 DAI).
    uint256[10] public unitPricePerType;
    // @note Half of the value is given for being referred to by a buyer, and the other half as discount for using a referral code.
    uint256 public referralRate;
    // @note Address of the ERC20 token used for payment.
    IERC20 public token;

    // -----------------------------------------------
    //  Events
    // -----------------------------------------------
    event CrowdtainerCreated(address indexed owner);
    event CrowdtainerInitialized(
        address indexed owner,
        uint256 _openingTime,
        uint256 _expireTime,
        uint256 _minimumSoldUnits,
        uint256 _maximumSoldUnits,
        uint256[10] _unitPricePerType,
        uint256 _referralRate,
        IERC20 _token
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
     * @param _minimumSoldUnits The amount of sales required for funding to be considered to be successful.
     * @param _maximumSoldUnits A limit after which no further purchases are possible.
     * @param _unitPricePerType Array with price of each item, in ERC2O units.
     * @param _referralRate Percentage used for incentivising participation.
     * @param _token Address of the ERC20 token used for payment.
     */
    function initialize(
        uint256 _openingTime,
        uint256 _expireTime,
        uint256 _minimumSoldUnits,
        uint256 _maximumSoldUnits,
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

        if (_maximumSoldUnits == 0) revert Errors.InvalidMaximumSoldUnits();
        require(!(_maximumSoldUnits == 0));

        if (_minimumSoldUnits == 0) revert Errors.InvalidMinimumSoldUnits();
        require(!(_minimumSoldUnits == 0));

        if (_minimumSoldUnits > _maximumSoldUnits)
            revert Errors.InvalidMinimumSoldUnits();
        require(!(_minimumSoldUnits > _maximumSoldUnits));

        if (_referralRate > SAFETY_MAX_REFERRAL_RATE)
            revert Errors.InvalidReferralRate({
                received: _referralRate,
                maximum: SAFETY_MAX_REFERRAL_RATE
            });
        require(!(_referralRate > SAFETY_MAX_REFERRAL_RATE));

        openingTime = _openingTime;
        expireTime = _expireTime;
        minimumSoldUnits = _minimumSoldUnits;
        maximumSoldUnits = _maximumSoldUnits;
        unitPricePerType = _unitPricePerType;
        referralRate = _referralRate;
        token = _token;

        crowdtainerState = CrowdtainerState.Initialized;

        emit CrowdtainerInitialized(
            owner,
            openingTime,
            expireTime,
            minimumSoldUnits,
            maximumSoldUnits,
            unitPricePerType,
            referralRate,
            token
        );
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
        if(crowdtainerState != CrowdtainerState.Uninitialized) {
            assert(expireTime >= (openingTime + SAFETY_TIME_RANGE));
            assert(maximumSoldUnits > 0);
            assert(minimumSoldUnits <= maximumSoldUnits);
            assert(referralRate <= SAFETY_MAX_REFERRAL_RATE);
        }
    }
}
