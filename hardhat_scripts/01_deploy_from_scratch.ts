// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";
import { BigNumberish } from "@ethersproject/bignumber/lib/bignumber";
import { parseUnits } from "ethers/lib/utils";
import { Vouchers721 } from "../out/typechain";

// This script is mainly used for testing a 'real' deployment on localhost, without reusing any former deployment.

async function main() {
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // Deploy contracts
  // Crowdtainer
  const crowdtainerFactory = await ethers.getContractFactory("Crowdtainer");
  const crowdtainer = await crowdtainerFactory.deploy();
  await crowdtainer.deployed();
  console.log("Crowdtainer deployed to:", crowdtainer.address);

  // @audit-issue Always initialize implementation contracts. Seems to be missing a crowdtainer.initialize.

  const metadataServiceV1Factory = await ethers.getContractFactory(
    "MetadataServiceV1"
  );

  const coinFactory = await ethers.getContractFactory("MockERC20");
  const coin = await coinFactory.deploy("FakeERC20", "USDC", 6);
  await coin.deployed();
  const erc20Decimals = await coin.decimals();
  console.log("Coin deployed to:", coin.address);
  console.log("Coin symbol:", await coin.symbol());
  console.log("Coin decimals:", erc20Decimals);

  // here
  const [agent, neo, trinity] = await ethers.getSigners();

  const mainnetChainId = 1;
  const isMainnet = (await agent.getChainId()) === mainnetChainId;

  if (isMainnet) {
    console.warn(
      "Mainnet configuration detected, skipping MockERC20 token distribution."
    );
    return;
  }

  const symbol = await coin.symbol();
  const quantity = parseUnits("10000", 6);

  console.log(`Mint ${quantity} ${symbol} to trinity (${trinity.address}).`);
  await coin.mint(trinity.address, quantity);

  console.log(`Mint ${quantity} ${symbol} to neo (${neo.address}).`);
  await coin.mint(neo.address, quantity);

  console.log(`Mint ${quantity} ${symbol} to agent (${agent.address}).`);
  await coin.mint(agent.address, quantity);

  console.log(`Done.`);

  const metadataService = await metadataServiceV1Factory.deploy(
    "USDC",
    erc20Decimals,
    "This ticket is not valid as an invoice"
  );
  await metadataService.deployed();
  console.log("MetadataServiceV1 deployed to:", metadataService.address);

  const vouchers721Factory = await ethers.getContractFactory("Vouchers721");
  const vouchers721 = <Vouchers721>(
    await vouchers721Factory.deploy(crowdtainer.address)
  );
  await vouchers721.deployed();

  console.log("Vouchers721 deployed to:", vouchers721.address);

  let arrayOfPrices = new Array<BigNumberish>();
  arrayOfPrices.push(parseUnits("120", erc20Decimals));
  arrayOfPrices.push(parseUnits("90", erc20Decimals));
  arrayOfPrices.push(parseUnits("15", erc20Decimals));
  arrayOfPrices.push(parseUnits("30", erc20Decimals));
  arrayOfPrices.push(parseUnits("140", erc20Decimals));
  arrayOfPrices.push(parseUnits("144", erc20Decimals));
  arrayOfPrices.push(parseUnits("25", erc20Decimals));
  arrayOfPrices.push(parseUnits("48", erc20Decimals));

  const currentTime = (await ethers.provider.getBlock("latest")).timestamp;

  const campaignData = {
    shippingAgent: agent.address,
    // signer: '0x0000000000000000000000000000000000000000',
    signer: "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
    openingTime: currentTime + 10,
    expireTime: currentTime + 10 + 3601 * 100,
    targetMinimum: parseUnits("1000", erc20Decimals),
    targetMaximum: parseUnits("10000000", erc20Decimals),
    unitPricePerType: arrayOfPrices,
    referralRate: 0,
    referralEligibilityValue: parseUnits("50", erc20Decimals),
    token: coin.address,
    legalContractURI: "http://example.com/terms",
  };

  await vouchers721.createCrowdtainer(
    campaignData,
    [
      "Germany Delivery | 3 Month Subscription | 500g",
      "Germany Delivery | 3 Month Subscription | 1kg",
      "Germany Delivery | Single | 500g",
      "Germany Delivery | Single | 1kg",
      "Europe Delivery | 3 Month Subscription | 500g",
      "Europe Delivery | 3 Month Subscription | 1kg",
      "Europe Delivery | Single | 500g",
      "Europe Delivery | Single | 1kg",
    ],
    metadataService.address
  );

  let crowdtainerId = (await vouchers721.crowdtainerCount()).toNumber();
  let crowdtainerAddress = await vouchers721.crowdtainerIdToAddress(
    crowdtainerId
  );

  console.log(
    `${agent.address} created a new Crowdtainer project. Id: ${crowdtainerId} @ ${crowdtainerAddress}`
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
