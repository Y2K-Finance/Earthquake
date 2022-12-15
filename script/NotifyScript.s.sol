// SPDX-License-Identifier;
pragma solidity ^0.8.13;

import "./Helper.sol";

/// @author MiguelBits
//forge script NotifyScript --rpc-url $ARBITRUM_RPC_URL --private-key $PRIVATE_KEY --broadcast --skip-simulation --gas-estimate-multiplier 200 --slow -vv
contract NotifyScript is Script, HelperConfig {

    address[] public rewards = [
        0x19bafA3f140aBDdc8f1a478DF44C1d23e2B371Bf,
         0x4bDF74F72d926B2D70dAFAe8a674ec5B1319390F,
         0x15C61846c17a2aba9cF4921045c05b83Ffeb576E,
         0xbAdf3585aC44561783a2535dA4306f62Ffc6564E,
         0x65176C17a5ff0694884660e2D17B89Cc34F57A19,
         0xDF527b972ee1e67bDcd3472CF2ed0dC2277F1d6F,
         0x0Eb5d1Df19725253E15D954D67694D18eF273237,
         0x69E2f2BE95C61564E331C9a0E0F6167702824EFA,
         0x1DC23d536Af56e4752C448Db9a5B695C0e74BAd1,
         0x71018569EFaB19485d64c75DD5F77f437Ba33892
    ];

    function run() public {
        vm.startBroadcast();
        for (uint i = 0; i < rewards.length; i++) {
            StakingRewards(rewards[i]).notifyRewardAmount(0);
        }
        vm.stopBroadcast();
    }
}