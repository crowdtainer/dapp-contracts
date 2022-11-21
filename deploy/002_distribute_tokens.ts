import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import "@nomiclabs/hardhat-ethers";
import { parseUnits } from "ethers/lib/utils";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const chainId = await hre.getChainId();
  const namedAccounts = await hre.getNamedAccounts();
  console.log("Accounts available:", namedAccounts);

  const { agent, neo, trinity } = namedAccounts;

  const mainnetChainId = "1";
  const isMainnet = chainId === mainnetChainId;

  if (isMainnet) {
    console.warn(
      "Mainnet configuration detected, skipping Coin.sol token distribution."
    );
    return;
  }

  // Give some Matrix ERC20 tokens to Neo and Trinity, our simulated participants declared in hardhat.config.js
  const token = await hre.ethers.getContract("Coin");
  const symbol = await token.symbol();

  const quantity = parseUnits("10000", 6);

  console.log(`Mint ${quantity} ${symbol} to trinity (${trinity}).`);
  await hre.run("mint", {
    receiver: trinity,
    amount: `${quantity}`,
  });

  console.log(`Mint ${quantity} ${symbol} to neo (${neo}).`);
  console.log(`Give tokens to neo address: ${neo}`);
  // Give tokens to neo
  await hre.run("mint", {
    receiver: neo,
    amount: `${quantity}`,
  });

  console.log(`Mint ${quantity} ${symbol} to agent (${agent}).`);
  console.log(`Give tokens to neo address: ${agent}`);
  // Give tokens to neo
  await hre.run("mint", {
    receiver: agent,
    amount: `${quantity}`,
  });

};
export default func;
func.tags = ["DistributeTokens"];
