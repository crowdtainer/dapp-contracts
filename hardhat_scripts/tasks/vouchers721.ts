import { task } from "hardhat/config";
import "@nomiclabs/hardhat-ethers";
import "@typechain/hardhat";
// import {} from "../../typechain/Vouchers721";

task("createCrowdtainer", "Create/initialize a new Crowdtainer project with default values.")
    .setAction(async function ({ _ }, { ethers }) {

        const token = await ethers.getContract("Coin");
        const [agent] = await ethers.getSigners();

        const vouchers721 = await ethers.getContract("Vouchers721");
        const metadataService = await ethers.getContract("MetadataServiceV1");

        console.log(`MetadataServiceV1 address: ${metadataService.address}`);
        console.log(`Agent address: ${agent.address}`);
        console.log(`token address: ${token.address}`);

        //  Vouchers721.initialize() params:
        //  - CampaignData,
        //  - string array of product descriptions,
        //  - ERC721 tokenUri implementation contract address

        let campaignData = {
            shippingAgent: agent.address,
            openingTime: 1,
            expireTime: 2,
            targetMinimum: 100,
            targetMaximum: 10000,
            unitPricePerType: [
              1,
              2,
              3,
              4
            ],
            referralRate: 20,
            referralEligibilityValue: 50,
            token: token.address
          };

        await vouchers721.createCrowdtainer(campaignData,
            ["","","",""],
            metadataService.address);

        console.log(`${agent.address} created a new Crowdtainer project.`);

});