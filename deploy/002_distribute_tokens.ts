import {HardhatRuntimeEnvironment} from 'hardhat/types';
import {DeployFunction} from 'hardhat-deploy/types';
import '@nomiclabs/hardhat-ethers';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {

  const chainId = await hre.getChainId();
  const {neo, trinity} = await hre.getNamedAccounts();

  const mainnetChainId = "1";
  const isMainnet = (chainId == mainnetChainId);

  if(isMainnet){
    console.warn("Mainnet configuration detected, skipping Coin.sol token distribution.");
    return;
  }

  // Give some Matrix ERC20 tokens to Neo and Trinity, our simulated participants declared in hardhat.config.js
  const token = await hre.ethers.getContract("Coin");
  const symbol = await token.symbol();

  const quantity = 89898989;

  console.log(`Mint ${quantity} ${symbol} to trinity (${trinity}).`);
  await hre.run("mint", {
    receiver: trinity,
    amount: `${quantity}`
  });

  console.log(`Mint ${quantity} ${symbol} to neo (${neo}).`);
  console.log(`Give tokens to neo address: ${neo}`);
  // Give tokens to neo
  await hre.run("mint", {
    receiver: neo,
    amount: `${quantity}`
  });

};
export default func;
func.tags = ['DistributeTokens'];