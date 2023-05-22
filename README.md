# Y2K

![image](https://user-images.githubusercontent.com/15989933/168874410-a2ce1798-8d72-4fce-a6ba-b61d4303a3e9.png)

# Contracts

| Contract        | Arbitrum Address                                                       |
| --------------- | ---------------------------------------------------------------------- |
| Controller      | https://arbiscan.io/address/0x225aCF1D32f0928A96E49E6110abA1fdf777C85f |
| Vault Factory   | https://arbiscan.io/address/0x984e0eb8fb687afa53fc8b33e12e04967560e092 |
| Rewards Factory | https://arbiscan.io/address/0x9889Fca1d9A5D131F5d4306a2BC2F293cAfAd2F3 |
| Y2K token       | https://arbiscan.io/address/0x65c936f008BC34fE819bce9Fa5afD9dc2d49977f |
| Y2K treasury    | https://arbiscan.io/address/0x5c84cf4d91dc0acde638363ec804792bb2108258 |

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
  `forge update`

## Deploy

## Test in Mainnet Fork

```

forge test --fork-url https://arb1.arbitrum.io/rpc -vv

```

## Makefile

```
make install
```
