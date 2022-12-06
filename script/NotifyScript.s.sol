// SPDX-License-Identifier;
pragma solidity ^0.8.13;

import "./Helper.sol";

/// @author MiguelBits
//forge script NotifyScript --rpc-url $ARBITRUM_RPC_URL --private-key $PRIVATE_KEY --broadcast --skip-simulation --gas-estimate-multiplier 200 --slow -vv
contract NotifyScript is Script, HelperConfig {

    address[] public rewards = [
        0x7a6D2EfB486bbc91266fb43473B9CA2C5Da7F0cA,
    0x12e77EDa10071cF5791F024059FAc5D5A7b487d7 ,
    0xE5d8576805bc45aeC62d9F90A73E9AD15B1dFB1d ,
    0x6e8F08653317EA05d138FCa6dcB069F5eBCFB9E3,
    0x6f72b4DD530725df79C24A416dA5db1bAd297354 ,
    0x3Da92C7fbe81350C64Ae40fB606A36Bd6192Bd47 ,
    0x340bCE2EBcc20de3DBBA71667aBb021F159A9850 ,
    0x8e119CE249476490DAe0Abbf36d7d0bCFEaa1bDD ,
    0x6F4bCdAa3Ab5b6eC75E3c30e8FF8B48c2aE4f89E ,
    0x54D3cfeAA423EE4246605c65AF6C20B6d8e4E226 ,
    0x05f318Ed71F42848E5a3f249805e51520D77c654 ,
    0xe62ad4f2219EFD116ee8Fa18d242B09a1C04db9C ,
    0x1Ffd39a15FFdf362f1ac8E3eaaDdd5c69b5F1CA2 ,
    0xb7330B1E2FF9c71848E32Bb5Ed7a70D2f00E100E ,
    0xB1c39c22B43f7ce9619bCaC7eda2c07d9b849120 ,
    0xf411386BCD7ab10604F1cfAd1613bA9A088Edcfa ,
    0x959Dfcd448cC6CF908ef3EC26C08d93D3A8DDFfF ,
    0x1b3b4DB62dFAc2963EE4597BE53cd500f829289C ,
    0x07EDb0ed167CDF787e0C7Cb212cF2b60CEbc4a70 
    ];

    function run() public {
        vm.startBroadcast();
        for (uint i = 0; i < rewards.length; i++) {
            StakingRewards(rewards[i]).notifyRewardAmount(0);
        }
        vm.stopBroadcast();
    }
}