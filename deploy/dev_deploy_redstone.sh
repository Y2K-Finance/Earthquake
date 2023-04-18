#!/bin/bash

# Replace these values with the correct ones for your environment
RPC_URL="https://goerli.infura.io/v3/37519f5fe2fb4d2cac2711a66aa06514"
PRIVATE_KEY="0xa881e3de2f71ddfcd7d5c189c4755b6033328d48e9895d47ea4de00603d6732c"
SEQUENCER_ADDRESS="0x0000000000000000000000000000000000000000"
FACTORY_ADDRESS="0x0000000000000000000000000000000000000000"
CONTRACT_PATH="src/v2/Controllers/RedstonePriceProvider.sol:RedstonePriceProvider"



# Replace these values with the correct ones for your environment
RPC_URL="FROM_CONST"
PRIVATE_KEY="FROM_A_CONST"
SEQUENCER_ADDRESS="0x0000000000000000000000000000000000000000"
FACTORY_ADDRESS="0x0000000000000000000000000000000000000000"
CONTRACT_PATH="src/v2/Controllers/RedstonePriceProvider.sol:RedstonePriceProvider"

forge create --rpc-url $RPC_URL --private-key $PRIVATE_KEY $CONTRACT_PATH --constructor-args "$SEQUENCER_ADDRESS" "$FACTORY_ADDRESS"

#
#Deployer: 0xbe1E971E8e5E50F7698C74656520F0E788a0518D
#Deployed to: 0x11Cc82544253565beB74faeda687db72cd2D5d32
#Transaction hash: 0x65e4c6f1f158dfcd8b0446c61ff34a9bbd3f67328d630e8f5a09711aac8c6d9b