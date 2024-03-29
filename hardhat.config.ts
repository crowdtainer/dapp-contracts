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

import "./hardhat_scripts/tasks/account";
import "./hardhat_scripts/tasks/erc20";
import "./hardhat_scripts/tasks/time";
import "./hardhat_scripts/tasks/vouchers721";
import "./hardhat_scripts/tasks/shippingAgent";

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
    agent: 0,     // shipping agent / service provider
    agentAuth: 0, // shipping agent signer (join authorizer)
    neo: 1,       // participant
    trinity: 2,   // participant
  },
  networks: {
    goerli: {
      url: nodeUrlFor("goerli"),
      accounts: privateKeysFor("goerli"),
      // gas: 2100000,
      // gasPrice: 1003244855,
      // accounts: mnemonicAccountsFor('rinkeby'),
    },
    optimism: {
      url: nodeUrlFor("optimism"),
      accounts: privateKeysFor('optimism'),
    },
    arbitrum: {
      url: nodeUrlFor("arbitrum"),
      accounts: privateKeysFor('arbitrum'),
    },
    optimismgoerli: {
      url: "https://goerli.optimism.io",
      accounts: privateKeysFor('optimismgoerli'),
    },
    localhost: {
      // saveDeployments: true,
      accounts: privateKeysFor('localhost')
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
    gasPrice: 0,
  },
};

export default config;
