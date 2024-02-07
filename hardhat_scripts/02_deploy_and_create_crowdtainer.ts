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
import { ContractTransaction } from "ethers";

// This script can be used to perform a deployment, either against localhost or a real network, while
// reusing any previous deployments when possible (note usage of 'deployments' from hre hardhat-deploy plugin).

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
  const { deployer, agent } = await getNamedAccounts();
  const deployerSigner = await hre.ethers.getSigner(deployer);
  const agentSigner = await hre.ethers.getSigner(agent);

  // Deploy Crowdtainer
  let deployResult: DeployResult = await deploy("Crowdtainer", {
    from: deployer,
    args: [],
    log: true,
  });

  // Uncomment to test with mocked token
  // const coinFactory = await ethers.getContractFactory("MockERC20");
  // const coin = await coinFactory.deploy("FakeERC20", "USDC", 6);
  // await coin.deployed();
  // const erc20Decimals = await coin.decimals();
  // console.log("Coin deployed to:", coin.address);
  // console.log("Coin symbol:", await coin.symbol());
  // console.log("Coin decimals:", erc20Decimals);

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
  const campaignDurationInDays = 42;
  const campaignData = {
    shippingAgent: agentSigner.address,
    signer: '0x0000000000000000000000000000000000000000', // address(0) means no off-chain authorization required.
    // signer: agentSigner.address
    openingTime: currentTime + 10,
    expireTime: currentTime + 60 * 60 * 24 * campaignDurationInDays,
    targetMinimum: parseUnits('35000', ERC20Decimals),
    targetMaximum: parseUnits('100000', ERC20Decimals),
    unitPricePerType: arrayOfPrices,
    referralRate: 20,
    referralEligibilityValue: parseUnits('50', ERC20Decimals),
    // token: coin.address, // mocked token
    token: ERC20TokenAddress,
    legalContractURI: "http://example.com/terms"
  };

  const vouchers721: Vouchers721 = await hre.ethers.getContract("Vouchers721");
  const metadataService: MetadataServiceV1 = await hre.ethers.getContract("MetadataServiceV1");

  let txResult: ContractTransaction | undefined;

  try {
    txResult = await vouchers721.connect(deployerSigner).createCrowdtainer(
      campaignData,                                       // EUR / kg     USD / kg
      ["Germany Delivery | Single | 500g",                // 37             41
        "Germany Delivery | Single | 1kg",                // 30             33
        "Germany Delivery | Single | 2kg",                // 28             31
        "Germany Delivery | 3 Month Subscription | 500g", // 37             41
        "Germany Delivery | 3 Month Subscription | 1kg",  // 30             33
        "Germany Delivery | 3 Month Subscription | 2kg",  // 28             31
        "Europe Delivery | Single | 500g",                // 61             66
        "Europe Delivery | Single | 1kg",                 // 42             46
        "Europe Delivery | Single | 2kg",                 // 32             35
        "Europe Delivery | 3 Month Subscription | 500g",  // 61             66
        "Europe Delivery | 3 Month Subscription | 1kg",   // 42             46
        "Europe Delivery | 3 Month Subscription | 2kg"],  // 32             35
      metadataService.address
    );
  } catch (error) {
    console.log(`Error creating campaign: ${error}`);
    return;
  }

  let numberOfDeployedCampaigns = await vouchers721.crowdtainerCount();
  console.log(`TxResult: ${txResult?.hash} Detected ${numberOfDeployedCampaigns} campaign(s).`);

  let crowdtainerId = (numberOfDeployedCampaigns).toNumber();
  let crowdtainerAddress = await vouchers721.crowdtainerIdToAddress(crowdtainerId);

  console.log(`${agentSigner.address} created a new Crowdtainer project. Id: ${crowdtainerId} @ ${crowdtainerAddress}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
