import { task } from "hardhat/config";
import "@nomiclabs/hardhat-ethers";
import { Crowdtainer } from "../../out/typechain/";
import { ContractTransaction } from "ethers";

task("setURLs", "Set url for CCIP-Read.")
  .addParam("url", "The first URL to be passed to the client.")
  .addParam("crowdtainerddress", "The crowdtainer address.")
  .setAction(async function ({ url, crowdtaineraddress }, hre) {
    const crowdtainer = await hre.ethers.getContract<Crowdtainer>("Crowdtainer");
    crowdtainer.attach(crowdtaineraddress);
    const [agent] = await hre.ethers.getSigners();
    let urls = new Array<string>();
    urls.push(url);
    let setUrlTx = await crowdtainer.connect(agent).setUrls(urls);
    console.log(`Waiting for transaction confirmation.. (hash ${setUrlTx.hash})`);
    setUrlTx.wait();
    console.log("setURL transaction confirmed.");
  });

task("setSigner", "Set signer public key for CCIP-Read.")
  .addParam("address", "The public key to be used for signature verification.")
  .addParam("crowdtaineraddress", "The crowdtainer address.")
  .setAction(async function ({ address, crowdtaineraddress }, hre) {
    const crowdtainerFactory = await hre.ethers.getContractFactory("Crowdtainer");
    const crowdtainer = <Crowdtainer>crowdtainerFactory.attach(crowdtaineraddress);
    const [agent] = await hre.ethers.getSigners();
    let setSignerTx = await crowdtainer.connect(agent).setSigner(address);
    console.log(`Waiting for transaction confirmation.. (hash ${setSignerTx.hash})`);
    setSignerTx.wait();
    console.log("setsetSignerURL transaction confirmed.");
  });

task("getPaidAndDeliver", "Call function to put crowdtainer state in 'delivery' mode. Requires minimum funding target to be reached.")
  .addParam("crowdtaineraddress", "The crowdtainer address.")
  .setAction(async function ({ crowdtaineraddress }, hre) {
    const crowdtainerFactory = await hre.ethers.getContractFactory("Crowdtainer");
    const crowdtainer = <Crowdtainer>crowdtainerFactory.attach(crowdtaineraddress);
    const [agent] = await hre.ethers.getSigners();
    let getPaidAndDeliverTx = await crowdtainer.connect(agent).getPaidAndDeliver();
    console.log(`Waiting for transaction confirmation.. (hash ${getPaidAndDeliverTx.hash})`);
    getPaidAndDeliverTx.wait();
    console.log("getPaidAndDeliver transaction confirmed.");
  });

task("abortProject", "Call function to put crowdtainer state in 'failed' mode.")
  .addParam("crowdtaineraddress", "The crowdtainer address.")
  .setAction(async function ({ crowdtaineraddress }, hre) {
    const crowdtainerFactory = await hre.ethers.getContractFactory("Crowdtainer");
    const crowdtainer = <Crowdtainer>crowdtainerFactory.attach(crowdtaineraddress);
    const [agent] = await hre.ethers.getSigners();
    let abortProjectTx: ContractTransaction;
    try {
      abortProjectTx = await crowdtainer.connect(agent).abortProject(); 
    } catch (error) {
      console.log(`Failed: ${error}`);
      return;
    }
    console.log(`Waiting for transaction confirmation.. (hash ${abortProjectTx.hash})`);
    abortProjectTx.wait();
    console.log("abortProject() transaction confirmed.");
  });