<div style="text-align:center"><img src="logo.png" alt="Crowdtainer" height="128px"/>

<h1> Crowdtainer contracts repository </h1> </div>
<br/>

![Github Actions](https://github.com/crowdtainer/dapp-contracts/workflows/Tests/badge.svg)

## Functionality and design

This repository contains all solidity code related to the core functionality of crowdtainer.

```TODO: Add summary + system description link with further details.```

## Building and testing

#### Install Nix

```sh
# User must be in sudoers
curl -L https://nixos.org/nix/install | sh

# Run this or login again to use Nix
. "$HOME/.nix-profile/etc/profile.d/nix.sh"
```

#### Install DappTools

```sh
curl https://dapp.tools/install | sh
```

### Build and test 

```sh
git clone https://github.com/crowdtainer/dapp-contracts
cd dapp-contracs
make # Also installs project dependencies
make test
```


## Deploying

Contracts can be deployed via the `make deploy` command. Addresses are automatically
written in a name-address json file stored under `out/addresses.json`.

### Local Testnet

```
# To spin up a local testnet:
dapp testnet

```
Make sure ETH_FROM local environment variable is the one returned by dapp testnet above.

```
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

```
ETH_FROM=0x3538b6eF447f244268BCb2A0E1796fEE7c45002D make deploy-mainnet
```

### Rinkeby

```
ETH_FROM=0x3538b6eF447f244268BCb2A0E1796fEE7c45002D make deploy-rinkeby
```

### Custom Network

```
ETH_RPC_URL=<your network> make deploy
```
