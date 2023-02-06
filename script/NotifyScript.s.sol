// SPDX-License-Identifier;
pragma solidity ^0.8.13;

import "./Helper.sol";

/// @author MiguelBits
//forge script NotifyScript --rpc-url $ARBITRUM_RPC_URL --private-key $PRIVATE_KEY --broadcast --skip-simulation --gas-estimate-multiplier 200 --slow -vv
contract NotifyScript is Script, HelperConfig {

    address[] public rewards = [
         0x6A74021D67002Ba1948109FAeD2C50244882577A,
         0x90557aFCddB76B855bD70343BA00a27967aeb56b,
         0x3a20a5C6B3e9331d5Bc854F563DEDc88896a1417,
         0x9Aa2E8B1bfe386890a0eA2ae4eF3Ea555d2920Fc,
         0x50C64a8babcd32f8746d4D4730C35097a1e454AA,
         0xfF2eD828Fd39936E0eCF4DE2d5a61de55Eb2823C,
         0x7B5b1E41Fa1908a3c6339a633Ea209a5a7491721,
         0xc7cEDa964cb4FD41Bc406f054f780D9327641B26,
         0x44bAf45349EDB93fd5416B6c303587F9dE5625d8,
         0xcf0D125CdC00f0e5003fF597d4069e0d1EFCd218,
         0x3B0cAaDC0FFA682BF2DfA3467c034e0038A6D4eb,
         0x9CC6343574D7F71c72cE141a8754E673180263fE,
         0x31ae6B7b62aAcFd4f4d3F35f5C0206fF6194C38c,
         0xc2cC71f1f0c1A3a7b245985A4BBAE6A13f5E4EB0
    ];

    function run() public {
        vm.startBroadcast();
        for (uint i = 0; i < rewards.length; i++) {
            StakingRewards(rewards[i]).notifyRewardAmount(0);
        }
        vm.stopBroadcast();
    }
}
