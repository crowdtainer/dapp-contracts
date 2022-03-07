# Crowdtainer smart contracts system description (v1)

> This evolving document describes and drives development of the initial version of Crowdtainer, so that any interested parties working on it have a central point to refer and make improvements to the system.
> Non-developers are also welcome to read this document to make decisions about how the system works and set expectations accordingly. Eventually development should be frozen (together with this document) before an initial version is released.
## Problem statement

The main goal of these smart contracts is help people with similar interests to coordinate and form a bulk purchase. This helps reduce costs for the whole group due improved logistics, and might enable otherwise impossible projects to actually happen due improved social coordination. Buyers then have more diversity of products and services to choose from, at a potentially lower cost. At the supply side, projects that were formerly impossible due low economies of scale or tragedy of common goods problems, may now become a possibility. The main focus of this project is to empower the many small entrepreneurs or small communities that has been marginalized by monopolies.

If we imagine a very generic way to categorize project types based on quantity and cost per unit delivered, we envision Crowdtainer projects in its current version to be a good fit (or not), according to the following table:

| Unitary value     |  Sale quantity    | Applicability |
| -------------     | :-------------:   |         -----:|
| Low               | Large             |           Yes |
| Low               | Small             |           Yes |
| High              | Small             |            No |
| High              | Large             |         Maybe |

### How is this different than other existing crowdfunding platforms?

The idea is not far away, but there are some crucial implementation differences: 

- The lack of yet another company between the seller and buyer, since coordination happens via smart contract.
- Competitive/low fees: the theoretical minimum fee possible is the blockchain or rollup transaction fee.
- Allows for more flexible design and transparency of the incentive mechanims, for example: In Crowdtainer, the person that indicates a friend with a referral code is rewarded proportionally to the number of people using the given code. This doesn't happen with most crowdfunding platforms (if any).
- Here (at least to start) we envision usage to have a normal legal sales agreement for delivering the promised products if the funding is successful, making it a normal product sale in legal terms. The initial users plan to start/bootstrap with simpler/safer products/services, and not product or services that have a high risk of not being delivered. Though, that is up to the users of smart contract.
- Generic implementation, allowing a variety of applications ranging from bulk purchases to crowdfunding donations or aid missions.
- Permisionless: anyone can deploy and start their own project. The reputation and worthiness of each project however lays on the participant to analyse and judge, and it is upon the service provider to write their sale contracts, websites, and finally deliver on the promises. Competitive interfaces may then be built around the smart contracts, providing the full range of choices from the most permissionless all the way to a curated version where only audited service providers can join.

### What these smart contracts *do not* provide?

- There are no curation / KYC mechanism at the core / smart contract level. We hope people will build systems on top of this basic layer, to curate high quality projects and help avoid scams while keeping those raising funds accountable in their respective juridsdictions.

### Example use case:

An innovative farmer discovered a way to produce fresh, organic, and climate neutral vegetables with less chemicals by protecting his crop in a smart and natural way. He would like to bring this innovation to his whole town, but to do so, he'd need some upfront capital to plant more. However he doesn't know if the future sales would be enough to pay for the investment.

He might do it anyway, and thus take a huge risk upon himself, by sponsoring the whole thing and hoping for the best later (that there will be will be enough demand and purchases to pay off the debts). Or, he might simply not take the risk and not grow his plantation.

In the situation above, society potentially lost a great idea. Instead, using this smart contract, he is given another option, to see if there is real demand for his product even before getting into debt.

There are two possibilities that can now happen:
 - In the bad case, not enough people are interested in the innovation. Those who did participate (if any) simply take their money back from the contract. Now at least the farmer knows there is no demand and is not into debt.
 - In the good case, enough people are interested, and the farmer knows he can invest in producing more vegetables, because there are now buyers waiting for it.

## Actors and System States

There are 2 main actor types involved:

- *Group Buying side*: a collective of people willing to coordinate in group buying. This group is referred as "participants".
- *Selling side*: A company or person willing to sell a service or product. This group is referred as "shipping agent" or "service provider".

The smart contract has the following possible states:

- *Uninitialized*: The Crowdtainer contract was deployed but has not been initialized yet.
- *Funding*: The project started and is collecting interested participant's funds. Any participant is allowed to change their mind and withdraw their funds at this stage. The service provider is not allowed to withdraw any funds.
- *Failed*: The project's goal has not been reached in time. Any participant can widraw their funds back. The service provider is not allowed to withdraw any funds.
- *Delivery*: Successfully funded and the service provider withdrew the funds to signal commitment to deliver the products or services.

Only the *selling side* (deployer of the contract, i.e. service/product provider) is able to switch the contract into "Delivery" state. This is used to simultaneously withdraw the funds and signal that the provider agrees with the orders and represents her/his "signature" of the agreement to the sale terms.

If the deployer/service provider for whatever reason is no longer interested or able to provide the service/products it is possible for the provider to manually signal this via smart contract method, or it eventually enter into "Expired" state if no action is taken. Both these conditions put the project state to `Failed` mode, in which participants may withdraw their contributed funds.

Once the smart contract is in "Delivery" state however, it is no longer possible for participants to withdraw their funds. Should an event happen where the provider can't deliver the promised services, dispute resolution happens via normal means, and the provider needs to return the funds manually.

> Note: Future versions may add an oracle and other verification methods, so that funds are withdrawn in steps over time (e.g., upon confirmation of milestones) and not up-front all at once, thus reducing the need to trust in the local existing legal system for disputes related to the contractual sale.

## Participation incentive mechanism

For the *group buying side*, the smart contract contains two incentive mechanisms (described below) in order to reward participants that provably helped the group to achieve the project goal. This is similar to referral codes available in apps like Uber or Airbnb, but it is different in that usually those credits are restricted for usage within those apps themselves, while here, one can withdraw the credits and do whatever is desired with it, since it is redeemed in ERC20 tokens (e.g., a 'stablecoin'). Such indication rewards have no caps and is proportional to the number of times it was referred to. Furthermore, to incentivize another user to use a referral code, a discount is applied to the new purchase.

The following main parameters are given by the user when joining:

* `quantities`: Array with the number of units desired for each product or service.
* `enableReferral`: Informs whether the user would like to be eligible to collect rewards for being referred. The participant's wallet address becomes the "referral/voucher code" that can be given to other people. If a subsequent new purchase refers to this given code, it entitles the referrer user a percentage of the 'sale' - redeemable directly in the smart contract if the funding is successful.
* `referrer`: Optional referral code to be used to claim a discount. If not specified, the participant pays the full product price times their respective quantities. If specified, half the referral value is credited to the referral code owner (the user which joined with `enableReferral` set to true), and another half becomes a discount applied to the total cost of the user joining ((sum of product quantities * prices) * discount).

Example:

- For a Crowdtainer setup with a single product at 50 USD price per unit, and referral rate of 20%, and a minimum target of 500 USD. Recall that the referral rate is divided by 2, where half is used to apply a discount for a user joining, the other half as reward for the referrer (10% each in this example).

- Alice joins requesting one unit (thus spending 50 USD), with referrals enabled for her account. She publishes her referral code in her blog.

- 20 other new participants use Alice's referral code to request one product unit each when joining. These new participants get a discount of 10% on their purchase (each new participant therefore pays 45 USD).

- Alice's rewards will be: 100 USD. Explanation: 20 (units) x 50 (product price in USD) x 10% (reward rate / 2). If we now subtract her cost of joining, Alice gets one unit of product "for free" while effectively receiving 50 USD as a compensation for referral of 20 participants: 100 USD in rewards minus cost of joining of 50 USD.

- Finally, given the minimum funding target is reached, the service provider / agent is able to withdraw:
```
        + 50            (Alice's payment to join)
        + (45 * 18)     (Total value accrued from 20 participants)
        - 100           (Alice's rewards)
        ------------
        760 USD         (payment for supplying/delivering all products or services)
```

> All rewards are redeemable only if a project has its minimum funding goals met and entered `Delivery` state.

> The minimum target is set by the project creator (when deploying a new Crowdtainer). Also, the project deployer may set the referral rate to zero, which effectively disables the referral system altogether.

> Front-ends / UI's should enable ENS resolution to make sharing/typing these codes easier.

## User Stories

What follows is a detailed description of the smart contract expectations in User Stories format.
### As a project deployer

- I must be able to create a project by specifying the following variables so that I can start a crowdtainer for my product or service:

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

- I need tooling to deploy the contract at a deterministic address, so that I can reference the contract address in the legal agreement document even before the contract has been deployed.
    - TBD if needed on first version.

- I must be able to withdraw the funds if the minimum target is reached, so that I can signal that no more sales are available, and start working on shipping the sold products.

- The withdrawl function should allow for partial withdrawals, so that participants can get a 'cash-back' in case the estimated price for producing the service or product was higher than estimated.
    - This allows for getting signal of intent from participants, even before the exact final cost can be calculated, by guessing the cost by a higher margin. E.g.: Estimate unit meal cost of 15 eur per person for price to pool money, but return overpayment once the exact final price was calculated by the restaurant (discounting for shipping savings etc).
    - The withdrawl function needs to provide the final prices array, so that each participant is correctly assigned the remainder value.

- I need a 2-way communication channel, so that once a Crowdtainer is successful, I can communicate with them regarding their delivery. 
    - Ideas: NFT-gated discord channel per Crowdtainer project.

- I need a method to cancel a project, so that I can signal participants that the project will no longer be possible, and participants are therefore able to leave taking their money without waiting for expiration.

### As a buyer/participant

- I'd like way to read the IPFS/HASH data so that I can verify that the legal term is the same as provided in a frontend interface.

- I'd like to specify my details of order and sign such transaction, so that I can participate in a group buying.

- Optionally, when joining a buying group, I'd like to additionally specify:
    - whether I'd like to be eligible to share referral code and get rewards for my friend's purchases:
        - If the user opts into the program and the referral code is used, it is no longer possible to leave the project and get refunds (at the "Funding" stage). This is to prevent users getting the discount then leaving.
    - a friend's referral code, so that I can get a discount on my own purchase.

- I’d like an API to view and withdrawl my deposits in a running project, so that I can quit if no longer interested, or if the crowdfunding failed.

- I'd like an API to view if the goal was reached, so that I can decide to either withdrawl my funds or wait for product delivery.

- I'd like an API to view how much rewards I acquired due sharing of personal referral code, if the project succeeded.

- I'd like an API to claim rewards due sharing of referral code (if the project succeeded).

- I'd like an API to claim refunds if the sale was not successful.

- I'd like an API to see how much I bought for each type of product.

- I'd like the contract to not allow Ether (payable function disabled), so that I don't accidently send Ether to it (since the contract only accepts a certain ERC20 token).

### As an observer (anyone)

- I'd like to be able to get basic information of a crowdtainer project deployed, such as:
    - All information used during deployment (opening and closing time, etc).
    - Check the contract status (Funding, Expired, Delivery, Finalized).
    - To be decided: IPFS/Swarm hash which points to the legal contract documents.

## Periphery contracts

In addition to the core "Crowdtainer" contract, a wrapper EIP-1155 contract can be used to manage Crowdtainer projects.

Being EIP-1155 compliant provides the following benefits:
- User interfaces can more easily manage multiple projects, keep track of ownership, and allow for easy transferability of ownership/claims in projects.
- Interoperability with other platforms that understand the EIP-1155 interface.
- Allow service/product providers to authenticate messages for communication and delivery, based on the token owner. E.g.: gated discord channel for chat support, which only buyers can enter, thus solving the spam/bot problem without requiring KYC.
- Allow service providers to ask the customer's personal data (if needed), only when needed (upon successful project funding). This makes the token act as a voucher that is used to redeem the given products. Only when the redeem period arrives, the customer may provide any personal data required for service fulfillment.
- With the token, it becomes possible to easily "gift" someone a product/service, without knowing anything but the person's Ethereum wallet address:
    - E.g.: Alice wants to give a bottle of fine wine to Bob. Usually, Alice would have to ask Bob for his physical home address, then put Bob's address in the service provider website. In that case both she and the service provider knows Bob's home address. Having a token allows Alice instead to simply send the token to Bob's Ethereum wallet address, and this allows Bob to claim the wine bottle in the service provider website to be shipped to him. In the latter case, only who needs to know Bob's address knows it: the service/product provider.
- The project can enter a temporary "redeem period", where token transfers are paused. This gives time to allow participants to prove their participation in order to claim the products or services with the service provider (off-chain), providing any further information as required (off-chain).

## Potential ideas or features to be decided for inclusion

- Implement partial/milestones-based withdrawls, based on weighted delegate voting (weight proportional to referral amount)
    - If payment doesn't pass through voting, switch to Failed mode and allow participants to withdrawl the remainder amounts.
    - TBD:
        - how to decide on ratios / threshold values that defines vote quorum (?)
        - any potential negative/unintended side-effects? I.e., think about possible collusion, lack of privacy etc.
- Add parameter where the Crowdtainer deployer (agent) can specify an "agent fee", from zero up to a certain maximum reasonable value.
- Allow Agent / service provider partial withdrawl + provide a merkle root, which is used to allow certain participants to take their money back. This can be used to easily return funds to people that failed i.e. to provide a shipping address to complete the purchase.
- "Native" Meta-transaction support



