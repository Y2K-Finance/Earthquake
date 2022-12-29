// SPDX-License-Identifier;
pragma solidity ^0.8.13;

import "./Helper.sol";

/// @author MiguelBits
//forge script NotifyScript --rpc-url $ARBITRUM_RPC_URL --private-key $PRIVATE_KEY --broadcast --skip-simulation --gas-estimate-multiplier 200 --slow -vv
contract NotifyScript is Script, HelperConfig {

    address[] public rewards = [
        0xCB10779f0806e2d6f33025cEBb7664dFAD8B8B7B,
         0xBB0bBA94F8383160e19E930DB20FDB6CaA943aBD,
         0xe9211260d67F52247A00a67bce790DFc8b3df0e2,
         0xb73d9b01c633861e472cEA8e253a2f36Dc636FE2,
         0x9EA823Dc86A4b887F68baB50E19753CDEcD9F5F5,
         0x876A5C3Cf93b4663DB59Da00e2b18fab5A5C1b9b,
         0xe494e739EE9FEcbA59CcDCC0E7D25688232fE730,
         0x0494bfbe21eBF830aE309538B1A01F81a9D65BbF,
         0xc7147F170ABe43f846e779830B0805ECA19D591E,
         0x5578A7d563ea55a695EE77c1392ec0DCad4459ae
    ];

    function run() public {
        vm.startBroadcast();
        for (uint i = 0; i < rewards.length; i++) {
            StakingRewards(rewards[i]).notifyRewardAmount(0);
        }
        vm.stopBroadcast();
    }
}
