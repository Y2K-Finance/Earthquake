// SPDX-License-Identifier;
pragma solidity ^0.8.13;

import "./Helper.sol";

/// @author MiguelBits
//forge script NotifyScript --rpc-url $ARBITRUM_RPC_URL --private-key $PRIVATE_KEY --broadcast --skip-simulation --gas-estimate-multiplier 200 --slow -vv
contract NotifyScript is Script, HelperConfig {

    address[] public rewards = [
        0xF2B08467510490d87603FD5E456855a86dBee861,
         0x07c7A7B21e0393fFD8e2dd4b81FcbFC3aA27E091,
         0xc59465d44B45BE3510056d5152Df49950AeAe0bC,
         0x7682667b528eCb3584247988F8A1CbD42EEee2Aa,
         0x8e3bE385e4901Aa2E46B2cFfB67d168c908772e4,
         0x0FdcffEc9AC0C0A5f22EdaF7Ca521CB886a4bEBF,
         0x819B9CE06C5EcAFD314f194A199F39f0E9e68b17,
         0x4A351c2717CaBD8CE23191BF55A59fcBA03b45Fb,
         0x39dB79a22b7FD3610EBbF31D2F97bc901Cf72609,
         0x2F1013700a91846B1e9a1069F2b9c31d6B7ECb5d,
         0x86D79957eeB010FA98c7bE01e01E6c7Aabce3c2D,
         0x60fB512249217E1b4c0a8baa61dC4DCa04EF8eB7
    ];

    function run() public {
        vm.startBroadcast();
        for (uint i = 0; i < rewards.length; i++) {
            StakingRewards(rewards[i]).notifyRewardAmount(0);
        }
        vm.stopBroadcast();
    }
}
