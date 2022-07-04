import { task } from "hardhat/config";
import "@nomiclabs/hardhat-ethers";

task(
  "timetravel",
  "Move forward in time"
)
  .addParam("seconds", "Move forward in time.")
  .setAction(async function ({ seconds }, hre) {
  let { ethers } = hre;

  await ethers.provider.send("evm_increaseTime",[Number(seconds)]);
  await ethers.provider.send("evm_mine",[]);

  console.log(`Moved forwards ${seconds} seconds.`);
});