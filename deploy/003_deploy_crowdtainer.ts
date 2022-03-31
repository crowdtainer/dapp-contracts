import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import "@nomiclabs/hardhat-ethers";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deploy } = hre.deployments;
  const { deployer } = await hre.getNamedAccounts();

  const token = await hre.ethers.getContract("Coin");
  const symbol = await token.symbol();

  // Deploy Crowdtainer
  await deploy("Crowdtainer", {
    from: deployer,
    args: [],
    log: true,
  });

  // Deploy ERC-721 containing tokenURI implementation
  await deploy("MetadataServiceV1", {
    from: deployer,
    args: [symbol, "This ticket is not valid as an invoice."],
    log: true,
  });

  const crowdtainerImplementation = await hre.ethers.getContract("Crowdtainer");

  // Deploy Vouchers721 - main contract for users
  await deploy("Vouchers721", {
    from: deployer,
    args: [crowdtainerImplementation.address],
    log: true,
  });
};

export default func;
func.tags = ["DeployCrowdtainer"];
