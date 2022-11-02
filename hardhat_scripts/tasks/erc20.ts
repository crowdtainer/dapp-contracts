import { task } from "hardhat/config";
import { Coin } from "../../out/typechain/";

task("accounts", "Prints the list of accounts.", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();
  for (const account of accounts) {
    console.log(account.address);
  }
});

task(
  "blockNumber",
  "Prints the current block number.",
  async (_, { ethers }) => {
    await ethers.provider.getBlockNumber().then((blockNumber) => {
      console.log("Current block number: " + blockNumber);
    });
  }
);

task("totalSupply", "Total supply of the ERC-20 token.").setAction(
  async function (_, hre) {
    console.log(`ChainId: ${await hre.getChainId()}`);
    const token = await hre.ethers.getContract("Coin");
    const supply = await token.totalSupply();
    const tokenSymbol = await token.symbol();
    console.log(
      `ERC-20 contract has a total supply of:  ${supply} ${tokenSymbol}`
    );
  }
);

task("balanceOf", "Total balance of ERC-20 token for a given account.")
  .addParam("account", "Account address")
  .setAction(async function ({ account }, hre) {
    console.log(`ChainId: ${await hre.getChainId()}`);
    const token = await hre.ethers.getContract("Coin");
    const balance = await token.balanceOf(account);
    const tokenSymbol = await token.symbol();
    console.log(
      `Account ${account} has a total token balance:  ${balance} ${tokenSymbol}`
    );
  });

task("mint", "ERC-20 mint.")
  .addParam("receiver", "Receiver address")
  .addParam("amount", "Token amount")
  .setAction(async function ({ receiver, amount }, hre) {
    const token = await hre.ethers.getContract<Coin>("Coin");
    const [deployer] = await hre.ethers.getSigners();
    await (await token.connect(deployer).mint(receiver, amount)).wait();

    const supply = await token.totalSupply();
    const symbol = await token.symbol();
    console.log(`${deployer.address} has minted ${amount} to ${receiver}. Current supply of ${supply} ${symbol}.`);
  });

task("approve", "ERC-20 approve.")
  .addParam("from", "Named account allowing spending (from hardhat.config)")
  .addParam("spender", "Spender address")
  .addParam("amount", "Token amount")
  .setAction(async function ({  from, spender, amount }, hre) {
    const token = await hre.ethers.getContract<Coin>("Coin");
    const sender = await hre.ethers.getSigner(from);

    console.log(`Gas price: ${await sender.getGasPrice()}`);

    await (await token.connect(sender).approve(spender, amount)).wait();
    console.log(
      `${sender.address} has approved ${amount} tokens to ${spender}`
    );
  });