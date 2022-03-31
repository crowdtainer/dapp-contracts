import { task } from "hardhat/config";
import "@nomiclabs/hardhat-ethers";
import "@typechain/hardhat";

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
    const token = await hre.ethers.getContract("Coin");
    const [deployer] = await hre.ethers.getSigners();
    await (await token.connect(deployer).mint(receiver, amount)).wait();
    console.log(`${deployer.address} has minted ${amount} to ${receiver}`);
  });

task("approve", "ERC-20 approve.")
  .addParam("spender", "Spender address")
  .addParam("amount", "Token amount")
  .setAction(async function ({ spender, amount }, hre) {
    const token = await hre.ethers.getContract("Coin");
    const [sender] = await hre.ethers.getSigners();
    await token.approve(spender, amount);
    console.log(
      `${sender.address} has approved ${amount} tokens to ${spender}`
    );
  });

task("transfer", "ERC-20 transfer.")
  .addParam("token", "Token address")
  .addParam("spender", "Spender address")
  .addParam("amount", "Token amount")
  .setAction(async function ({ token, spender, amount }, { ethers }) {
    const watermelonToken = await ethers.getContractFactory("WatermelonToken");
    const watermelon = watermelonToken.attach(token);
    const [minter] = await ethers.getSigners();
    await (await watermelon.connect(minter).transfer(spender, amount)).wait();
    console.log(`${minter.address} has transferred ${amount} to ${spender}`);
  });
