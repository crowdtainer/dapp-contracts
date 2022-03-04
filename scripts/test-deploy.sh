#!/usr/bin/env bash

set -eo pipefail

# bring up the network
. $(dirname $0)/run-temp-testnet.sh

# run the deploy script
. $(dirname $0)/deploy.sh

# get the addresses
crowdtainerAddr=$(jq -r '.Crowdtainer' out/addresses.json)
vouchersAddr=$(jq -r '.Vouchers721' out/addresses.json)

# the initial crowdtainerCount must be zero
greeting=$(seth call $vouchersAddr 'crowdtainerCount()(uint256)')
[[ $greeting = 0 ]] || error

# example on how to interact using temporary keystore
# seth send $vouchersAddr \
#     'greet(string memory)' '"yo"' \
#     --keystore $TMPDIR/8545/keystore \
#     --password /dev/null

sleep 1

echo "Success."
