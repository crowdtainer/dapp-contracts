import { task } from "hardhat/config";
import "@nomiclabs/hardhat-ethers";
import { BigNumberish } from "@ethersproject/bignumber/lib/bignumber";
import { parseUnits } from "ethers/lib/utils";

task(
  "createCrowdtainer",
  "Create/initialize a new Crowdtainer project with default values."
).setAction(async function ({ _ }, { ethers }) {
  const coin = await ethers.getContract("Coin");
  const [agent] = await ethers.getSigners();

  const vouchers721 = await ethers.getContract("Vouchers721");
  const metadataService = await ethers.getContract("MetadataServiceV1");

  console.log(`MetadataServiceV1 address: ${metadataService.address}`);
  console.log(`Agent address: ${agent.address}`);
  console.log(`token address: ${coin.address}`);

  const erc20Decimals = await coin.decimals();

  let arrayOfBigNumbers: [
    BigNumberish,
    BigNumberish,
    BigNumberish,
    BigNumberish
  ];

  arrayOfBigNumbers = [parseUnits('1', erc20Decimals),
                       parseUnits('2', erc20Decimals),
                       parseUnits('3', erc20Decimals),
                       parseUnits('4', erc20Decimals)];

  const currentTime = (await ethers.provider.getBlock("latest")).timestamp;

  const campaignData = {
    shippingAgent: agent.address,
    openingTime: currentTime + 10,
    expireTime: currentTime + 10 + 3601,
    targetMinimum: parseUnits('10000', erc20Decimals),
    targetMaximum: parseUnits('10000000', erc20Decimals),
    unitPricePerType: arrayOfBigNumbers,
    referralRate: 20,
    referralEligibilityValue: parseUnits('50', erc20Decimals),
    token: coin.address,
  };

  await vouchers721.createCrowdtainer(
    campaignData,
    ["250g", "500g", "1Kg", "2Kg"],
    metadataService.address
  );

  console.log(`${agent.address} created a new Crowdtainer project.`);
});
