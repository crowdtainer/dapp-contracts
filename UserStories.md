# Crowdtainer smart contracts system description (v1)

> This evolving document describes and drives development of the initial version of Crowdtainer, so that any interested parties working on it have a central point to refer and make improvements to the system.
> Non-developers are also welcome to read this document to make consious decisions about how the system works and set expectations accordingly. Eventually development should be frozen (together with this document) before an initial version is released.
## Problem statement

The main goal of the contract is help people with similar interests to coordinate and form a bulk purchase. This helps reduce costs for the whole group due improved logistics, and might enable otherwise impossible projects to actually happen. Buyers then have more diversity of products to choose from, at a potentially lower cost. At the supply side, projects that were formerly impossible due low economies of scale or tragedy of common goods problems, now become a possibility.

### How is this different than other existing crowdfunding platform?

The idea is not far away, but there are some crucial implementation differences: 

- The lack of yet another company between the seller and buyer, since coordination happens via smart contract.
- Allows for more flexible design and transparency of the incentive mechanims.
- Here (at least to start) there is an actual legal sales agreement for delivering the promised products. We are starting with simpler/safer products/services, and not things that are ultra high risk of not being delivered.

### Example:

An innovative farmer discovered a way to produce fresh, organic, and climate neutral vegetables with less chemicals by protecting his crop in a smart and natural way. He would like to bring this innovation to his whole town, but to do so, he'd need some upfront capital to plant more. However he doesn't know if the future sales would be enough to pay for the investment.

He might do it anyway, and thus take a huge risk upon himself, by sponsoring the whole thing and hoping for the best later (that there will be will be enough demand and purchases to pay off the debts). Or, he might simply not take the risk and not grow his plantation.

In the situation above, society potentially lost a great idea. Instead, using this smart contract, he is given another option, to see if there is real demand for his product even before getting into debt.

There are two possibilities that can now happen:
 - In the bad case, not enough people are interested in the innovation. Those who did participate (if any) simply take their money back from the contract. Now at least the farmer knows there is no demand and is not into debt.
 - In the good case, enough people are interested, and the farmer knows he can invest in producing more vegetables, because there are now buyers waiting for it.

## Actors and System States

There are 2 main actor types involved:

- *Group Buying side*: a collective of people willing to coordinate in group buying.
- *Selling side*: A company or person willing to sell a service or product.

The contract has the following possible states:

- *Funding*:  The project started and is collecting interested people's funds. Any participant is allowed to change their mind and withdraw their funds at this stage. The service provider is not allowed to withdraw any funds.
- *Failed*:  The project's goal has not been reached in time. Any participant can widraw their funds back. The service provider however is not allowed to withdraw any funds.
- *Delivery*: Successfully funded and the products or services will be delivered per legal contract terms. Funds are made available for the service/product provider.

Only the *selling side* (deployer of the contract, i.e. service/product provider) is able to switch the contract into "Delivery" state. This is used to simultaneously withdraw the funds and signal that the provider agrees with the orders and represents her/his "signature" of the agreement to the sale terms.

If the deployer/service provider for whatever reason is no longer interested or able to provide the service/products (by not switching the contract to this state), it eventually enter into "Expired" state.

Once the smart contract is in "Delivery" state, it is no longer possible for participants to withdraw their funds. Should an event happen where the provider can't deliver the promised services, dispute resolution happens via normal means, and the provider needs to return the funds manually.

> Note: Future versions will add an oracle and other verification methods, so that funds are withdrawn in steps over time (upon confirmation of milestones) and not up-front all at once, thus reducing the need to trust in the local existing legal system for disputes related to the contractual sale.

## Smart contract incentive mechanism 

For the *group buying side*, the smart contract contains two incentive mechanisms (described below) in order to reward participants that provably helped the group to achieve their minimum goal. This is similar to referral codes available in apps like Uber or Airbnb, but it is different in that usually those credits are restricted for usage within those apps themselves, while here, one can withdraw the credits and do whatever is desired with it, since it is redeemed in stablecoin. It also has no limits and is proportional to the number of times it was referred to.

- *Referral code sharing*: Participants are given a referral code after a purchase. If a new purchase refers to this given code, this entitles the referral code owner to a percentage of the sale - redeemable directly in the smart contract.

- *Buy with referral code*: Participants that uses a referral code during a purchase, get a discount in their purchase - also redeemable directly in the smart contract.

Example:

For a Crowdtainer setup with a single product at 50 DAI per unit, and referral rate of 20%:

* User A joins a Crowdtainer (spending 50 DAI) and publishes her referral code in her blog. 100 people then use her referral code to get a discount on a new purchase. User A's rewards will then be 950 DAI: 100 (units) x 50 (product price in DAI) x 0.2 (reward rate) - 50 (cost of joining the Crowdtainer with one product unit).

> Note: All rewards are redeemable only if a project has its minimum funding goals met.

## User Stories

What follows is a detailed description of the smart contract expectations in User Stories format.
### As a project deployer

- I must be able to create a project by specifying the following variables so that I can start a crowdtainer for my product or service:

```
    /**
     * @param _openingTime Funding opening time.
     * @param _expireTime Time after which the owner can no longer withdraw funds.
     * @param _minimumSoldUnits The amount of sales required for funding to be considered to be successful.
     * @param _maximumSoldUnits A limit after which no further purchases are possible.
     * @param _unitPricePerType Array with price of each item, in ERC2O units.
     * @param _referralRate Percentage used for incentivising participation.
     * @param _token Address of the ERC20 token used for payment.
     */
```

- I need tooling to deploy the contract at a deterministic address, so that I can reference the contract address in the legal agreement document even before the contract has been deployed.

- I must be able to withdraw the funds if the minimum target is reached, so that I can signal that no more sales are avaiable, and start working on shipping the sold products.

- The withdrawl function should allow for partial withdrawals, so that participants can get a 'cash-back' in case the estimated price for producing the service or product was higher than estimated.
    - This allows for getting signal of intent from participants, even before the exact final cost can be calculated, by guessing the cost by a higher margin. E.g.: Estimate unit meal cost of 15 eur per person for price to pool money, but return overpayment once the exact final price was calculated by the restaurant (discounting for shipping savings etc).
    - The withdrawl function needs to provide the final prices array, so that each participant is correctly assigned the remainder value.

- I need a 2-way communication channel, so that once a Crowdtainer is successful, I can communicate with them regarding their delivery.

### As a buyer

- I'd like way to read the IPFS/HASH data so that I can verify that the legal term is the same as provided in a frontend interface.

- I'd like to specify my details of order and signing a transaction, so that I can participate in a group buying.

- Optionally, when joining a buying group, I'd like to additionally specify:
    - a *custom personal referral code*, so that I can share it and get rewards for my friend's purchases.
    - a friend's referral code, so that I can get a discount on my own purchase.

- I’d like an API to view and withdrawl my deposits in a running project, so that I can quit if no longer interested, or if the crowdfunding failed.

- I'd like an API to view if the goal was reached, so that I can decide to either withdrawl my funds or wait for product delivery.

- I'd like an API to view how much rewards I acquired due sharing of personal referral code, if the project succeeded.

- I'd like an API to claim rewards due sharing of referral code (if the project succeeded).

- I'd like an API to claim refunds if the sale was not successful.

- I'd like an API to see how much I bought for each type of product.

- I'd like the contract to not allow Ether (payable function disabled), so that I don't accidently send Ether to it (since the contract only accepts a certain ERC20 token).

### As an observer (user, deployer or anyone)

- I'd like to be able to get basic information of a crowdtainer project deployed, such as:
    - All information used during deploy (opening and closing time, etc).
    - Check if contract status (Funding, Expired, Delivery, Finalized).
    - IPFS/Swarm hash which points to the legal contract documents.
