#!/usr/bin/env bash

set -eo pipefail

# import the deployment helpers
. $(dirname $0)/common.sh

# Deploy Crowdtainer.
CrowdtainerAddr=$(deploy Crowdtainer)
log "Crowdtainer deployed at:" $CrowdtainerAddr

# Now deploy Vouchers712, giving it a reference to the Crowdtainer implementation
Vouchers721Addr=$(deploy Vouchers721 $CrowdtainerAddr)
log "Vouchers721 deployed at:" $Vouchers721Addr

