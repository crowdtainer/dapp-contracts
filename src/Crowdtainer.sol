// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

library Errors {
    // --- Constructor errors ---

    // @dev: Method invoked with address(0)
    error SenderAddressIsZero();
    // @dev: Constructor token contains address(0)
    error TokeAddressIsZero();
    // @dev: Method invoked with unexpected message sender
    error CallerNotAllowed(address expected, address actual);
    // @dev: Constructor called with opening time in the past (timestamp < now)
    error OpeningTimeInThePast();
    // @dev: Constructor called with closing time is less than one hour away from the opening time
    error ClosingTimeTooEarly();
    // @dev: Constructor called with invalid number of maximum units to be sold (0)
    error InvalidMaximumSoldUnits();
    // @dev: Constructor called with invalid number of minimum units to be sold (less than maximum sold units)
    error InvalidMinimumSoldUnits();
    // @dev: Construct called with invalid number of product types (must be > 0)
    error InvalidNumberOfProductTypes();
    // @dev: Construct called with invalid price per type length (must be == number of product types)
    error InvalidPricePerTypeLength();
    // @dev: Construct called with invalid discount rate (must be between 1 and 50); i.e.: within 1% - 50%.
    error InvalidDiscountRate(uint256 rate);
    // @dev: Construct called with invalid discount rate (must be between 1 and 50). i.e.: within 1% - 50%.
    error InvalidReferralRate(uint256 rate);
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

contract Crowdtainer is WithModifiers {
    // address used when deploying this contract.
    address public immutable owner;

    string public receivedMessage;

    uint256 public immutable openingTime;
    uint256 public immutable closingTime;
    uint256 public immutable minimumSoldUnits;
    uint256 public immutable maximumSoldUnits;
    uint256 public immutable numberOfProductTypes;
    uint256[] public unitPricePerType;
    uint256 public immutable discountRate;
    uint256 public immutable referralRate;
    IERC20 public immutable token;

    // Events
    event CrowdtainerCreated(address indexed owner);
    event CrowdtainerInDeliveryStage();

    /**
     * @dev Initializes a Crowdtainer.
     * @param _openingTime Funding opening time.
     * @param _closingTime Funding closing time.
     * @param _minimumSoldUnits The amount of sales required for funding to be considered to be successful.
     * @param _maximumSoldUnits A limit after which no further purchases are possible.
     * @param _numberOfProductTypes Used as index to store the price per unit in unitPricePerType.
     * @param _unitPricePerType Array with price of each item, in ERC2O units. The price should be given in the number of smallest unit for precision (e.g 10^18 == 1 DAI).
     * @param _discountRate The discount percentage to be received for using the referral system.
     * @param _referralRate The reward percentage to be given for being referred to by a buyer.
     * @param _token Address of the ERC20 token used for payment.
     */
    constructor(
        uint256 _openingTime,
        uint256 _closingTime,
        uint256 _minimumSoldUnits,
        uint256 _maximumSoldUnits,
        uint256 _numberOfProductTypes,
        uint256[] memory _unitPricePerType,
        uint256 _discountRate,
        uint256 _referralRate,
        IERC20 _token
    ) {
        // Basic sanity checks
        if (msg.sender == address(0)) revert Errors.SenderAddressIsZero();
        if (address(_token) == address(0)) revert Errors.TokeAddressIsZero();
        if (_openingTime < block.timestamp)
            revert Errors.OpeningTimeInThePast();
        if (_closingTime < _openingTime + 1 hours)
            revert Errors.ClosingTimeTooEarly();
        if (_maximumSoldUnits == 0) revert Errors.InvalidMaximumSoldUnits();
        if (_minimumSoldUnits > _maximumSoldUnits)
            revert Errors.InvalidMinimumSoldUnits();
        if (_numberOfProductTypes == 0)
            revert Errors.InvalidNumberOfProductTypes();
        if (_unitPricePerType.length != _numberOfProductTypes)
            revert Errors.InvalidPricePerTypeLength();
        if (_discountRate == 0 || _discountRate > 50)
            revert Errors.InvalidDiscountRate(_discountRate);
        if (_referralRate == 0 || _referralRate > 50)
            revert Errors.InvalidReferralRate(_referralRate);

        owner = msg.sender;

        openingTime = _openingTime;
        closingTime = _closingTime;
        minimumSoldUnits = _minimumSoldUnits;
        maximumSoldUnits = _maximumSoldUnits;
        numberOfProductTypes = _numberOfProductTypes;
        unitPricePerType = _unitPricePerType;
        discountRate = _discountRate;
        referralRate = _referralRate;
        token = _token;

        emit CrowdtainerCreated(owner);
    }

    function getPaidAndDeliver() public onlyAddress(owner) {
        // TODO: implementation
        emit CrowdtainerInDeliveryStage();
    }
}
