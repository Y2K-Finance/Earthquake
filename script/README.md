Create .env file like:

```
RINKEBY_RPC_URL=https://eth-rinkeby.alchemyapi.io/v2/blablabla
PRIVATE_KEY=0x00000...
ARBITRUM_RINKEBY_RPC_URL=https://rinkeby.arbitrum.io/rpc
ARBITRUM_RPC_URL=https://arb1.arbitrum.io/rpc
LOCALHOST=...
```

Use command:

```
source .env
```

Deploy with similar command:

```
forge script script/DeployContract.s.sol:ContractScript --rpc-url $ARBITRUM_RPC_URL  --private-key $PRIVATE_KEY --broadcast -vvvv
```
