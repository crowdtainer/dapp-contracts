import { task } from "hardhat/config";

task("setNonce", "Modifies an account's nonce by overwriting it.")
  .addParam("account", "Account address")
  .addParam("nonce", "nonce in hex; E.g.: 0x21")
  .setAction(async function ({ account, nonce }, hre) {
    console.log(`ChainId: ${await hre.getChainId()}`);
    let result = await hre.network.provider.send("hardhat_setNonce", [
      account,
      nonce
    ]);
    console.dir(result);
  });