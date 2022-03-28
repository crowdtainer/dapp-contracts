import {HardhatRuntimeEnvironment} from 'hardhat/types';
import {DeployFunction} from 'hardhat-deploy/types';
// import '@nomiclabs/hardhat-ethers';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const {deployments, getNamedAccounts} = hre;
  const {deploy} = deployments;

  const chainId = await getChainId();

  const {deployer} = await getNamedAccounts();

  // TODO_NEXT
};
export default func;
func.tags = ['Coin'];
