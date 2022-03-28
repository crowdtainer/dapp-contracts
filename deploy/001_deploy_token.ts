import {HardhatRuntimeEnvironment} from 'hardhat/types';
import {DeployFunction} from 'hardhat-deploy/types';
// import '@nomiclabs/hardhat-ethers';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const {deployments, getNamedAccounts} = hre;
  const {deploy} = deployments;

  const {deployer} = await getNamedAccounts();

  await deploy('Coin', {
    from: deployer,
    args: ["FakeERC20", "TST", 1],
    log: true,
  });
};
export default func;
func.tags = ['Coin'];
