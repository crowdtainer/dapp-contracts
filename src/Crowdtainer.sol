// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

enum CrowdtainerState {
    Uninitialized,
    Initialized,
    Delivery
}

library Errors {
    // --- Constructor errors ---

    // @notice: Payable receive function called, but we don't accept Eth for payment
    error ContractDoesNotAcceptEther();
    // @notice: The function invoked does not exist in this contract
    error FunctionNotFound();
    // @notice: Constructor invoked with owner unset: address(0)
    error OwnerAddressIsZero();
    // @notice: Cannot initialize with token of address(0)
    error TokenAddressIsZero();
    // @notice: Method invoked with unexpected message sender
    error CallerNotAllowed(address expected, address actual);
    // @notice: Initialize called with opening time in the past (timestamp < now)
    error OpeningTimeInThePast();
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
    // @notice: Invalid state transition attempted.
    error InvalidStateTransition(CrowdtainerState from, CrowdtainerState to);
}

abstract contract WithModifiers {
    /**
     * @dev Throws if called by any account other than the specified.
     */
    modifier onlyAddress(address requiredAddress) {
        if (requiredAddress != msg.sender)
            revert Errors.CallerNotAllowed({
                expected: msg.sender,
                actual: requiredAddress
            });
        _;
    }
}

/**
 * @title Crowdtainer contract
 */
contract Crowdtainer is WithModifiers {
    address public immutable owner;

    // -----------------------------------------------
    //  Safety margins to avoid impractical values
    // -----------------------------------------------
    uint256 public constant SAFETY_TIME_RANGE = 1 hours;
    // @notice Maximum value for referral discounts and rewards
    uint256 public constant SAFETY_MAX_REFERRAL_RATE = 50;
    // @notice Maximum number of different products.
    uint256 public constant MAX_NUMBER_OF_PRODUCTS = 100;

    // -----------------------------------------------
    //  Values set by init function
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
    uint256[] public unitPricePerType;
    // @note Half of the value is given for being referred to by a buyer, and the other half as discount for using a referral code.
    uint256 public referralRate;
    // @note Address of the ERC20 token used for payment.
    IERC20 public token;

    CrowdtainerState private crowdtainerState;

    // Events
    event CrowdtainerCreated(address indexed owner);
    event CrowdtainerInitialized();
    event CrowdtainerInDeliveryStage();

    // @param _owner Address entitled to initialize the contract. Represents the product or service provider.
    constructor(address _owner) {
        if (_owner == address(0)) revert Errors.OwnerAddressIsZero();
        owner = _owner;
        emit CrowdtainerCreated(owner);
    }

    /**
     * @dev Initializes a Crowdtainer.
     * @dev The contract is initialized outside the constructor so that we can do more extensive symbolic testing.
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
        uint256[] memory _unitPricePerType,
        uint256 _referralRate,
        IERC20 _token
    ) public onlyAddress(owner) {
        // @dev: Basic sanity checks
        if (address(_token) == address(0)) revert Errors.TokenAddressIsZero();

        // @dev: Opening time should not be too far in the past
        if (_openingTime < block.timestamp - SAFETY_TIME_RANGE)
            revert Errors.OpeningTimeInThePast();

        // @dev: Expiration time should not be too close to the opening time
        if (_expireTime < _openingTime + SAFETY_TIME_RANGE)
            revert Errors.ClosingTimeTooEarly();

        if (_maximumSoldUnits == 0) revert Errors.InvalidMaximumSoldUnits();

        if (_minimumSoldUnits > _maximumSoldUnits)
            revert Errors.InvalidMinimumSoldUnits();

        if (
            _unitPricePerType.length == 0 ||
            _unitPricePerType.length > MAX_NUMBER_OF_PRODUCTS
        ) revert Errors.InvalidNumberOfProductTypes();

        if (_referralRate > SAFETY_MAX_REFERRAL_RATE)
            revert Errors.InvalidReferralRate({
                received: _referralRate,
                maximum: SAFETY_MAX_REFERRAL_RATE
            });

        if (crowdtainerState != CrowdtainerState.Uninitialized)
            revert Errors.InvalidStateTransition({
                from: crowdtainerState,
                to: CrowdtainerState.Initialized
            });

        crowdtainerState = CrowdtainerState.Initialized;

        openingTime = _openingTime;
        expireTime = _expireTime;
        minimumSoldUnits = _minimumSoldUnits;
        maximumSoldUnits = _maximumSoldUnits;
        unitPricePerType = _unitPricePerType;
        referralRate = _referralRate;
        token = _token;

        emit CrowdtainerInitialized();
    }

    function getPaidAndDeliver() public onlyAddress(owner) {
        // TODO: implementation
        emit CrowdtainerInDeliveryStage();
    }
}
