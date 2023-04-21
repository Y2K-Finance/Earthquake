#!/bin/bash

# 1 - Setup .env
# 
#
# 



# Make sure you use . .env or source .env before using this script
. .env
CONTRACT_PATH="src/v2/Controllers/RedstonePriceProvider.sol:RedstonePriceProvider"
forge create --rpc-url $RPC_URL --private-key $PRIVATE_KEY $CONTRACT_PATH --constructor-args "$SEQUENCER_ADDRESS" "$FACTORY_ADDRESS" "VST"