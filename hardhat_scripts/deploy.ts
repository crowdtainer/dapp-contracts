// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";

async function main() {
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // Deploy contracts
  // Crowdtainer
  const Crowdtainer = await ethers.getContractFactory("Crowdtainer");
  const crowdtainer = await Crowdtainer.deploy();
  await crowdtainer.deployed();
  console.log("Crowdtainer deployed to:", crowdtainer.address);

  const MetadataServiceV1 = await ethers.getContractFactory("MetadataServiceV1");
  const metadataService = await MetadataServiceV1.deploy("DAI", "This ticket is not valid as an invoice");
  await metadataService.deployed();
  console.log("MetadataServiceV1 deployed to:", crowdtainer.address);

  const Vouchers721 = await ethers.getContractFactory("Vouchers721");
  const vouchers721 = await Vouchers721.deploy(crowdtainer.address);
  await vouchers721.deployed();

  console.log("Vouchers721 deployed to:", crowdtainer.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
