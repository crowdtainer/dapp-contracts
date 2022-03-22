#!/usr/bin/env bash

# Defaults
# Add your defaults here
# For example:
# address=0x01be23585060835e02b77ef475b0cc51aa1e0709

# Contract arguments default here
arguments=""

if [ "$NETWORK" = "rinkeby" ]
then 
    : # Add arguments only for rinkeby here!
    # like: 
    # address=0x83858094EA2c475F1E91e4AC09C64255EaCB0DfF
elif [ "$NETWORK" = "mainnet" ]
then 
    : # Add arguments only for mainnet here!
    # like: 
    # address=0x01be23585060835e02b77ef475b0cc51aa1e0709
fi

if [ "$CONTRACT" = "Crowdtainer" ]
then 
    : # Add conditional arguments here for contracts
    # arguments=$interval
fi 