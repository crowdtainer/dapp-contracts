import * as dotenv from "dotenv";

import { HardhatUserConfig, task } from "hardhat/config";
import "@nomiclabs/hardhat-ethers";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import "solidity-coverage";
import "hardhat-deploy";
import {node_url_for, mnemonicAccountsFor, privateKeysFor} from './network_utils/network';

import "./hardhat_scripts/tasks/erc20"
import "./hardhat_scripts/tasks/vouchers721"

dotenv.config();

const config: HardhatUserConfig = {
  paths: {
    sources: "./src/contracts",
    cache: "./out/hardhat/cache",
    artifacts: "./out/hardhat/artifacts"
  },
  solidity: "0.8.11",
  namedAccounts: {
    deployer: 0,
    neo: 1,     // participant
    trinity: 2, // participant
    agent: 3,   // agent / service provider
  },
  networks: {
    rinkeby: {
      url: node_url_for('rinkeby'),
      accounts: privateKeysFor('rinkeby'),
      //accounts: mnemonicAccountsFor('rinkeby'),
    },
    localhost: {
      gas: 2100000,
      gasPrice: 8000000000,
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
    gasPrice: 0,
  },
};

export default config;
