#!/usr/bin/env bash

set -eo pipefail

# import the deployment helpers
. $(dirname $0)/common.sh

# import config with arguments based on contract and network
. $(dirname $0)/helper-config.sh

lastAddress="0x0"

function deployContract() {
    local network=$1
    local contractName=$2
    shift;
    shift;

    if [[ -z ${network+x} ]]; then echo "Error: network not specified."; exit 1; fi
    if [[ -z ${contractName+x} ]]; then echo "Error: contract not specified."; exit 1; fi

    log "Deploying $contractName to $network with arguments: $@"

    lastAddress=$(deploy $contractName "$@")
    log "$contractName deployed at address: $lastAddress"
}

START_ETH_BALANCE=$(seth balance $ETH_FROM)

# Deploy Crowdtainer.
contractName=Crowdtainer
deployContract $NETWORK Crowdtainer
crowdtainerAddress=$lastAddress

# Deploy MetadataServiceV1
deployContract $NETWORK MetadataServiceV1 '"DAI"' '"This ticket is not valid as an invoice."'

# Deploy Vouchers721; Params: reference of Crowdtainer implementation
contractName=Vouchers721
deployContract $NETWORK $contractName $crowdtainerAddress

END_ETH_BALANCE=$(seth balance $ETH_FROM)
ETH_SPENT="$((START_ETH_BALANCE-END_ETH_BALANCE))"
echo "ETH spent: $(echo "$ETH_SPENT/10^18" | bc -l) ETH"