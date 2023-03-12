// SPDX-License-Identifier;
pragma solidity ^0.8.13;

import "./Helper.sol";

/// @author MiguelBits
//forge script NotifyScript --rpc-url $ARBITRUM_RPC_URL --private-key $PRIVATE_KEY --broadcast --skip-simulation --gas-estimate-multiplier 200 --slow -vv
contract NotifyScript is Script, HelperConfig {

    address[] public rewards = [
         0xf1666400507da4886917f07E03A7bB27477eF742,
         0x0D09ddB0034d98Ed508216602C2297acaB722AE6,
         0x959579254313c92c2B37d747769dB7814cd2a1DF,
         0x089CED40eD1daF0bb2c53982f017861DFe323ED0,
         0xB7dA56B18fc352097FBe5d29a87F77cDE06Ed994,
         0x299f37CE634C4858503cc7145006C3fA1Af20EFC,
         0xEB413d3E8334540FA29DFAC2a9560AA925a2F722,
         0x9b83ee7C5b8C64A7571790BAed1B1939c040D312,
         0xC959faF9d5c5f7dD4fF43290AE905f6D1eD59A51,
         0x92e6EBc308E2e188DEBc8cfE95a517d91056A7b5,
         0x5044DDA63b2bff8fAf962f848893262425F2C694,
         0x3990ba1cF2c6F7Ccf166c28d2c14a44F3467503D,
         0x8BAAc8887Efe1fcD7aC3e89F647B311f7F37FCC9,
         0x62398b7a4fb30D90C4893191A02Ba6935F33013A
    ];

    function run() public {
        vm.startBroadcast();
        for (uint i = 0; i < rewards.length; i++) {
            StakingRewards(rewards[i]).notifyRewardAmount(0);
        }
        vm.stopBroadcast();
    }
}
