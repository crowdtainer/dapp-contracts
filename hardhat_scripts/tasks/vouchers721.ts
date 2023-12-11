import { task } from "hardhat/config";
import "@nomiclabs/hardhat-ethers";
import { BigNumberish } from "@ethersproject/bignumber/lib/bignumber";
import { parseUnits } from "ethers/lib/utils";
import { MockERC20, Vouchers721 } from "../../out/typechain";
import assert from "node:assert";

task(
  "createCrowdtainer",
  "Create/initialize a new Crowdtainer project with default values."
).setAction(async function ({ }, hre) {
    let { ethers } = hre;
    const coin = <MockERC20>(await ethers.getContract("MockERC20"));
    
    const { agent, agentAuth } = await hre.getNamedAccounts();
    const agentSigner = await hre.ethers.getSigner(agent);
    const agentAuthSigner = await hre.ethers.getSigner(agentAuth);

    assert(agentSigner);
    assert(agentAuthSigner);

    const vouchers721 = await ethers.getContract<Vouchers721>("Vouchers721");
    const metadataService = await ethers.getContract("MetadataServiceV1");

    console.log(`MetadataServiceV1 address: ${metadataService.address}`);
    console.log(`Agent address: ${agentSigner.address}`);
    console.log(`Agent join auth address: ${agentAuthSigner.address}`);
    console.log(`token address: ${coin.address}`);

    const erc20Decimals = await coin.decimals();

    let arrayOfPrices = new Array<BigNumberish>();

    arrayOfPrices.push(parseUnits('15', erc20Decimals));
    arrayOfPrices.push(parseUnits('30', erc20Decimals));
    arrayOfPrices.push(parseUnits('120', erc20Decimals));
    arrayOfPrices.push(parseUnits('90', erc20Decimals));
    arrayOfPrices.push(parseUnits('25', erc20Decimals));
    arrayOfPrices.push(parseUnits('48', erc20Decimals));
    arrayOfPrices.push(parseUnits('140', erc20Decimals));
    arrayOfPrices.push(parseUnits('144', erc20Decimals));

    const currentTime = (await ethers.provider.getBlock("latest")).timestamp;

    // + (5*3600)
    // + 1150*100

    const campaignData = {
      shippingAgent: agentSigner.address,
      // signer: agentAuthSigner.address, // to disable EIP-3668 use 0x0000000000000000000000000000000000000000
      signer: '0x0000000000000000000000000000000000000000',
      openingTime: currentTime + 10,
      expireTime: currentTime + 10 + 3601 * 24 * 60,
      targetMinimum: parseUnits('1000', erc20Decimals),
      targetMaximum: parseUnits('10000000', erc20Decimals),
      unitPricePerType: arrayOfPrices,
      referralRate: 20,
      referralEligibilityValue: parseUnits('0', erc20Decimals),
      token: coin.address,
      legalContractURI: "http://example.com/terms"
    };

    await vouchers721.createCrowdtainer(
      campaignData,
      ["Germany Delivery | Single | 500g",
        "Germany Delivery | Single | 1kg",
        "Germany Delivery | 3 Month Subscription | 500g",
        "Germany Delivery | 3 Month Subscription | 1kg",
        "Europe Delivery | Single | 500g",
        "Europe Delivery | Single | 1kg",
        "Europe Delivery | 3 Month Subscription | 500g",
        "Europe Delivery | 3 Month Subscription | 1kg"],
      metadataService.address
    );

    let crowdtainerId = (await vouchers721.crowdtainerCount()).toNumber();
    console.log(`Vouchers721 address: ${vouchers721.address}`);
    console.log(`Crowdtainer count: ${crowdtainerId}`);
    let crowdtainerAddress = await vouchers721.crowdtainerIdToAddress(crowdtainerId);

    console.log(`${agent} created a new Crowdtainer project. Id: ${crowdtainerId} @ ${crowdtainerAddress}`);
  });

task("join", "Join a Crowdtainer with the given parameters.")
  .addParam("user", "Named account from which the operation should be executed")
  .addParam("crowdtainerid", "Crowdtainer id")
  .addParam("quantities", "Single value used as quantity for all products")
  .setAction(async function ({ user, crowdtainerid, quantities }, hre) {

    let { ethers } = hre;
    const namedAccounts = await hre.getNamedAccounts();
    const sender = await hre.ethers.getSigner(namedAccounts[user]);

    const vouchers721 = await ethers.getContract<Vouchers721>("Vouchers721");
    let crowdtainerAddress = await vouchers721.crowdtainerIdToAddress(crowdtainerid);
    console.log(`Crowdtainer address: ${crowdtainerAddress}`);

    let quantity: BigNumberish[] = new Array<BigNumberish>();

    for (let index = 0; index < 8; index++) {
        quantity.push(quantities);
    }

    await vouchers721.connect(sender)["join(address,uint256[])"](crowdtainerAddress, quantity);

    console.log(`${sender.address} has joined crowdtainerId ${crowdtainerid}`);
  });

task("leave", "Leave the specified Crowdtainer")
  .addParam("user", "Named account from which the operation should be executed")
  .addParam("crowdtainerid", "Crowdtainer id")
  .setAction(async function ({ user, crowdtainerid }, hre) {

    let { ethers } = hre;
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