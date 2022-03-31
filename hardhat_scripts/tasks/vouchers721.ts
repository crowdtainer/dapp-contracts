import { task } from "hardhat/config";
import "@nomiclabs/hardhat-ethers";
import { BigNumberish } from "@ethersproject/bignumber/lib/bignumber";
import { parseUnits } from "ethers/lib/utils";

task(
  "createCrowdtainer",
  "Create/initialize a new Crowdtainer project with default values."
).setAction(async function ({ _ }, { ethers }) {
  const token = await ethers.getContract("Coin");
  const [agent] = await ethers.getSigners();

  const vouchers721 = await ethers.getContract("Vouchers721");
  const metadataService = await ethers.getContract("MetadataServiceV1");

  console.log(`MetadataServiceV1 address: ${metadataService.address}`);
  console.log(`Agent address: ${agent.address}`);
  console.log(`token address: ${token.address}`);

  let arrayOfBigNumbers: [
    BigNumberish,
    BigNumberish,
    BigNumberish,
    BigNumberish
  ];
  arrayOfBigNumbers = [1, 2, 3, 4];

  const currentTime = (await ethers.provider.getBlock("latest")).timestamp;
  const erc20Decimals = await token.decimals();

  const campaignData = {
    shippingAgent: agent.address,
    openingTime: currentTime + 10,
    expireTime: currentTime + 10 + 3601,
    targetMinimum: parseUnits("10000", erc20Decimals),
    targetMaximum: parseUnits("10000000", erc20Decimals),
    unitPricePerType: arrayOfBigNumbers,
    referralRate: 20,
    referralEligibilityValue: parseUnits("50", erc20Decimals),
    token: token.address,
  };

  await vouchers721.createCrowdtainer(
    campaignData,
    ["250g", "500g", "1Kg", "2Kg"],
    metadataService.address
  );

  console.log(`${agent.address} created a new Crowdtainer project.`);
});
