// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

// @dev External dependencies
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// @dev Internal dependencies
import "./ICrowdtainer.sol";
import "./Errors.sol";
import "./Constants.sol";

interface AuthorizationGateway {
    function getSignedJoinApproval(
        address crowdtainerAddress,
        address addr,
        uint256[] calldata quantities,
        bool _enableReferral,
        address _referrer
    ) external view returns (bytes memory signature);
}

/**
 * @title Crowdtainer contract
 * @author Crowdtainer.eth
 */
contract Crowdtainer is ICrowdtainer, ReentrancyGuard, Initializable {
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    // -----------------------------------------------
    //  Main project state
    // -----------------------------------------------
    CrowdtainerState public crowdtainerState;

    /// @notice Owner of this contract.
    /// @dev Has permissions to call: initialize(), join() and leave() functions. These functions are optionally
    /// @dev gated so that an owner contract can do special accounting (such as an EIP721-compliant contract as its owner).
    address public owner;

    /// @notice The entity or person responsible for the delivery of this crowdtainer project.
    /// @dev Allowed to call getPaidAndDeliver(), abortProject() and set signer address.
    address public shippingAgent;

    /// @notice Maps wallets that joined this Crowdtainer to the values they paid to join.
    mapping(address => uint256) public costForWallet;

    /// @notice Maps accounts to accumulated referral rewards.
    mapping(address => uint256) public accumulatedRewardsOf;

    /// @notice Total rewards claimable for project.
    uint256 public accumulatedRewards;

    /// @notice Maps referee to referrer.
    mapping(address => address) public referrerOfReferee;

    uint256 public referralEligibilityValue;

    /// @notice Wether an account has opted into being elibible for referral rewards.
    mapping(address => bool) public enableReferral;

    /// @notice Maps the total discount for each user.
    mapping(address => uint256) public discountForUser;

    /// @notice The total value raised/accumulated by this contract.
    uint256 public totalValueRaised;

    /// @notice Address owned by shipping agent to sign authorization transactions.
    address private signer;

    /// @notice Mapping of addresses to random nonces; Used for transaction replay protection.
    mapping(address => mapping(bytes32 => bool)) public usedNonces;

    /// @notice URL templates to the service provider's gateways that implement the CCIP-read protocol.
    string[] public urls;

    uint256 internal oneUnit; // Smallest unit based on erc20 decimals.

    // -----------------------------------------------
    //  Modifiers
    // -----------------------------------------------
    /**
     * @dev If the Crowdtainer contract has an "owner" contract (such as Vouchers721.sol), this modifier will
     * enforce that only the owner can call this function. If no owner is assigned (is address(0)), then the
     * restriction is not applied, in which case msg.sender checks are performed by the owner.
     */
    modifier onlyOwner() {
        if (owner == address(0)) {
            // This branch means this contract is being used as a stand-alone contract, not managed/owned by a EIP-721/1155 contract
            // E.g.: A Crowdtainer instance interacted directly by an EOA.
            _;
            return;
        }
        requireMsgSender(owner);
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

    function requireMsgSender(address requiredAddress) internal view {
        if (msg.sender != requiredAddress)
            revert Errors.CallerNotAllowed({
                expected: requiredAddress,
                actual: msg.sender
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

    /// @notice Address used for signing authorizations. This allows for arbitrary
    /// off-chain mechanisms to apply law-based restrictions and/or combat bots squatting offered items.
    /// @notice If signer equals to address(0), no restriction is applied.
    function getSigner() external view returns (address) {
        return signer;
    }

    function setSigner(address _signer) external {
        requireMsgSender(shippingAgent);
        signer = _signer;
        emit SignerChanged(signer);
    }

    function setUrls(string[] memory _urls) external {
        requireMsgSender(shippingAgent);
        urls = _urls;
        emit CCIPURLChanged(urls);
    }

    // -----------------------------------------------
    //  Values set by initialize function
    // -----------------------------------------------
    /// @notice Time after which it is possible to join this Crowdtainer.
    uint256 public openingTime;
    /// @notice Time after which it is no longer possible for the service or product provider to withdraw funds.
    uint256 public expireTime;
    /// @notice Minimum amount in ERC20 units required for Crowdtainer to be considered to be successful.
    uint256 public targetMinimum;
    /// @notice Amount in ERC20 units after which no further participation is possible.
    uint256 public targetMaximum;
    /// @notice The price for each unit type.
    /// @dev The price should be given in the number of smallest unit for precision (e.g 10^18 == 1 DAI).
    uint256[] public unitPricePerType;
    /// @notice Half of the value act as a discount for a new participant using an existing referral code, and the other
    /// half is given for the participant making a referral. The former is similar to the 'cash discount device' in stamp era,
    /// while the latter is a reward for contributing to the Crowdtainer by incentivising participation from others.
    uint256 public referralRate;
    /// @notice Address of the ERC20 token used for payment.
    IERC20 public token;
    /// @notice URI string pointing to the legal terms and conditions ruling this project.
    string public legalContractURI;

    // -----------------------------------------------
    //  Events
    // -----------------------------------------------

    /// @notice Emmited when the signer changes.
    event SignerChanged(address indexed newSigner);

    /// @notice Emmited when CCIP-read URLs changes.
    event CCIPURLChanged(string[] indexed newUrls);

    /// @notice Emmited when a Crowdtainer is created.
    event CrowdtainerCreated(
        address indexed owner,
        address indexed shippingAgent
    );

    /// @notice Emmited when a Crowdtainer is initialized.
    event CrowdtainerInitialized(
        address indexed _owner,
        IERC20 _token,
        uint256 _openingTime,
        uint256 _expireTime,
        uint256 _targetMinimum,
        uint256 _targetMaximum,
        uint256[] _unitPricePerType,
        uint256 _referralRate,
        uint256 _referralEligibilityValue,
        string _legalContractURI,
        address _signer
    );

    /// @notice Emmited when a user joins, signalling participation intent.
    event Joined(
        address indexed wallet,
        uint256[] quantities,
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
     * @notice Initializes a Crowdtainer.
     * @param _owner The contract owning this Crowdtainer instance, if any (address(0x0) for no owner).
     * @param _campaignData Data defining all rules and values of this Crowdtainer instance.
     */
    function initialize(
        address _owner,
        CampaignData calldata _campaignData
    ) external initializer onlyInState(CrowdtainerState.Uninitialized) {
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

        uint256 _oneUnit = 10 ** IERC20Metadata(_campaignData.token).decimals();

        for (uint256 i = 0; i < _campaignData.unitPricePerType.length; i++) {
            if (_campaignData.unitPricePerType[i] < _oneUnit) {
                revert Errors.PriceTooLow();
            }
        }

        if (_campaignData.referralRate > SAFETY_MAX_REFERRAL_RATE)
            revert Errors.InvalidReferralRate({
                received: _campaignData.referralRate,
                maximum: SAFETY_MAX_REFERRAL_RATE
            });

        shippingAgent = _campaignData.shippingAgent;
        signer = _campaignData.signer;
        openingTime = _campaignData.openingTime;
        expireTime = _campaignData.expireTime;
        targetMinimum = _campaignData.targetMinimum;
        targetMaximum = _campaignData.targetMaximum;
        unitPricePerType = _campaignData.unitPricePerType;
        referralRate = _campaignData.referralRate;
        referralEligibilityValue = _campaignData.referralEligibilityValue;
        token = IERC20(_campaignData.token);
        legalContractURI = _campaignData.legalContractURI;
        oneUnit = _oneUnit;

        crowdtainerState = CrowdtainerState.Funding;

        emit CrowdtainerInitialized(
            owner,
            token,
            openingTime,
            expireTime,
            targetMinimum,
            targetMaximum,
            unitPricePerType,
            referralRate,
            referralEligibilityValue,
            legalContractURI,
            signer
        );
    }

    function numberOfProducts() external view returns (uint256) {
        return unitPricePerType.length;
    }

    /**
     * @notice Join the Crowdtainer project.
     * @param _wallet The wallet that is joining the Crowdtainer. Must be the msg.sender if Crowdtainer owner is address(0x0).
     * @param _quantities Array with the number of units desired for each product.
     *
     * @dev This method is present to make wallet interactions more friendly, by requiring fewer parameters for projects with referral system disabled.
     * @dev Requires IERC20 permit.
     */
    function join(address _wallet, uint256[] calldata _quantities) public {
        join(_wallet, _quantities, false, address(0));
    }

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
    )
        public
        onlyOwner
        onlyInState(CrowdtainerState.Funding)
        onlyActive
        nonReentrant
    {
        if (signer != address(0)) {
            // See https://eips.ethereum.org/EIPS/eip-3668
            revert Errors.OffchainLookup(
                address(this), // sender
                urls, // gateway urls
                abi.encodeWithSelector(
                    AuthorizationGateway.getSignedJoinApproval.selector,
                    address(this),
                    _wallet,
                    _quantities,
                    _enableReferral,
                    _referrer
                ), // parameters/data for the gateway (callData)
                Crowdtainer.joinWithSignature.selector, // 4-byte callback function selector
                abi.encode(_wallet, _quantities, _enableReferral, _referrer) // parameters for the contract callback function
            );
        }

        if (owner == address(0)) {
            requireMsgSender(_wallet);
        }

        _join(_wallet, _quantities, _enableReferral, _referrer);
    }

    /**
     * @notice Allows joining by means of CCIP-READ (EIP-3668).
     * @param result (uint64, bytes) of signature validity and the signature itself.
     * @param extraData ABI encoded parameters for _join() method.
     *
     * @dev Requires IRC20 permit.
     */
    function joinWithSignature(
        bytes calldata result, // off-chain signed payload
        bytes calldata extraData // retained by client, passed for verification in this function
    )
        external
        onlyOwner
        onlyInState(CrowdtainerState.Funding)
        onlyActive
        nonReentrant
    {
        require(signer != address(0));

        // decode extraData provided by client
        (
            address _wallet,
            uint256[] memory _quantities,
            bool _enableReferral,
            address _referrer
        ) = abi.decode(extraData, (address, uint256[], bool, address));

        if (_quantities.length != unitPricePerType.length) {
            revert Errors.InvalidProductNumberAndPrices();
        }

        if (owner == address(0)) {
            requireMsgSender(_wallet);
        }

        // Get signature from server response
        (
            address contractAddress,
            uint64 epochExpiration,
            bytes32 nonce,
            bytes memory signature
        ) = abi.decode(result, (address, uint64, bytes32, bytes));

        bytes32 messageDigest = keccak256(
            abi.encodePacked(
                contractAddress,
                _wallet,
                _quantities,
                _enableReferral,
                _referrer,
                epochExpiration,
                nonce
            )
        );

        require(
            signaturePayloadValid(
                contractAddress,
                messageDigest,
                signer,
                epochExpiration,
                nonce,
                signature
            )
        );
        usedNonces[signer][nonce] = true;

        _join(_wallet, _quantities, _enableReferral, _referrer);
    }

    function signaturePayloadValid(
        address contractAddress,
        bytes32 messageDigest,
        address expectedPublicKey,
        uint64 expiration,
        bytes32 nonce,
        bytes memory signature
    ) internal view returns (bool) {
        address recoveredPublicKey = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", messageDigest)
        ).recover(signature);

        if (recoveredPublicKey != expectedPublicKey) {
            revert Errors.InvalidSignature();
        }
        if (contractAddress != address(this)) {
            revert Errors.InvalidSignature();
        }

        if (expiration <= block.timestamp) {
            revert Errors.SignatureExpired(uint64(block.timestamp), expiration);
        }

        if (usedNonces[expectedPublicKey][nonce]) {
            revert Errors.NonceAlreadyUsed(expectedPublicKey, nonce);
        }

        return true;
    }

    function _join(
        address _wallet,
        uint256[] memory _quantities,
        bool _enableReferral,
        address _referrer
    ) internal {
        enableReferral[_wallet] = _enableReferral;

        if (_quantities.length != unitPricePerType.length) {
            revert Errors.InvalidProductNumberAndPrices();
        }

        // @dev Check if wallet didn't already join
        if (costForWallet[_wallet] != 0) revert Errors.UserAlreadyJoined();

        // @dev Calculate cost
        uint256 finalCost;

        for (uint256 i = 0; i < _quantities.length; i++) {
            if (_quantities[i] > MAX_NUMBER_OF_PURCHASED_ITEMS)
                revert Errors.ExceededNumberOfItemsAllowed({
                    received: _quantities[i],
                    maximum: MAX_NUMBER_OF_PURCHASED_ITEMS
                });

            finalCost += unitPricePerType[i] * _quantities[i];
        }

        if (finalCost < oneUnit) {
            revert Errors.InvalidNumberOfQuantities();
        }

        if (_enableReferral && finalCost < referralEligibilityValue)
            revert Errors.MinimumPurchaseValueForReferralNotMet({
                received: finalCost,
                minimum: referralEligibilityValue
            });

        // @dev Apply discounts to `finalCost` if applicable.
        bool eligibleForDiscount;
        // @dev Verify validity of given `referrer`
        if (_referrer != address(0) && referralRate > 0) {
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
            discount = (finalCost * referralRate) / 100 / 2;

            // @dev 1- Apply discount
            finalCost -= discount;
            discountForUser[_wallet] += discount;

            // @dev 2- Apply reward for referrer
            accumulatedRewardsOf[_referrer] += discount;
            accumulatedRewards += discount;

            referrerOfReferee[_wallet] = _referrer;
        }

        costForWallet[_wallet] = finalCost;

        // increase total value accumulated by this contract
        totalValueRaised += finalCost;

        // @dev Check if the purchase order doesn't exceed the goal's `targetMaximum`.
        if (totalValueRaised > targetMaximum)
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

    /**
     * @notice Leave the Crowdtainer and withdraw deposited funds given when joining.
     * @notice Calling this method signals that the participant is no longer interested in the project.
     * @param _wallet The wallet that is leaving the Crowdtainer.
     * @dev Only allowed if the respective Crowdtainer is in active `Funding` state.
     */
    function leave(
        address _wallet
    )
        external
        onlyOwner
        onlyInState(CrowdtainerState.Funding)
        onlyActive
        nonReentrant
    {
        if (owner == address(0)) {
            requireMsgSender(_wallet);
        }

        uint256 withdrawalTotal = costForWallet[_wallet];

        // @dev Subtract formerly given referral rewards originating from this account.
        address referrer = referrerOfReferee[_wallet];
        if (referrer != address(0)) {
            accumulatedRewardsOf[referrer] -= discountForUser[_wallet];
        }

        /* @dev If this wallet's referral was used, then it is no longer possible to leave().
         *      This is to discourage users from joining just to generate discount codes.
         *      E.g.: A user uses two different wallets, the first joins to generate a discount code for him/herself to be used in
         *      the second wallet, and then immediatelly leaves the pool from the first wallet, leaving the second wallet with a full discount. */
        if (accumulatedRewardsOf[_wallet] > 0) {
            revert Errors.CannotLeaveDueAccumulatedReferralCredits();
        }

        totalValueRaised -= costForWallet[_wallet];
        accumulatedRewards -= discountForUser[_wallet];

        costForWallet[_wallet] = 0;
        discountForUser[_wallet] = 0;
        referrerOfReferee[_wallet] = address(0);
        enableReferral[_wallet] = false;

        // @dev transfer the owed funds from this contract back to the user.
        token.safeTransfer(_wallet, withdrawalTotal);

        emit Left(_wallet, withdrawalTotal);
    }

    /**
     * @notice Function used by the service provider to signal commitment to ship service or product by withdrawing/receiving the payment.
     */
    function getPaidAndDeliver()
        public
        onlyInState(CrowdtainerState.Funding)
        nonReentrant
    {
        requireMsgSender(shippingAgent);
        uint256 availableForAgent = totalValueRaised - accumulatedRewards;

        if (totalValueRaised < targetMinimum) {
            revert Errors.MinimumTargetNotReached(
                targetMinimum,
                totalValueRaised
            );
        }

        crowdtainerState = CrowdtainerState.Delivery;

        // @dev transfer the owed funds from this contract to the service provider.
        token.safeTransfer(shippingAgent, availableForAgent);

        emit CrowdtainerInDeliveryStage(shippingAgent, availableForAgent);
    }

    /**
     * @notice Function used by project deployer to signal that it is no longer possible to the ship service or product.
     *         This puts the project into `Failed` state and participants can withdraw their funds.
     */
    function abortProject()
        public
        onlyInState(CrowdtainerState.Funding)
        nonReentrant
    {
        requireMsgSender(shippingAgent);
        crowdtainerState = CrowdtainerState.Failed;
    }

    /**
     * @notice Function used by participants to withdraw funds from a failed/expired project.
     */
    function claimFunds() public {
        claimFunds(msg.sender);
    }

    /**
     * @notice Function to withdraw funds from a failed/expired project back to the participant, with sponsored transaction.
     */
    function claimFunds(address wallet) public nonReentrant {
        uint256 withdrawalTotal = costForWallet[wallet];

        if (withdrawalTotal == 0) {
            revert Errors.InsufficientBalance();
        }

        if (block.timestamp < openingTime)
            revert Errors.OpeningTimeNotReachedYet(
                block.timestamp,
                openingTime
            );

        if (crowdtainerState == CrowdtainerState.Uninitialized)
            revert Errors.InvalidOperationFor({state: crowdtainerState});

        if (crowdtainerState == CrowdtainerState.Delivery)
            revert Errors.InvalidOperationFor({state: crowdtainerState});

        // The first interaction with this function 'nudges' the state to `Failed` if
        // the project didn't reach the goal in time, or if service provider is unresponsive.
        if (block.timestamp > expireTime && totalValueRaised < targetMinimum) {
            crowdtainerState = CrowdtainerState.Failed;
        } else if (block.timestamp > expireTime + MAX_UNRESPONSIVE_TIME) {
            crowdtainerState = CrowdtainerState.Failed;
        }

        if (crowdtainerState != CrowdtainerState.Failed)
            revert Errors.CantClaimFundsOnActiveProject();

        // Reaching this line means the project failed either due expiration or explicit transition from `abortProject()`.

        costForWallet[wallet] = 0;
        discountForUser[wallet] = 0;
        referrerOfReferee[wallet] = address(0);

        // @dev transfer the owed funds from this contract back to the user.
        token.safeTransfer(wallet, withdrawalTotal);

        emit FundsClaimed(wallet, withdrawalTotal);
    }

    /**
     * @notice Function used by participants to withdraw referral rewards from a successful project.
     */
    function claimRewards() public {
        claimRewards(msg.sender);
    }

    /**
     * @notice Function to withdraw referral rewards from a successful project, with sponsored transaction.
     */
    function claimRewards(
        address _wallet
    ) public nonReentrant onlyInState(CrowdtainerState.Delivery) {
        uint256 totalRewards = accumulatedRewardsOf[_wallet];
        accumulatedRewardsOf[_wallet] = 0;

        token.safeTransfer(_wallet, totalRewards);

        emit RewardsClaimed(_wallet, totalRewards);
    }
}
