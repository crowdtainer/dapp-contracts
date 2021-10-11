# Description of system expectations for Crowdtainer smartcontracts (v1)

## As a deployer

- I should be able to create a project by specifying the following variables so that I can start a crowdtainer for my product or service:

```
    /** @param openingTime Funding opening time.
      * @param closingTime Funding closing time.
      * @param minimumUnitsTarget The amount of sales required for funding to be considered to be successful.
      * @param maximumTargetUnits A limit after which no further purchases are possible.
      * @param token Address of the ERC20 token used for payment.
      * @param pricePerUnit The price of each unit, in ERC2O units. The price should be given in the number of smallest unit for precision (e.g 10^18 == 1 DAI).
      * @param discount The discount percentage to be received for using the referral system.
      * @param reward The reward percentage to be given for being referred to by a buyer.
      * @param legalContractIPFSHash A string containing the IPFS hash of the legal agreement to be fullfiled if the goal is reached.
      * @param legalContractSWARMHash A string containing the SWARM hash of the legal agreement to be fullfiled if the goal is reached.
      */
```

- I need tooling to deploy the contract at a deterministic address (using CREATE2 opcode), so that I can reference the contract address in the legal agreement document even before the contract has been deployed.

- I should be able to withdraw the funds if the minimum target is reached, so that I can signal that no more sales are avaiable, and start working on shipping the sold products.

> Note: Future versions will add an oracle and other verification methods, so that funds are withdrawn in steps over time (upon confirmation of milestones) and not up-front all at once.

- Should *not* allow Ether to be sent to the deployed contract itself.

## As a buyer

- I'd like way to read the IPFS/HASH data so that I can verify that the legal term is the same as provided in a frontend interface.

- I'd like to specify my details of order and signing a transaction, so that I can participate in a group buying.

- Optionally, when joining a buying group, I'd like to additionally specify:
    - a * custom personal referral code*, so that I can share it and get rewards for my friend's purchases.
    - a friend's referral code, so that I can get a discount on my own purchase.

- I’d like an API to view and withdrawl my deposits in a running project, so that I can quit if no longer interested, or if the crowdfunding failed.

- I'd like an API to view if the goal was reached, so that I can decide to either withdrawl my funds or wait for product delivery.

- I'd like an API to view how much rewards I acquired due sharing of personal referral code, if the project succeeded.

- I'd like an API to claim rewareds due sharing of personal referral code, if the project succeeded.

- I'd like an API to claim refunds if the sale was not successful.

- I'd like an API to see how much I bought for each type of product.

## As an observer (user, deployer or anyone)

- I'd like to be able to get basic information of a crowdtainer project deployed, such as:
    - All information used during deploy (opening and closing time, etc).
    - Check if contract status (Funding, expired, Delivery, Finalized ).
    - IPFS/Swarm hash which points to the legal contract documents.