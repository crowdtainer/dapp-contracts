
## User Stories

What follows is a detailed description of the smart contract expectations in User Stories format.
- ✅ are completed items, ◻️ otherwise.
### As a project deployer

- ✅ I must be able to create a project by specifying the following variables so that I can start a crowdtainer for my product or service:

```
    /**
     * @param _shippingAgent Address that represents the product or service provider.
     * @param _openingTime Funding opening time.
     * @param _expireTime Time after which the shipping agent can no longer withdraw funds.
     * @param _targetMinimum Amount in ERC20 units required for the Crowdtainer to be considered to be successful.
     * @param _targetMaximum Amount in ERC20 units after which no further participation is possible.
     * @param _unitPricePerType Array with price of each item, in ERC2O units. Zero indicates end of product list.
     * @param _referralRate Percentage used for incentivising participation. Half the amount goes to the referee, and the other half to the referrer.
     * @param _referralEligibilityValue The minimum purchase value required to be eligible to participate in referral rewards.
     * @param _token Address of the ERC20 token used for payment.
```

- ✅ I must be able to withdraw the funds if the minimum target is reached, so that I can signal that no more sales are available, and start working on shipping the sold products.

- (redacted for MVP) ~~The withdrawl function should allow for partial withdrawals, so that participants can get a 'cash-back' in case the estimated price for producing the service or product was higher than estimated.~~ 
    - ~~This allows for getting signal of intent from participants, even before the exact final cost can be calculated, by guessing the cost by a higher margin. E.g.: Estimate unit meal cost of 15 eur per person for price to pool money, but return overpayment once the exact final price was calculated by the restaurant (discounting for shipping savings etc).~~ 
    - ~~The withdrawl function needs to provide the final prices array, so that each participant is correctly assigned the remainder value.~~ 
- ✅ I need a way to mark a voucher as "claimed". (done in commit 8626f67)

- ✅ I need a 2-way communication channel, so that once a Crowdtainer is successful, I can communicate with them regarding their delivery. 
    - Idea: NFT-gated discord channel per Crowdtainer project. (Found https://swordybot.com/ and https://Collab.Land)

- ✅ I need a method to cancel a project, so that I can signal participants that the project will no longer be possible, and participants are therefore able to leave taking their money without waiting for expiration.

### As a buyer/participant

- ◻️ I'd like way to read the IPFS/HASH data so that I can verify that the legal term is the same as provided in a frontend interface.

- ✅ I'd like to specify my details of order and sign such transaction, so that I can participate in a group buying.

- Optionally, when joining a buying group, I'd like to additionally specify:
    - ✅ whether I'd like to be eligible to share referral code and get rewards for my friend's purchases:
        - ✅ If the user opts into the program and the referral code is used, it is no longer possible to leave the project and get refunds (at the "Funding" stage). This is to prevent users getting the discount then leaving.
    - ✅ a friend's referral code, so that I can get a discount on my own purchase.

- ✅ I’d like an API to view and withdrawl my deposits in a running project, so that I can quit if no longer interested, or if the crowdfunding failed.

- ✅ I'd like an API to view if the goal was reached, so that I can decide to either withdrawl my funds or wait for product delivery.

- ✅ I'd like an API to view how much rewards I acquired due sharing of personal referral code, if the project succeeded.

- ✅ I'd like an API to claim rewards due sharing of referral code (if the project succeeded).

- ✅ I'd like an API to claim refunds if the sale was not successful.

- ✅ I'd like an API to see how much I bought for each type of product.

- ✅ I'd like the contract to not allow Ether (payable function disabled), so that I don't accidently send Ether to it (since the contract only accepts a certain ERC20 token).

### As an observer (anyone)

- I'd like to be able to get basic information of a crowdtainer project deployed, such as:
    - ✅ All information used during deployment (opening and closing time, etc).
    - ✅ Check the contract status (Funding, Expired, Delivery, Finalized).
    - To be decided: IPFS/Swarm hash which points to the legal contract documents.


## Potential ideas or features to be decided for inclusion

- Implement partial/milestones-based withdrawls, based on weighted delegate voting (weight proportional to referral amount)
    - If payment doesn't pass through voting, switch to Failed mode and allow participants to withdrawl the remainder amounts.
    - TBD:
        - how to decide on ratios / threshold values that defines vote quorum (?)
        - any potential negative/unintended side-effects? I.e., think about possible collusion, lack of privacy etc.
- Add parameter where the Crowdtainer deployer (agent) can specify an "agent fee", from zero up to a certain maximum reasonable value.
- Allow Agent / service provider partial withdrawl + provide a merkle root, which is used to allow certain participants to take their money back. This can be used to easily return funds to people that failed i.e. to provide a shipping address to complete the purchase.
- "Native" Meta-transaction support
