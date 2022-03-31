import {HardhatRuntimeEnvironment} from 'hardhat/types';
import {DeployFunction} from 'hardhat-deploy/types';
import '@nomiclabs/hardhat-ethers';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {

  const chainId = await hre.getChainId();
  const {deployer, agent, neo, trinity} = await hre.getNamedAccounts();

  const mainnetChainId = "1";
  const isMainnet = (chainId == mainnetChainId);

  if(isMainnet){
    console.warn("Mainnet configuration detected. Implementantion should use officially deployed DAI contract.");
    // TODO
    return;
  }
  
  const token = await hre.ethers.getContract("Coin");
  const vouchers721 = await hre.ethers.getContract("Vouchers721");

  await hre.run("createCrowdtainer", { /* params */ });

  console.log(`Created Crowdtainer project.`);

};

export default func;
func.tags = ['CreateCrowdtainerProject'];
