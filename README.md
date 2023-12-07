<div align="center"><img src="docs/CrowdtainerLogo.svg" alt="Crowdtainer" height="128px"/>

<h1>Crowdtainer Solidity smart contracts</h1>

<br />

![Github Actions](https://github.com/crowdtainer/dapp-contracts/workflows/Tests/badge.svg)

</div>

This repository contains all the solidity code related to the core functionality of Crowdtainer.

There are currently three different tools that are able to build & execute tests in this repository: DappTools, Foundry and Hardhat.

- Foundry: Fast execution of solidity unit tests.
- Dapp.tools: Solidity tests with Formal Verification, local test network, and deployment scripts.
- Hardhat:
  - Scripts and utilities used to deploy, initialize, and interact a Crowdtainer project.
  - Easy to run test network (local), useful for frontend development.

## Functionality and design

- [`Crowdtainer smart contracts system description`](./docs/SystemDescription.md)
- [`User Stories`](./docs/UserStories.md)

## Community

Come hang on our [discord](https://discord.gg/D6FrwCfKAP) ✨

## Contributing

Foundry is our recommended for getting started with Solidity development, since it is easier to install, and faster to execute tests with. However, it is not yet as feature complete as DappTools, namely, it doesn't support formal verification (yet). Scripts such as `make test` depend on DappTools. However it is generally possible to execute the unit tests with `forge test`, as we strive to keep compatibility.

## Directory Structure

<pre>
root
├── <a href="./deploy">deploy:</a> Hardhat deployment tasks.
├── <a href="./deployments">deployments:</a> Existing deployments artifacts.
├── <a href="./src">src/</a>
│   ├── <a href="./src/contracts">contracts</a>: Crowdtainer's Solidity source code.
│   └── <a href="./src/test">test</a>: Solidity tests. Used by Foundry and Dapp.tools.
├── <a href="./docs">docs:</a> Documentation and user stories.
├── <a href="./lib">lib</a>: Solidity libraries / remappings (git submodules).
├── <a href="./scripts">scripts</a>: Scripts used by Makefile. Entry points for dapp.tools.
└── <a href="./hardhat_scripts">hardhat_scripts</a>: Deploy & interact with contracts.
</pre>

# Security Policy and Vulnerability Reporting

Please refer to [Security Policy](https://github.com/crowdtainer/dapp-contracts/.github/blob/master/SECURITY.md) for detailed information about how to report vulnerabilities in this codebase.

# Installing dependencies

`Note: Below are instructions to have all three workflows available (Foundry, Dapp.tools and Hardhat). However, one workflow does not depend on the tools required by the other. Frontend development may be interested only in getting a local network running with contracts and therefore only install node/Hardhat.`

## Hardhat installation

- Prerequisite: node

```sh
# Install yarn
npm install --global yarn

# Install Solidity compiler:
See instructions at https://docs.soliditylang.org/en/v0.8.16/installing-solidity.html

# Install Crowdtainer node project dependencies
yarn install
```

## Foundry installation

```sh
curl -L https://foundry.paradigm.xyz | bash

# Reload your terminal enviroment variables, e.g.:
source ~/.zshrc

foundryup

# MacOS might also require:
brew install libusb
```

## Nix (only required for Dapp tools)

```sh
# Nix for Linux users:
sh <(curl -L https://nixos.org/nix/install) --daemon

# Nix for MacOs users:
sh <(curl -L https://nixos.org/nix/install)

# Run this or login again to use Nix
. "$HOME/.nix-profile/etc/profile.d/nix.sh"

# For MacOS users:
sh <(curl -L https://nixos.org/nix/install) --darwin-use-unencrypted-nix-store-volume --daemon
# In case of MacOS arm (M1) issues, you may want to run everything under Rosetta.
vi ~/.config/nix/nix.conf
# set:
system = x86_64-darwin
nix-env -iA ghc -f $(curl -sS https://api.github.com/repos/dapphub/dapptools/releases/latest | jq -r .tarball_url)

# Then, restart your terminal/shell session to make the installation effective.
```

## Install DappTools

```sh
curl https://dapp.tools/install | sh
```

# Building and testing

## Hardhat

```sh
# Important (required for npx hardhat compile):
yarn build # generates smartcontract <-> typescript bindings with typechain

npx hardhat # show all available tasks
```

Important: With `npx hardhat node` running in a separate terminal, in order to use
tasks to e.g. manually interact with the contract state, hardhat requires specifying the network:

```sh
// A few examples:

// To create a new crowdtainer:
npx hardhat createCrowdtainer --network localhost --agent 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
// where the last parameter is the address of the agent/service provider address

// Alternatively, to create a new crowdtainer via "hardhat-deploy script":
npx hardhat run hardhat_scripts/02_deploy_and_create_crowdtainer.ts --network localhost

// To make a user join a crowdtainer project:
npx hardhat join --user neo --crowdtainerid 1 --quantities 200 --network localhost

// To fast forward in time:
npx hardhat timetravel --seconds 2000

// Service providing accepting funds and committing to delivery:
npx hardhat getPaidAndDeliver --crowdtaineraddress 0x3B02fF1e626Ed7a8fd6eC5299e2C54e1421B626B --network localhost
```

Copy the `.env.example` file to `.env`.

### Local instance + deployment

```sh
# Run a simulated Ethereum blockchain locally and deploy contracts:
# (scripts under deploy/*.ts are executed sequentially)
npx hardhat node
```

To deploy to a specific network:

```sh
# (See hardhat.config.ts for available networks)
npx hardhat deploy --network <network_name> # e.g. rinkeby
```

### Useful commands

```sh
npx hardhat accounts
npx hardhat compile
npx hardhat clean
# To deploy all contracts + Crowdtainer instance to some other node (local or remote):
npx hardhat run hardhat_scripts/deploy_with_mocked_token.ts --network localhost
# TS_NODE_FILES=true npx ts-node scripts/deploy.ts
npx eslint '**/*.{js,ts}'
npx eslint '**/*.{js,ts}' --fix
npx prettier '**/*.{json,sol,md}' --check
npx prettier '**/*.{json,sol,md}' --write
npx solhint 'contracts/**/*.sol'
npx solhint 'contracts/**/*.sol' --fix
# Debug function with specific parameters; Eg.:
forge run src/test/Join.t.sol -t JoinFuzzer --sig "testInvariantsHold(uint256,uint256,uint256)" --debug 0 0 0
# Debugger for tests; E.g.:
forge debug src/test/Leave.t.sol --tc CrowdtainerValidLeaveTester --sig "testJoinThenLeaveWithoutReferralsMustSucceed()"
# Code coverage with Foundry: forge coverage --report lcov (then with e.g. VSCode's Coverage Gutters plugin -> Shift + CMD + 7 to load/display lcov)
```

## Solidity code development

```sh
git clone --recursive https://github.com/crowdtainer/dapp-contracts
cd dapp-contracs
make         # Also installs project dependencies

# To run dapp-tools based tests (Unit testing, Fuzz and Symbolic):
make test

# To see unit test code coverage:
make coverage

# To run Solidity' SMTChecker-based tests:
make solcheck
```

### Estimation of gas costs:

With dapp.tools:
- First run a local testnet with `dapp testnet`.
- Then run e.g.: `make contract=Crowdtainer estimate`

With Foundry:
- forge test --gas-report

### Contract size estimation:
- Example: `make contract=Vouchers721 size`

### To apply linter (Solidity only):

```sh
make lint
```

## Dapp.tools

Contracts can be deployed via the `make deploy` command. Addresses are automatically
written in a name-address json file stored under `out/addresses.json`. Additionally, you can specify a specific network with `make deploy-rinkeby` or `make deploy-mainnet`. You can choose which contract you want to deploy, by adding it as a variable, e.g.:

```sh
make deploy-rinkeby CONTRACT=Crowdtainer
```

### Local Testnet

```sh
# To spin up a local testnet:
dapp testnet
```

Make sure ETH_FROM is set according to the address returned by dapp testnet above in `.dapprc` file.

```sh
# Then in a second terminal:
make deploy
```

### Local deploy test

[`scripts/test-deploy.sh`](./scripts/test-deploy.sh) will launch a local testnet, deploy the contracts, and do some sanity checks.

Environment variables under the `.env` file are automatically loaded (see [`.env.example`](./.env.example)).
Be careful of the [precedence in which env vars are read](https://github.com/dapphub/dapptools/tree/2cf441052489625f8635bc69eb4842f0124f08e4/src/dapp#precedence).

We assume `ETH_FROM` is an address you own and is part of your keystore.
If not, use `ethsign import` to import your private key.

We use Alchemy as a remote node provider for the Mainnet & Rinkeby network deployments.
You must have set your API key as the `ALCHEMY_API_KEY` enviroment variable in order to
deploy to these networks

### Mainnet

```sh
ETH_FROM=0x3538b6eF447f244268BCb2A0E1796fEE7c45002D make deploy-mainnet
```

### Rinkeby

```sh
ETH_FROM=0x3538b6eF447f244268BCb2A0E1796fEE7c45002D make deploy-rinkeby
```

### Custom Network

```sh
ETH_RPC_URL=<your network> make deploy
```
