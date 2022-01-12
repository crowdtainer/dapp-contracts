#!/usr/bin/env bash

set -eo pipefail

# import the deployment helpers
. $(dirname $0)/common.sh

# Deploy.
CrowdtainerAddr=$(deploy Crowdtainer 0x3412b62B3cd896Fc768023b0c25Cee9013ca44A9)
log "Crowdtainer deployed at:" $CrowdtainerAddr
