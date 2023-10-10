import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import "@nomiclabs/hardhat-ethers";
import { parseUnits } from "ethers/lib/utils";
import { Crowdtainer, Vouchers721, MockERC20 } from "../out/typechain/";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const chainId = await hre.getChainId();
  const { agent } = await hre.getNamedAccounts();

  const mainnetChainId = "1";
  const isMainnet = chainId === mainnetChainId;

  if (isMainnet) {
    console.warn(
      "Mainnet configuration detected. Implementantion should use officially deployed DAI contract."
    );
    // TODO
    return;
  }

  const token = await hre.ethers.getContract<MockERC20>("MockERC20");
  const symbol = await token.symbol();
  const { neo, trinity } = await hre.getNamedAccounts();

  const vouchers721 = <Vouchers721>(await hre.ethers.getContract("Vouchers721"));
  const crowdtainerAddress = await vouchers721.crowdtainerIdToAddress(1);

  const quantity = parseUnits("10000", await token.decimals());
  console.log(`Approve ${quantity} ${symbol} from neo to Crowdtainer @ (${crowdtainerAddress}).`);
  
  // Give allowance to neo
  await hre.run("approve", {
    from: neo,
    spender: crowdtainerAddress,
    amount: `${quantity}`,
  });

  console.log(`Approve ${quantity} ${symbol} from trinity to Crowdtainer @ (${crowdtainerAddress}).`);
  // Give allowance to trinity
  await hre.run("approve", {
    from: trinity,
    spender: crowdtainerAddress,
    amount: `${quantity}`,
  });

};

export default func;
func.tags = ["CreateCrowdtainerProject"];
