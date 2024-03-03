// SPDX-License-Identifier;
pragma solidity ^0.8.15;

import "../src/lock-rewards/LockRewards.sol";
import "forge-std/Script.sol";
import "forge-std/StdJson.sol";

// forge script LockRewardsScript --rpc-url $ARBITRUM_RPC_URL --private-key $PRIVATE_KEY --broadcast --skip-simulation --slow --verify -vv

contract LockRewardsScript is Script {
    using stdJson for string;

    function run() public {

        vm.startBroadcast();

        console.log("Broadcast sender", msg.sender);


        LockRewards lockContract16Weeks = new LockRewards(
            0xE3d9514f1485e3A26789B4a0a2A874D270EFE37e, // lockToken
            0x5D59e5837F7e5d0F710178Eda34d9eCF069B36D2, // rewardToken1 GOV
            0x6BE37a65E46048B1D12C0E08d9722402A5247Ff1, // rewardToken2 WETH
            16,
            16
        );

        lockContract16Weeks.changeRecoverWhitelist(0xE3d9514f1485e3A26789B4a0a2A874D270EFE37e, true);

        LockRewards lockContract32Weeks = new LockRewards(
            0xE3d9514f1485e3A26789B4a0a2A874D270EFE37e, // lockToken
            0x5D59e5837F7e5d0F710178Eda34d9eCF069B36D2, // rewardToken1 GOV
            0x6BE37a65E46048B1D12C0E08d9722402A5247Ff1, // rewardToken2 WETH
            32,
            32
        );

        lockContract32Weeks.changeRecoverWhitelist(0xE3d9514f1485e3A26789B4a0a2A874D270EFE37e, true);

        console.log("LockRewards 16 weeks", address(lockContract16Weeks));
        console.log("LockRewards 32 weeks", address(lockContract32Weeks));

        // approve lockContract16Weeks to transfer lockToken
        IERC20(0xE3d9514f1485e3A26789B4a0a2A874D270EFE37e).approve(address(lockContract16Weeks), type(uint256).max);
        lockContract16Weeks.deposit(100 ether, 16);


        // approve lockContract32Weeks to transfer lockToken
        IERC20(0xE3d9514f1485e3A26789B4a0a2A874D270EFE37e).approve(address(lockContract32Weeks), type(uint256).max);
        lockContract32Weeks.deposit(100 ether, 32);

        // log balance
        console.log("LockRewards 16 weeks balance", IERC20(0xE3d9514f1485e3A26789B4a0a2A874D270EFE37e).balanceOf(address(lockContract16Weeks)));
        console.log("LockRewards 32 weeks balance", IERC20(0xE3d9514f1485e3A26789B4a0a2A874D270EFE37e).balanceOf(address(lockContract32Weeks)));
        //transfer ownership
        //vaultFactory.transferOwnership(addresses.admin);
        vm.stopBroadcast();

    }
}