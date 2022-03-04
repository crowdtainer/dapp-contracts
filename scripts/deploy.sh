#!/usr/bin/env bash

set -eo pipefail

# import the deployment helpers
. $(dirname $0)/common.sh

# import config with arguments based on contract and network
. $(dirname $0)/helper-config.sh

# Deploy Crowdtainer.
: ${CONTRACT:=Crowdtainer}

echo "Deploying $CONTRACT to $NETWORK with arguments: $arguments"
Address=$(deploy $CONTRACT)
log "$CONTRACT deployed at:" $Address

: ${CONTRACT:=Vouchers721}

# Now deploy Vouchers712, giving it a reference to the Crowdtainer implementation
$arguments = $Address $arguments
echo "Deploying $CONTRACT to $NETWORK with arguments: $Address $arguments"
Address=$(deploy $CONTRACT $Address)
log "$CONTRACT deployed at:" $Address
