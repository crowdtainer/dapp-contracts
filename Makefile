# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

install: solc update npm

# dapp deps
update:; dapp update

# npm deps for linting etc.
npm:; yarn install

# install solc version
# example to install other versions: `make solc 0_8_2`
SOLC_VERSION := 0_8_16
solc:; nix-env -f https://github.com/dapphub/dapptools/archive/master.tar.gz -iA solc-static-versions.solc_${SOLC_VERSION}

# Build & test
build  		:; dapp build
test   		:; dapp test # --ffi # enable if you need the `ffi` cheat code on HEVM
coverage   	:; dapp test --coverage --cov-match Crowdtainer.sol
coverage2 	:; dapp test --coverage --cov-match Vouchers721.sol
clean  		:; dapp clean
lint   		:; yarn run lint
estimate 	:; ./scripts/estimate-gas.sh ${contract}
size   		:; ./scripts/contract-size.sh ${contract}

# Deployment helpers
deploy :; @./scripts/deploy.sh

# mainnet
deploy-mainnet: export NETWORK=mainnet
deploy-mainnet: export ETH_RPC_URL=https://eth-${NETWORK}.alchemyapi.io/v2/${ALCHEMY_API_KEY}
deploy-mainnet: check-api-key deploy

# rinkeby
deploy-rinkeby: export NETWORK=rinkeby
deploy-rinkeby: export ETH_RPC_URL=https://eth-${NETWORK}.alchemyapi.io/v2/${ALCHEMY_API_KEY}
deploy-rinkeby: check-api-key deploy

deploy-localhost: export NETWORK=localhost
deploy-localhost: export ETH_RPC_URL=http://127.0.0.1:8545
deploy-localhost: deploy

check-api-key:
ifndef ALCHEMY_API_KEY
	$(error ALCHEMY_API_KEY is undefined)
endif

solcheck:; solc src/Crowdtainer.sol --model-checker-targets constantCondition,divByZero,balance,assert,popEmptyArray,outOfBounds --model-checker-show-unproved --model-checker-timeout 100 --model-checker-engine chc
