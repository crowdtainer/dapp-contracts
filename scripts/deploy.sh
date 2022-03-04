#!/usr/bin/env bash

set -eo pipefail

# import the deployment helpers
. $(dirname $0)/common.sh

# import config with arguments based on contract and network
. $(dirname $0)/helper-config.sh

# Deploy Crowdtainer.
: ${CONTRACT:=Crowdtainer}

echo "Deploying $CONTRACT to $NETWORK with arguments: $arguments"
Address=$(deploy $CONTRACT $arguments)
log "$CONTRACT deployed at:" $Address

# Now deploy Vouchers712, giving it a reference to the Crowdtainer implementation

echo "Deploying Vouchers721 to $NETWORK with arguments: $Address $arguments"
Address=$(deploy Vouchers721 $Address $arguments)
log "Vouchers721 deployed at:" $Address
