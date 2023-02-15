import { task } from "hardhat/config";
import "@nomiclabs/hardhat-ethers";
import { Crowdtainer} from "../../out/typechain/";

task("setURLs", "Set url for CCIP-Read.")
  .addParam("url", "The first URL to be passed to the client.")
  .addParam("crowdtainerddress", "The crowdtainerId.")
  .setAction(async function ({ url, crowdtaineraddress }, hre) {
    const crowdtainer = await hre.ethers.getContract<Crowdtainer>("Crowdtainer");
    crowdtainer.attach(crowdtaineraddress);
    let urls = new Array<string>();
    urls.push(url);
    let setUrlTx = await crowdtainer.setUrls(urls);
    console.log(`Waiting for transaction confirmation.. (hash ${setUrlTx.hash})`);
    setUrlTx.wait();
    console.log("setURL transaction confirmed.");
  });

task("setSigner", "Set signer public key for CCIP-Read.")
  .addParam("address", "The public key to be used for signature verification.")
  .addParam("crowdtaineraddress", "The crowdtainerId.")
  .setAction(async function ({ address, crowdtaineraddress }, hre) {
    const crowdtainerFactory = await hre.ethers.getContractFactory("Crowdtainer");
    const crowdtainer = <Crowdtainer>crowdtainerFactory.attach(crowdtaineraddress);
    let setSignerTx = await crowdtainer.setSigner(address);
    console.log(`Waiting for transaction confirmation.. (hash ${setSignerTx.hash})`);
    setSignerTx.wait();
    console.log("setsetSignerURL transaction confirmed.");
  });

task("getPaidAndDeliver", "Call function to put crowdtainer state in 'delivery' mode. Requires minimum funding target to be reached.")
  .addParam("crowdtaineraddress", "The crowdtainerId.")
  .setAction(async function ({ crowdtaineraddress }, hre) {
    const crowdtainerFactory = await hre.ethers.getContractFactory("Crowdtainer");
    const crowdtainer = <Crowdtainer>crowdtainerFactory.attach(crowdtaineraddress);
    let getPaidAndDeliverTx = await crowdtainer.getPaidAndDeliver();
    console.log(`Waiting for transaction confirmation.. (hash ${getPaidAndDeliverTx.hash})`);
    getPaidAndDeliverTx.wait();
    console.log("getPaidAndDeliver transaction confirmed.");
  });

task("abortProject", "Call function to put crowdtainer state in 'failed' mode.")
  .addParam("crowdtaineraddress", "The crowdtainer address.")
  .setAction(async function ({ crowdtaineraddress }, hre) {
    const crowdtainerFactory = await hre.ethers.getContractFactory("Crowdtainer");
    const crowdtainer = <Crowdtainer>crowdtainerFactory.attach(crowdtaineraddress);
    let abortProjectTx = await crowdtainer.abortProject();
    console.log(`Waiting for transaction confirmation.. (hash ${abortProjectTx.hash})`);
    abortProjectTx.wait();
    console.log("getPaidAndDelivery transaction confirmed.");
  });