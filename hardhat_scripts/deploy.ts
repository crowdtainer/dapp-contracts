// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";
import { BigNumberish } from "@ethersproject/bignumber/lib/bignumber";
import { parseUnits } from "ethers/lib/utils";
import { Vouchers721 } from "../out/typechain";

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


  const metadataServiceV1Factory = await ethers.getContractFactory(
    "MetadataServiceV1"
  );

  const coinFactory = await ethers.getContractFactory("Coin");
  const coin = await coinFactory.deploy("Token", "USDC", 1);
  await coin.deployed();
  const erc20Decimals = await coin.decimals();
  console.log("Coin deployed to:", crowdtainer.address);

  const metadataService = await metadataServiceV1Factory.deploy(
    "USDC",
    erc20Decimals,
    "This ticket is not valid as an invoice"
  );
  await metadataService.deployed();
  console.log("MetadataServiceV1 deployed to:", crowdtainer.address);

  const vouchers721Factory = await ethers.getContractFactory("Vouchers721");
  const vouchers721 = <Vouchers721>(await vouchers721Factory.deploy(crowdtainer.address));
  await vouchers721.deployed();

  console.log("Vouchers721 deployed to:", crowdtainer.address);

  const [agent] = await ethers.getSigners();

  let arrayOfPrices = new Array<BigNumberish>();
  arrayOfPrices.push(parseUnits('120', erc20Decimals));
  arrayOfPrices.push(parseUnits('90', erc20Decimals));
  arrayOfPrices.push(parseUnits('15', erc20Decimals));
  arrayOfPrices.push(parseUnits('30', erc20Decimals));
  arrayOfPrices.push(parseUnits('140', erc20Decimals));
  arrayOfPrices.push(parseUnits('144', erc20Decimals));
  arrayOfPrices.push(parseUnits('25', erc20Decimals));
  arrayOfPrices.push(parseUnits('48', erc20Decimals));

  const currentTime = (await ethers.provider.getBlock("latest")).timestamp;

  const campaignData = {
    shippingAgent: agent.address,
    signer: '0x0000000000000000000000000000000000000000', // 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
    openingTime: currentTime + 10,
    expireTime: currentTime + 10 + 3601 * 100,
    targetMinimum: parseUnits('1000', erc20Decimals),
    targetMaximum: parseUnits('10000000', erc20Decimals),
    unitPricePerType: arrayOfPrices,
    referralRate: 0,
    referralEligibilityValue: parseUnits('50', erc20Decimals),
    token: coin.address,
    legalContractURI: ""
  };

  await vouchers721.createCrowdtainer(
    campaignData,
    ["Germany Delivery | 3 Month Subscription | 500g",
      "Germany Delivery | 3 Month Subscription | 1kg",
      "Germany Delivery | Single | 500g",
      "Germany Delivery | Single | 1kg",
      "Europe Delivery | 3 Month Subscription | 500g",
      "Europe Delivery | 3 Month Subscription | 1kg",
      "Europe Delivery | Single | 500g",
      "Europe Delivery | Single | 1kg"],
    metadataService.address
  );

  let crowdtainerId = (await vouchers721.crowdtainerCount()).toNumber();
  let crowdtainerAddress = await vouchers721.crowdtainerIdToAddress(crowdtainerId);

  console.log(`${agent.address} created a new Crowdtainer project. Id: ${crowdtainerId} @ ${crowdtainerAddress}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
