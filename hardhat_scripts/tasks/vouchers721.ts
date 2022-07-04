import { task } from "hardhat/config";
import "@nomiclabs/hardhat-ethers";
import { BigNumberish } from "@ethersproject/bignumber/lib/bignumber";
import { parseUnits } from "ethers/lib/utils";
import { Coin, Vouchers721 } from "../../out/typechain/";

task(
  "createCrowdtainer",
  "Create/initialize a new Crowdtainer project with default values."
).setAction(async function ({ _ }, hre) {
  let { ethers } = hre;
  const coin = <Coin>(await ethers.getContract("Coin"));

  const namedAccounts = await hre.getNamedAccounts();
  const agent = await ethers.getSigner(namedAccounts['agent']);

  const vouchers721 = await ethers.getContract<Vouchers721>("Vouchers721");
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

  arrayOfBigNumbers = [parseUnits('10', erc20Decimals),
                       parseUnits('20', erc20Decimals),
                       parseUnits('30', erc20Decimals),
                       parseUnits('40', erc20Decimals)];

  const currentTime = (await ethers.provider.getBlock("latest")).timestamp;

  // + (5*3600)

  const campaignData = {
    shippingAgent: agent.address,
    openingTime: currentTime + 30,
    expireTime: currentTime + 3600 * 5,
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

  let crowdtainerId = (await vouchers721.crowdtainerCount()).toNumber();
  let crowdtainerAddress = await vouchers721.crowdtainerIdToAddress(crowdtainerId);

  console.log(`${agent.address} created a new Crowdtainer project. Id: ${crowdtainerId} @ ${crowdtainerAddress}`);
});

task("join", "Join a Crowdtainer with the given parameters.")
  .addParam("user", "Named account from which the operation should be executed")
  .addParam("crowdtainerid", "Crowdtainer id")
  .addParam("quantities", "Single value used as quantity for all products")
  .setAction(async function ({ user, crowdtainerid, quantities }, hre) {

    let {ethers} = hre;
    const namedAccounts = await hre.getNamedAccounts();
    const sender = await hre.ethers.getSigner(namedAccounts[user]);

    const vouchers721 = await ethers.getContract<Vouchers721>("Vouchers721");
    let crowdtainerAddress = await vouchers721.crowdtainerIdToAddress(crowdtainerid);
    console.log(`Crowdtainer address: ${crowdtainerAddress}`);

    let quantity: [BigNumberish,BigNumberish,BigNumberish,BigNumberish]= [quantities, quantities, quantities, quantities];
    await vouchers721.connect(sender).join(crowdtainerAddress, quantity, false, '0x0000000000000000000000000000000000000000');

    console.log(`${sender.address} has joined crowdtainerId ${crowdtainerid}`);
  });

  task("leave", "Leave the specified Crowdtainer")
  .addParam("user", "Named account from which the operation should be executed")
  .addParam("crowdtainerid", "Crowdtainer id")
  .setAction(async function ({ user, crowdtainerid }, hre) {

    let {ethers} = hre;
    const namedAccounts = await hre.getNamedAccounts();
    const sender = await hre.ethers.getSigner(namedAccounts[user]);

    const vouchers721 = await ethers.getContract<Vouchers721>("Vouchers721");
    let crowdtainerAddress = await vouchers721.crowdtainerIdToAddress(crowdtainerid);
    console.log(`Crowdtainer address: ${crowdtainerAddress}`);

    let tokenId = await vouchers721.connect(sender).tokenOfOwnerByIndex(sender.address, 0);
    console.log(`Found tokenId: ${tokenId}`);

    await vouchers721.connect(sender).leave(tokenId);

    console.log(`${sender.address} has left crowdtainerId ${crowdtainerid}`);
  });