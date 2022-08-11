import * as dotenv from "dotenv";

import { HardhatUserConfig} from "hardhat/types";
import "@nomiclabs/hardhat-ethers";
import "hardhat-gas-reporter";
import "solidity-coverage";

import "hardhat-deploy";
import {
  nodeUrlFor,
  /* mnemonicAccountsFor, */
  privateKeysFor,
} from "./network_utils/network";

import "./hardhat_scripts/tasks/erc20";
import "./hardhat_scripts/tasks/time";
import "./hardhat_scripts/tasks/vouchers721";

dotenv.config();

const config: HardhatUserConfig = {
  paths: {
    sources: "./src/contracts",
    cache: "./out/hardhat/cache",
    artifacts: "./out/hardhat/artifacts",
  },
  solidity: {
    version: "0.8.16",
    settings: {
      optimizer: {
        enabled: true,
        runs: 100
      }
    }
  },
  namedAccounts: {
    deployer: 0,
    neo: 1, // participant
    trinity: 2, // participant
    agent: 0, // agent / service provider
  },
  networks: {
    // for mainnet
    // optimism: {
    //   url: "https://mainnet.optimism.io",
    //   accounts: privateKeysFor('optimismmainnet'),
    // },
    // Testnets
    rinkeby: {
      url: nodeUrlFor("rinkeby"),
      accounts: privateKeysFor("rinkeby"),
      // gas: 2100000,
      // gasPrice: 1003244855,
      // accounts: mnemonicAccountsFor('rinkeby'),
    },
    optimismgoerli: {
      url: "https://goerli.optimism.io",
      accounts: privateKeysFor('optimismgoerli'),
    },
    localhost: {
      gas: 2100000,
      gasPrice: 8000000000,
    },
    // hardhat: {
    //   allowUnlimitedContractSize: true
    // },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
    gasPrice: 0,
  },
};

export default config;
