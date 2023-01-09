// SPDX-License-Identifier;
pragma solidity ^0.8.13;

import "./Helper.sol";

/// @author MiguelBits
//forge script NotifyScript --rpc-url $ARBITRUM_RPC_URL --private-key $PRIVATE_KEY --broadcast --skip-simulation --gas-estimate-multiplier 200 --slow -vv
contract NotifyScript is Script, HelperConfig {

    address[] public rewards = [
        0x91EF9bB9aC64f41c655D92BDeEC26Cdbee60dbf7,
         0x8Ade8B0fCe5C327bF9510a682a4DA24fEA22423C,
         0xeb89d16B5904d3AFe4F9344Ca1E6C8574157fbe6,
         0xD433458fEa78479627740A1e96DF81f54a7c8836,
         0x2624e5994bb4F0C4C8646609d7664D28b4C28558,
         0x079706F00AA3274e81199905C4E2cA88721a69C4,
         0x677Ff924eb2dC060059BA3524C7e9086be7d4695,
         0x638F3B2Fd7560c1D2736B6f077f84a352f53fe1b,
         0x1B71dd77FE00A6c577b1664FDc9bC6263dC05999,
         0x0c8c502ee0a13D7336D515e54015aAF1C431e6D1
    ];

    function run() public {
        vm.startBroadcast();
        for (uint i = 0; i < rewards.length; i++) {
            StakingRewards(rewards[i]).notifyRewardAmount(0);
        }
        vm.stopBroadcast();
    }
}
