// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";
import { BigNumberish } from "@ethersproject/bignumber/lib/bignumber";
import { parseUnits } from "ethers/lib/utils";
import { MetadataServiceV1, Vouchers721 } from "../out/typechain";
import { DeployResult } from "hardhat-deploy/types.js";

const hre = require('hardhat');
const { deployments, getNamedAccounts } = hre;

// Define proper ERC20 contract / parameters.
const ERC20TokenAddress = '0x5FbDB2315678afecb367f032d93F642f64180aa3';
const ERC20Decimals = 6;
const ERC20TokenSymbol = 'USDC';

async function main() {
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  console.log({ namedAccounts: await getNamedAccounts() });

  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  // Deploy Crowdtainer
  let deployResult: DeployResult = await deploy("Crowdtainer", {
    from: deployer,
    args: [],
    log: true,
  });

  console.log(`Crowdtainer deployed at address ${deployResult.address}`);

  // Deploy ERC-721 containing tokenURI implementation
  deployResult = await deploy("MetadataServiceV1", {
    from: deployer,
    args: [ERC20TokenSymbol, ERC20Decimals, "This participation proof is not valid as an invoice."],
    log: true,
  });

  console.log(`MetadataServiceV1 deployed at address ${deployResult.address}`);

  const crowdtainerImplementation = await hre.ethers.getContract("Crowdtainer");

  // Deploy Vouchers721 - main contract for users
  deployResult = await deploy("Vouchers721", {
    from: deployer,
    args: [crowdtainerImplementation.address],
    log: true,
  });

  console.log(`Vouchers721 deployed at address ${deployResult.address}`);

  // const [agent, neo, trinity] = await ethers.getSigners();
  const [agent] = await ethers.getSigners();

  let arrayOfPrices = new Array<BigNumberish>();
  arrayOfPrices.push(parseUnits('21', ERC20Decimals));
  arrayOfPrices.push(parseUnits('33', ERC20Decimals));
  arrayOfPrices.push(parseUnits('62', ERC20Decimals));
  arrayOfPrices.push(parseUnits('63', ERC20Decimals));
  arrayOfPrices.push(parseUnits('99', ERC20Decimals));
  arrayOfPrices.push(parseUnits('186', ERC20Decimals));
  arrayOfPrices.push(parseUnits('33', ERC20Decimals));
  arrayOfPrices.push(parseUnits('46', ERC20Decimals));
  arrayOfPrices.push(parseUnits('70', ERC20Decimals));
  arrayOfPrices.push(parseUnits('99', ERC20Decimals));
  arrayOfPrices.push(parseUnits('138', ERC20Decimals));
  arrayOfPrices.push(parseUnits('210', ERC20Decimals));

  const currentTime = (await ethers.provider.getBlock("latest")).timestamp;
  const campaignData = {
    shippingAgent: agent.address,
    // signer: '0x0000000000000000000000000000000000000000',
    signer: '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266',
    openingTime: currentTime + 10,
    expireTime: currentTime + 10 + 3601 * 100,
    targetMinimum: parseUnits('1000', ERC20Decimals),
    targetMaximum: parseUnits('10000000', ERC20Decimals),
    unitPricePerType: arrayOfPrices,
    referralRate: 0,
    referralEligibilityValue: parseUnits('50', ERC20Decimals),
    token: ERC20TokenAddress,
    legalContractURI: ""
  };

  const vouchers721: Vouchers721 = await hre.ethers.getContract("Vouchers721");
  const metadataService: MetadataServiceV1 = await hre.ethers.getContract("MetadataServiceV1");

  await vouchers721.createCrowdtainer(
    campaignData,                                       // EUR / kg     USD / kg 
    ["Germany Delivery | Single | 500g",               // 37             41
      "Germany Delivery | Single | 1kg",                // 30             33
      "Germany Delivery | Single | 2kg",                // 28             31
      "Germany Delivery | 3 Month Subscription | 500g",  // 37             41
      "Germany Delivery | 3 Month Subscription | 1kg",  // 30             33
      "Germany Delivery | 3 Month Subscription | 2kg",  // 28             31
      "Europe Delivery | Single | 500g",                // 61             66
      "Europe Delivery | Single | 1kg",                 // 42             46
      "Europe Delivery | Single | 2kg",                // 32             35
      "Europe Delivery | 3 Month Subscription | 500g",  // 61             66
      "Europe Delivery | 3 Month Subscription | 1kg",   // 42             46
      "Europe Delivery | 3 Month Subscription | 2kg"],   // 32             35
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
