#!/usr/bin/env bash

set -eo pipefail

# bring up the network
. $(dirname $0)/run-temp-testnet.sh

sleep 3

# run the deploy script
. $(dirname $0)/deploy.sh

# get the addresses
crowdtainerAddress=$(jq -r '.Crowdtainer' out/addresses.json)
metadataServiceAddress=$(jq -r '.MetadataServiceV1' out/addresses.json)
vouchersAddress=$(jq -r '.Vouchers721' out/addresses.json)

# the initial crowdtainerCount must be zero
greeting=$(seth call $vouchersAddress 'crowdtainerCount()(uint256)')
[[ $greeting = 0 ]] || error

# Encoding calldata structs: https://github.com/dapphub/dapptools/issues/616

# example on how to interact using temporary keystore
# seth send $vouchersAddr \
#     'greet(string memory)' '"yo"' \
#     --keystore $TMPDIR/8545/keystore \
#     --password /dev/null

sleep 1

echo "Success."
