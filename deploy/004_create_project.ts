import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import "@nomiclabs/hardhat-ethers";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const chainId = await hre.getChainId();
  const { agent } = await hre.getNamedAccounts();

  console.log("Detected accounts: ", await hre.getNamedAccounts());

  const mainnetChainId = "1";
  const isMainnet = chainId === mainnetChainId;

  if (isMainnet) {
    console.warn(
      "Mainnet configuration detected. Implementantion should use officially deployed DAI contract."
    );
    // TODO
    return;
  }

  await hre.run("createCrowdtainer", {
    agent: agent
  });
};

export default func;
func.tags = ["CreateCrowdtainerProject"];
