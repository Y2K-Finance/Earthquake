// SPDX-License-Identifier;
pragma solidity ^0.8.13;

import "./Helper.sol";

/// @author MiguelBits
//forge script NotifyScript --rpc-url $ARBITRUM_RPC_URL --private-key $PRIVATE_KEY --broadcast --skip-simulation --gas-estimate-multiplier 200 --slow -vv
contract NotifyScript is Script, HelperConfig {

    address[] public rewards = [
        0x8d26c1e23A9386A0f0489F8c32A32b406a9909D3,
         0xF47F297e6D959c04Fdf49EE60F46c7BCcBC40A10,
         0x699A17E1ae78045bB7e7Cb2d3246A911cE8f8F74,
         0x85A15d35cB1224Ac1677E095aAF938ef28A52833,
         0xa60d765986801253034DA961Bc4d729a3Af01A25,
         0xFe831c70fEbeF5E252ECD9FF45a79EEB88B966d3,
         0x159a2148dD1A411a5648e97396813da6311c4B54,
         0x2c408Be194c7F6B8F80b1dA72Cf54E7397C07c3f,
         0xE3E90fd8841fbaADc2652CFB5DA7fC487CaC517F,
         0xffBa1dA050605766509d6D1f982261Ad866a4CEC,
         0x0A3d57234e497cE46eBEA511A79377b47E2b8BcB,
         0x73fddb363e50F28c95bAF010019CffDde504D844
    ];

    function run() public {
        vm.startBroadcast();
        for (uint i = 0; i < rewards.length; i++) {
            StakingRewards(rewards[i]).notifyRewardAmount(0);
        }
        vm.stopBroadcast();
    }
}
