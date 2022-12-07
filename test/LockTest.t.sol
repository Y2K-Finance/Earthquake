// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Test.sol";
import {LockRewards} from "../src/lock-rewards/LockRewards.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";

contract LockTest is Test {

    LockRewards lockRewards16;
    LockRewards lockRewards32;
    address y2k = 0x5D59e5837F7e5d0F710178Eda34d9eCF069B36D2;
    address weth = 0x6BE37a65E46048B1D12C0E08d9722402A5247Ff1;
    address lp = 0xE3d9514f1485e3A26789B4a0a2A874D270EFE37e;

    uint rewardsY2k = 5 ether;
    uint rewardsWeth = 5 ether;
    uint maxEpochs = 32;
    uint minEpochs = 16;
    uint epochDurationInDays = 1;
    uint epochStart = block.timestamp + 5 hours;
    uint amountDeposit = 1 ether;
    address USER = 0xaC0D2cF77a8F8869069fc45821483701A264933B;

    //******************************************************************************/
    /*                                      DEPLOY
    ////////// ///////////////////////////////////////////////////////////////////*/
    function setupDeploy() public {
        vm.startPrank(USER);
        console.log("Setup");
        lockRewards16 = new LockRewards(lp, y2k, weth, maxEpochs, minEpochs);
        lockRewards32 = new LockRewards(lp, y2k, weth, maxEpochs, maxEpochs);
        ERC20(y2k).transfer(address(lockRewards16), rewardsY2k);
        ERC20(y2k).transfer(address(lockRewards16), rewardsY2k);
        // emit log_named_uint("balance of y2k", ERC20(y2k).balanceOf(USER));
        ERC20(weth).transfer(address(lockRewards16), rewardsWeth);
        ERC20(weth).transfer(address(lockRewards16), rewardsWeth);
        // emit log_named_uint("balance of weth", ERC20(weth).balanceOf(USER));
        ERC20(y2k).transfer(address(lockRewards32), rewardsY2k * 2);
        ERC20(y2k).transfer(address(lockRewards32), rewardsY2k * 2);
        ERC20(weth).transfer(address(lockRewards32), rewardsWeth * 2);
        ERC20(weth).transfer(address(lockRewards32), rewardsWeth * 2);
        // emit log_named_uint("balance of y2k16 ", ERC20(y2k).balanceOf(address(lockRewards16)));
        // emit log_named_uint("balance of y2k32 ", ERC20(y2k).balanceOf(address(lockRewards32)));
        // emit log_named_uint("balance of weth16", ERC20(weth).balanceOf(address(lockRewards16)));
        // emit log_named_uint("balance of weth32", ERC20(weth).balanceOf(address(lockRewards32)));

        lockRewards16.setNextEpoch_start(rewardsY2k, rewardsWeth, epochDurationInDays,
         epochStart);

        lockRewards16.setNextEpoch(rewardsY2k, rewardsWeth,
         epochDurationInDays);

        lockRewards32.setNextEpoch_start(rewardsY2k * 2,
         rewardsWeth * 2, epochDurationInDays, epochStart);

        lockRewards32.setNextEpoch(rewardsY2k * 2,
         rewardsWeth * 2, epochDurationInDays);

        vm.stopPrank();
    }

    function setupFork() public {
        lockRewards16 = LockRewards(0x25002Bc9266ac29D10eb655FE959902D650f9Fe0);
        lockRewards32 = LockRewards(0x045D4cBC009C87FAb4d08AcfF7cF6e36ec5491f6);
        emit log_named_uint("balance of lp", ERC20(lp).balanceOf(USER));
    }

    //******************************************************************************/
    /*                                      DEPOSIT
    ////////// ///////////////////////////////////////////////////////////////////*/

    function lockDeposit(uint epochs16, uint epochs32) public {
        //setupDeploy();
        //setupFork();
        console.log("Deposit");
        vm.startPrank(USER);
        ERC20(lp).approve(address(lockRewards16), amountDeposit);
        lockRewards16.deposit(amountDeposit, epochs16);
        ERC20(lp).approve(address(lockRewards32), amountDeposit);
        lockRewards32.deposit(amountDeposit, epochs32);
        vm.stopPrank();

        emit log_named_uint("balance of lp", ERC20(lp).balanceOf(USER));
        //balance of lockRewards16
        emit log_named_uint("balance of lockRewards16", lockRewards16.balanceOf(USER));
        //balance of lockRewards32
        emit log_named_uint("balance of lockRewards32", lockRewards32.balanceOf(USER));
        // viewAccount16();
        // viewAccount32();
    }

    function compoundDeposit() public {
        vm.startPrank(USER);
        vm.warp(epochDurationInDays * 1 days);

        lockRewards16.claimReward();
        lockRewards32.claimReward();

        ERC20(lp).approve(address(lockRewards16), amountDeposit);
        lockRewards16.deposit(amountDeposit, minEpochs);
        ERC20(lp).approve(address(lockRewards32), amountDeposit);
        lockRewards32.deposit(amountDeposit, maxEpochs);
        vm.stopPrank();
    }
    
    function testDeposit() public {
        setupDeploy();
        lockDeposit(minEpochs, maxEpochs);
        assertTrue(lockRewards16.balanceOf(USER) == amountDeposit, "balance of lockRewards16");
        assertTrue(lockRewards32.balanceOf(USER) == amountDeposit, "balance of lockRewards32");
    }

    function testReDeposit() public {
        setupDeploy();
        lockDeposit(minEpochs, maxEpochs);
        compoundDeposit();
        assertTrue(lockRewards16.balanceOf(USER) == amountDeposit * 2, "balance of lockRewards16");
        assertTrue(lockRewards32.balanceOf(USER) == amountDeposit * 2, "balance of lockRewards32");
    }

    function testFailReDeposit() public {
        setupDeploy();
        lockDeposit(minEpochs, maxEpochs);
        lockDeposit(1,1);
    }

    // write test for compound lock check if rewards are accrued
    function testIncreaseAmount() public {
        setupDeploy();
        lockDeposit(minEpochs, maxEpochs);
        lockDeposit(0,0);
        assertTrue(lockRewards16.balanceOf(USER) == amountDeposit * 2, "balance of lockRewards16");
        assertTrue(lockRewards32.balanceOf(USER) == amountDeposit * 2, "balance of lockRewards32");
    }

    //******************************************************************************/
    /*                                      EPOCHS
    ////////// ///////////////////////////////////////////////////////////////////*/
    function startNextEpoch(uint warpTime) public {
        vm.warp(warpTime);
        console2.log("block.timestamp", block.timestamp);
        
        vm.startPrank(USER);
        ERC20(y2k).transfer(address(lockRewards16), rewardsY2k);
        ERC20(y2k).transfer(address(lockRewards16), rewardsY2k);
        // emit log_named_uint("balance of y2k", ERC20(y2k).balanceOf(USER));
        ERC20(weth).transfer(address(lockRewards16), rewardsWeth);
        ERC20(weth).transfer(address(lockRewards16), rewardsWeth);
        // emit log_named_uint("balance of weth", ERC20(weth).balanceOf(USER));
        ERC20(y2k).transfer(address(lockRewards32), rewardsY2k * 2);
        ERC20(y2k).transfer(address(lockRewards32), rewardsY2k * 2);
        ERC20(weth).transfer(address(lockRewards32), rewardsWeth * 2);
        ERC20(weth).transfer(address(lockRewards32), rewardsWeth * 2);
        // emit log_named_uint("balance of y2k16 ", ERC20(y2k).balanceOf(address(lockRewards16)));
        // emit log_named_uint("balance of y2k32 ", ERC20(y2k).balanceOf(address(lockRewards32)));
        // emit log_named_uint("balance of weth16", ERC20(weth).balanceOf(address(lockRewards16)));
        // emit log_named_uint("balance of weth32", ERC20(weth).balanceOf(address(lockRewards32)));

        lockRewards16.setNextEpoch(rewardsY2k, rewardsWeth, epochDurationInDays);

        lockRewards32.setNextEpoch(rewardsY2k * 2,
         rewardsWeth * 2, epochDurationInDays);

        vm.stopPrank();

        (uint start, uint finish, uint locked, uint rewards1, uint rewards2, ) = lockRewards16.getNextEpoch();
        emit log_named_uint("start", start);
        emit log_named_uint("finish", finish);
        emit log_named_uint("locked", locked);
        emit log_named_uint("rewards1", rewards1);
        emit log_named_uint("rewards2", rewards2);
        viewCurrentEpoch();
        
    }
    
    function testWarpNextEpoch() public {
        setupDeploy();
        //epoch 1
        viewCurrentEpoch();
        console.log("Current epoch");
        console2.log("block.timestamp", block.timestamp);
        
        //epoch 2
        vm.warp(epochStart + 1 days);
        lockRewards16.updateEpochs();
        lockRewards32.updateEpochs();
        console.log("Warp to next epoch");
        console2.log("block.timestamp", block.timestamp);
        viewCurrentEpoch();

        //epoch 3
        vm.warp(block.timestamp + (epochDurationInDays * 200 * 1 days));
        lockRewards16.updateEpochs();
        lockRewards32.updateEpochs();
        console.log("Warp to next epoch");
        console2.log("block.timestamp", block.timestamp);
        viewCurrentEpoch();
    }

    function testMultipleEpochs(uint any) public {
        vm.assume(any > 0 && any < 32);
        setupDeploy();
        transitionNextEpoch();
        for(uint i = 0; i <= any; i++) {
            viewCurrentEpoch();
            startNextEpoch(block.timestamp +  1 days + 2);
            console.log("Warp to next epoch");
            console2.log("i current epoch", i);
        }
    }
    
    // TODO
    // relock your already locked tokens (need to be min epochs)
    // increase your position when already locked
    // lock for min epochs amount

    function transitionNextEpoch() public {
        (uint256 start,
        uint256 finish,
        uint256 locked,
        uint256 rewards1,
        uint256 rewards2,
        bool isSet) = lockRewards16.getCurrentEpoch();
        emit log_named_uint("start", start);
        emit log_named_uint("finish", finish);
        emit log_named_uint("locked", locked);
        emit log_named_uint("rewards1", rewards1);
        emit log_named_uint("rewards2", rewards2);
        if(isSet) {
            emit log_named_uint("isSet", 1);
        }else{
            emit log_named_uint("isSet", 0);
        }

        (uint256 start_2,
        uint256 finish_2,
        uint256 locked_2,
        uint256 rewards1_2,
        uint256 rewards2_2,
        bool isSet_2) = lockRewards16.getNextEpoch(); 
        emit log_named_uint("start_2", start_2);
        emit log_named_uint("finish_2", finish_2);
        emit log_named_uint("locked_2", locked_2);
        emit log_named_uint("rewards1_2", rewards1_2);
        emit log_named_uint("rewards2_2", rewards2_2);
        if(isSet_2) {
            emit log_named_uint("isSet_2", 1);
        }else{  
            emit log_named_uint("isSet_2", 0);
        }

        console2.log("block.timestamp", block.timestamp);
        assertTrue(start < start_2, "start < start_2");
        assertTrue(finish < finish_2, "finish < finish_2");
        assertTrue(finish + 1 == start_2, "finish == start_2");
        
        // viewCurrentEpoch();
        startNextEpoch(start_2);
        assertTrue(block.timestamp > finish, "block.timestamp > finish");
        // viewCurrentEpoch();

    }

    //******************************************************************************/
    /*                                      CLAIM
    ////////// ///////////////////////////////////////////////////////////////////*/

    function claimRewards() public {
        uint oldBalanceY2k = ERC20(y2k).balanceOf(USER);
        uint oldBalanceWeth = ERC20(weth).balanceOf(USER);
        
        vm.startPrank(USER);
        (uint rewarded1, uint rewarded2) = lockRewards16.claimReward();
        emit log_named_uint("rewarded y2k ", rewarded1);
        emit log_named_uint("rewarded weth", rewarded2);
        assertTrue(rewarded1 > 0, "rewarded1_16 > 0");
        assertTrue(rewarded2 > 0, "rewarded2_16 > 0");
        (rewarded1, rewarded2) = lockRewards32.claimReward();
        emit log_named_uint("rewarded y2k ", rewarded1);
        emit log_named_uint("rewarded weth", rewarded2);
        assertTrue(rewarded1 > 0, "rewarded1_32 > 0");
        assertTrue(rewarded2 > 0, "rewarded2_32 > 0");
        vm.stopPrank();

        uint newBalanceY2k = ERC20(y2k).balanceOf(USER);
        uint newBalanceWeth = ERC20(weth).balanceOf(USER);
        
        //balance of y2k
        emit log_named_uint("old balance of y2k ", oldBalanceY2k);
        emit log_named_uint("new balance of y2k ", newBalanceY2k);
        //balance of weth
        emit log_named_uint("old balance of weth", oldBalanceWeth);
        emit log_named_uint("new balance of weth", newBalanceWeth);

        viewCurrentEpoch();

        assertTrue(newBalanceY2k > oldBalanceY2k, "newBalanceY2k > oldBalanceY2k");
        assertTrue(newBalanceWeth > oldBalanceWeth, "newBalanceWeth > oldBalanceWeth");
    }

    function testClaimRewards() public {

        setupDeploy();
        lockDeposit(minEpochs, maxEpochs);
        console.log("Claim Rewards");

        //skip 1st epoch
        vm.warp(epochStart + 1 days);
        // (uint y2k_rewards16, uint weth_rewards16) = viewAccount16();
        // (uint y2k_rewards32, uint weth_rewards32) = viewAccount32();
        viewAccount16();
        viewAccount32();

        claimRewards();        
    }

    function testCompoundRewards() public {
        testClaimRewards();
        lockDeposit(0,0);
        console.log("Compound rewards");
        vm.warp(block.timestamp + 1 days + 2);
        viewAccount16();
        viewAccount32();

        claimRewards();
    }

    function testFuzzCompoundRewards(uint any) public {
        vm.assume(any < minEpochs - 1 && any > 0);
        testClaimRewards();
        for(uint i = 0; i <= any; i++){
            lockDeposit(0,0);
            console.log("Compound rewards");
            startNextEpoch(block.timestamp + 1 days + 2);
            viewAccount16();
            viewAccount32();

            claimRewards();
        }
    }
    // test for IncreaseLockEpochsNotGTZero()
    function testFailCompoundRewards() public {
        testClaimRewards();
        for(uint i = 0; i <= minEpochs; i++){
            lockDeposit(0,0);
            console.log("Compound rewards");
            startNextEpoch(block.timestamp + 1 days + 2);
            viewAccount16();
            viewAccount32();

            claimRewards();
        }
        // vm.expectRevert(LockRewards.selector.IncreaseLockEpochsNotGTZero());
    }

    //******************************************************************************/
    /*                                      VIEW
    ////////// ///////////////////////////////////////////////////////////////////*/

    function viewAccount16() public returns(uint, uint){
        console.log("View account 16");
        vm.startPrank(USER);
        (uint256 balance, uint256 lockEpochs, uint256 lastEpochPaid, 
        uint256 rewards1, uint256 rewards2) = lockRewards16.updateAccount();
        emit log_named_uint("balance", balance);
        emit log_named_uint("epochs locked", lockEpochs);
        emit log_named_uint("last epoch paid", lastEpochPaid);
        emit log_named_uint("y2k rewards1", rewards1);
        emit log_named_uint("weth rewards2", rewards2);
        vm.stopPrank();

        uint y2kBal = rewards1;
        uint wethBal = rewards2;
        return (y2kBal, wethBal);
    }
    function viewAccount32() public returns(uint, uint){
        console.log("View account 32");
        vm.startPrank(USER);
        (uint256 balance, uint256 lockEpochs, uint256 lastEpochPaid, 
        uint256 rewards1, uint256 rewards2) = lockRewards32.updateAccount();
        emit log_named_uint("balance", balance);
        emit log_named_uint("epochs locked", lockEpochs);
        emit log_named_uint("last epoch paid", lastEpochPaid);
        emit log_named_uint("y2k rewards1", rewards1);
        emit log_named_uint("weth rewards2", rewards2);
        vm.stopPrank();

        uint y2kBal = rewards1;
        uint wethBal = rewards2;
        return (y2kBal, wethBal);
    }

    function viewCurrentEpoch() public {
        //lockrewards16 current epoch
        uint epoch16 = lockRewards16.currentEpoch();
        //lockrewards32 current epoch
        uint epoch32 = lockRewards32.currentEpoch();
        emit log_named_uint("current epoch16", epoch16);
        emit log_named_uint("current epoch32", epoch32);
    }
}