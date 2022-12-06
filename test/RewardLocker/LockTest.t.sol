// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Test.sol";
import {LockRewards} from "./contracts/LockRewards.sol";
import {IERC20} from "./contracts/interfaces/IERC20.sol";

contract LockTest is Test {

    LockRewards lockRewards16;
    LockRewards lockRewards32;
    address y2k = 0x5D59e5837F7e5d0F710178Eda34d9eCF069B36D2;
    address weth = 0x6BE37a65E46048B1D12C0E08d9722402A5247Ff1;
    address lp = 0xE3d9514f1485e3A26789B4a0a2A874D270EFE37e;

    uint rewardsY2k = 50 ether;
    uint rewardsWeth = 50 ether;
    uint maxEpochs = 32;
    uint minEpochs = 16;
    uint epochDurationInDays = 1;
    uint epochStart = block.timestamp + 5 hours;
    uint amountDeposit = 1 ether;
    address USER = 0xaC0D2cF77a8F8869069fc45821483701A264933B;
    function setupDeploy() public {
        lockRewards16 = new LockRewards(lp, y2k, weth, minEpochs, maxEpochs);
        lockRewards32 = new LockRewards(lp, y2k, weth, maxEpochs, maxEpochs);

        lockRewards16.setNextEpoch_start(rewardsY2k, rewardsWeth, epochDurationInDays, epochStart);
        lockRewards16.setNextEpoch(rewardsY2k, rewardsWeth, epochDurationInDays);
        lockRewards32.setNextEpoch_start(rewardsY2k * 2, rewardsWeth * 2, epochDurationInDays, epochStart);
        lockRewards32.setNextEpoch(rewardsY2k * 2, rewardsWeth * 2, epochDurationInDays);
    }

    function setupFork() public {
        lockRewards16 = LockRewards(0x25002Bc9266ac29D10eb655FE959902D650f9Fe0);
        lockRewards32 = LockRewards(0x045D4cBC009C87FAb4d08AcfF7cF6e36ec5491f6);
        emit log_named_uint("balance of lp", IERC20(lp).balanceOf(USER));
    }

    function testLockDeposit() public {
        //setupDeploy();
        setupFork();
        vm.startPrank(USER);
        IERC20(lp).approve(address(lockRewards16), amountDeposit);
        lockRewards16.deposit(amountDeposit, minEpochs);
        IERC20(lp).approve(address(lockRewards32), amountDeposit);
        lockRewards32.deposit(amountDeposit, maxEpochs);
        vm.stopPrank();

        emit log_named_uint("balance of lp", IERC20(lp).balanceOf(USER));
        //balance of lockRewards16
        emit log_named_uint("balance of lockRewards16", lockRewards16.balanceOf(USER));
        //balance of lockRewards32
        emit log_named_uint("balance of lockRewards32", lockRewards32.balanceOf(USER));
    }

    function testFailRelock() public {
        // testLockDeposit();
        setupFork();
        vm.startPrank(USER);
        vm.warp(epochDurationInDays * 1 days);
        IERC20(lp).approve(address(lockRewards16), amountDeposit);
        lockRewards16.deposit(amountDeposit, 1);
        IERC20(lp).approve(address(lockRewards32), amountDeposit);
        lockRewards32.deposit(amountDeposit, 1);
        vm.stopPrank();
    }

    


}