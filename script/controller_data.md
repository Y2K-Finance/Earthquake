# Earthquake V2 Controller Data README

## Overview

This repository contains the implementation of the Earthquake V2 Controller, which is responsible for managing depeg events and handling data from various price providers.

## File Structure
```
src/v2/Controllers/
├── IDepegCondition.sol
├── IPriceProvider.sol
├── ControllerGenericV2.sol
├── PriceBasedDepegCondition.sol
├── ChainlinkPriceProvider.sol
├── RedstoneMockPriceProvider.sol
└── RedstonePriceProvider.sol
```

### Files Description

- **IDepegCondition.sol**: A generic depeg condition interface.
- **IPriceProvider.sol**: A generic price data provider interface, given a token address.
- **ControllerGenericV2.sol**: A new controller that can read data from a generic provider and be triggered by a generic depeg condition.
- **PriceBasedDepegCondition.sol**: A specific depeg condition controlled by an IPriceProvider and a strike price.
- **ChainlinkPriceProvider.sol**: A provider that uses a Chainlink source.
- **RedstoneMockPriceProvider.sol**: A provider that fakes a RedStone oracle.
- **RedstonePriceProvider.sol**: A real RedStone oracle.

## Tests

The following tests are included:


## Tests

The following tests are included:
```
test/V2/e2e/EndToEndV2GenericTest.t.sol:EndToEndV2Test
├── testGenericEndToEndDepeg() (gas: 592183)
└── testGenericEndToEndEndEpoch() (gas: 408323)
```


These tests use the `RedstoneMockPriceProvider.sol` to test a depeg event. This validates the interface in the case of the Earthquake epoch but does not actually integrate with any RedstoneOracle on-chain.

## Setup

### Prerequisites

1. Install Foundry:

```
sh
curl -L https://foundry.paradigm.xyz | bash
. ~/.bashrc
foundryup
```

## Clone the repository
```
git clone  https://github.com/Y2K-Finance/Earthquake
cd Earthquake
git checkout earthquake-v2-controller-data
```


## Run tests
```
forge test
```

## Deploy RedstonePriceProvider.sol
```
./script/DeployRedstoneVST.sh
```
Note: Record the contract address.


## Test the deployed contract
```
forge script ./script/TestRedstoneVST.s.sol:TestRedstoneVST --ffi --rpc-url $GOERLI_RPC_URL --broadcast -vvvv
```

## Create .env
Create a .env file in the root of the project with the following variables:

```
# Required for the dev version of RedStone
RPC_URL="https://goerli.infura.io/v3/XXXXXXXXXXXXXX"
PRIVATE_KEY="0xXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
SEQUENCER_ADDRESS="0x0000000000000000000000000000000000000000"
FACTORY_ADDRESS="0x0000000000000000000000000000000000000000"
CONTRACT_PATH="src/v2/Controllers/RedstonePriceProvider.sol:RedstonePriceProvider"

# Classic 
ARBITRUM_GOERLI_RPC_URL=https://goerli-rollup.arbitrum.io/rpc
PRIVATE_KEY=0xXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```
