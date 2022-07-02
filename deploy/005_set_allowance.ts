import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import "@nomiclabs/hardhat-ethers";
import { parseUnits } from "ethers/lib/utils";
import { Crowdtainer, Vouchers721 } from "../out/typechain/";

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

  const token = await hre.ethers.getContract("Coin");
  const symbol = await token.symbol();
  const { neo, trinity } = await hre.getNamedAccounts();

  const vouchers721 = <Vouchers721>(await hre.ethers.getContract("Vouchers721"));
  const crowdtainerAddress = await vouchers721.crowdtainerIdToAddress(1);

  const crowdtainerFactory = await hre.ethers.getContractFactory("Crowdtainer");
  const crowdtainer = <Crowdtainer>crowdtainerFactory.attach(crowdtainerAddress);

  const quantity = parseUnits("100000000000", 6);

  console.log(`Approve ${quantity} ${symbol} from neo to Crowdtainer @ (${crowdtainer.address}).`);
  // Give tokens to neo
  await hre.run("approve", {
    from: neo,
    spender: crowdtainer.address,
    amount: `${quantity}`,
  });

  console.log(`Approve ${quantity} ${symbol} from trinity to Crowdtainer @ (${crowdtainer.address}).`);
  // Give tokens to neo
  await hre.run("approve", {
    from: trinity,
    spender: crowdtainer.address,
    amount: `${quantity}`,
  });

};

export default func;
func.tags = ["CreateCrowdtainerProject"];
