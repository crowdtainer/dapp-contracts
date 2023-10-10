import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import "@nomiclabs/hardhat-ethers";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deploy } = hre.deployments;
  const chainId = await hre.getChainId();
  const { deployer } = await hre.getNamedAccounts();

  const mainnetChainId = "1";
  const isMainnet = chainId === mainnetChainId;

  console.log(`Current chainId: ${chainId}`);

  if (isMainnet) {
    console.warn(
      "Mainnet configuration detected, skipping MockERC20.sol contract deployment."
    );
    return;
  }

  // Deploy MockERC20.sol, a fake ERC20 contract for testing purposes.
  await deploy("MockERC20", {
    from: deployer,
    args: ["FakeERC20", "USDC", 6],
    log: true,
  });

  const token = await hre.ethers.getContract("MockERC20");
  const supply = await token.totalSupply();
  const symbol = await token.symbol();
  console.log(
    `MockERC20 deployed at: ${token.address}. Current supply of ${supply} ${symbol}`
  );
};

export default func;

func.tags = ["DeployFakeCoin"];
