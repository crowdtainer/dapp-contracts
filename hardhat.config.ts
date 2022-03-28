import * as dotenv from "dotenv";

import { HardhatUserConfig, task } from "hardhat/config";
import "@nomiclabs/hardhat-ethers";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import "solidity-coverage";
import "hardhat-deploy";
import "@nomiclabs/hardhat-ethers";
import {node_url_for, mnemonicAccountsFor, privateKeysFor} from './network_utils/network';

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
  },
  networks: {
    rinkeby: {
      url: node_url_for('rinkeby'),
      accounts: privateKeysFor('rinkeby'),
      //accounts: mnemonicAccountsFor('rinkeby'),
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
};

export default config;
