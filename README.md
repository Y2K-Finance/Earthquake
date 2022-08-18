# Y2K

![image](https://user-images.githubusercontent.com/15989933/168874410-a2ce1798-8d72-4fce-a6ba-b61d4303a3e9.png)

# Foundry / Forge

## Resources

- [Foundry Book](https://book.getfoundry.sh/index.html)

## Quickstart

### Requirements Install Foundry

- [Forge/Foundryup](https://github.com/gakonst/foundry#installation)

  - You'll know you've done it right if you can run `forge --version`
- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)

  - You'll know you've done it right if you can run `git --version`
- Install libs
  ``forge update``

## Deploy

```
forge create --rpc-url http://127.0.0.1:8545/ --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 src/VaultFactory.sol:VaultFactory --constructor-args "0xEAE1f7b21B7f6c711C441d85eE5ab53E4A626D65"

forge create --rpc-url http://127.0.0.1:8545/ --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 test/GovToken.sol:GovToken

forge create --rpc-url http://127.0.0.1:8545/ --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 src/Controller.sol:Controller --constructor-args "Address of GovToken" "Address of VaultFactory"

Then:
vaultFactory.setController(address(controller));
```

## Test in Mainnet Fork

```

forge test --fork-url https://eth-mainnet.alchemyapi.io/v2/XGDnf9iNvs51rbBp5r07HB7nIBg_Frqm -vv
forge test --match-contract PegMarketsTest --match-test testOracle --fork-url https://arb1.arbitrum.io/rpc -vv
forge test --match-contract PegMarketsTest --fork-url https://arb1.arbitrum.io/rpc -vv  


```

## Makefile

```
make install
```
