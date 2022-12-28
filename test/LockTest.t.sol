// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Test.sol";
import {LockRewards} from "../src/lock-rewards/LockRewards.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";

/// @author MiguelBits

contract LockTest is Test {

    LockRewards public lockRewards16;

    address public constant Y2K = 0x5D59e5837F7e5d0F710178Eda34d9eCF069B36D2;
    address public constant WETH = 0x6BE37a65E46048B1D12C0E08d9722402A5247Ff1;
    address public constant LP = 0xE3d9514f1485e3A26789B4a0a2A874D270EFE37e;

    uint public constant REWARDS_Y2K = 5 ether;
    uint public constant REWARDS_WETH = 5 ether;
    uint public constant MAX_EPOCHS = 32;
    uint public constant MIN_EPOCHS = 16;
    uint public constant EPOCH_DURATION_IN_DAYS = 1;
    uint public constant AMOUNT_DEPOSIT = 1 ether;
    address public constant USER = 0xaC0D2cF77a8F8869069fc45821483701A264933B;
    uint public immutable EPOCH_START = block.timestamp + 5 hours;

    //******************************************************************************/
    /*                                      DEPLOY
    ////////// ///////////////////////////////////////////////////////////////////*/
    function setupDeploy() public {
        vm.startPrank(USER);
        console.log("Setup");
        lockRewards16 = new LockRewards(LP, Y2K, WETH, MAX_EPOCHS, MIN_EPOCHS);
        ERC20(Y2K).transfer(address(lockRewards16), REWARDS_Y2K);
        ERC20(Y2K).transfer(address(lockRewards16), REWARDS_Y2K);
        // emit log_named_uint("balance of Y2K", ERC20(Y2K).balanceOf(USER));
        ERC20(WETH).transfer(address(lockRewards16), REWARDS_WETH);
        ERC20(WETH).transfer(address(lockRewards16), REWARDS_WETH);
        // emit log_named_uint("balance of WETH", ERC20(WETH).balanceOf(USER));

        // emit log_named_uint("balance of y2k16 ", ERC20(Y2K).balanceOf(address(lockRewards16)));
        // emit log_named_uint("balance of weth16", ERC20(WETH).balanceOf(address(lockRewards16)));

        lockRewards16.setNextEpoch_start(REWARDS_Y2K, REWARDS_WETH, EPOCH_DURATION_IN_DAYS,
         EPOCH_START);

        lockRewards16.setNextEpoch(REWARDS_Y2K, REWARDS_WETH,
         EPOCH_DURATION_IN_DAYS);

        vm.stopPrank();
    }

    function setupFork() public {
        lockRewards16 = LockRewards(0x25002Bc9266ac29D10eb655FE959902D650f9Fe0);
        emit log_named_uint("balance of LP", ERC20(LP).balanceOf(USER));
    }

    //******************************************************************************/
    /*                                      DEPOSIT
    ////////// ///////////////////////////////////////////////////////////////////*/

    function lockDeposit(uint _minEpoch) public {
        //setupDeploy();
        //setupFork();
        console.log("Deposit");
        vm.startPrank(USER);
        ERC20(LP).approve(address(lockRewards16), AMOUNT_DEPOSIT);
        lockRewards16.deposit(AMOUNT_DEPOSIT, _minEpoch);
        vm.stopPrank();

        emit log_named_uint("balance of LP", ERC20(LP).balanceOf(USER));
        //balance of lockRewards16
        emit log_named_uint("balance of lockRewards16", lockRewards16.balanceOf(USER));
        // viewAccount16();
    }

    function lockDepositAmount(uint _minEpoch, uint amount) public {
        //setupDeploy();
        //setupFork();
        console.log("Deposit");
        vm.startPrank(USER);
        ERC20(LP).approve(address(lockRewards16), amount);
        lockRewards16.deposit(amount, _minEpoch);
        vm.stopPrank();

        emit log_named_uint("balance of LP", ERC20(LP).balanceOf(USER));
        //balance of lockRewards16
        emit log_named_uint("balance of lockRewards16", lockRewards16.balanceOf(USER));
        // viewAccount16();
    }

    function testFuzzDeposit(uint epochs, uint amount) public {
        vm.assume(amount >= 0 && amount <= ERC20(LP).balanceOf(USER));
        vm.assume(epochs >= MIN_EPOCHS && epochs <= MAX_EPOCHS);
        setupDeploy();
        lockDepositAmount(epochs, amount);
        assertTrue(lockRewards16.balanceOf(USER) == amount, "balance of lockRewards16");
    }
    
    function testDeposit() public {
        setupDeploy();
        lockDeposit(MIN_EPOCHS);
        assertTrue(lockRewards16.balanceOf(USER) == AMOUNT_DEPOSIT, "balance of lockRewards16");    }

    function testReDeposit() public {
        setupDeploy();
        lockDeposit(MIN_EPOCHS);
        lockDeposit(0);
        assertTrue(lockRewards16.balanceOf(USER) == AMOUNT_DEPOSIT * 2, "balance of lockRewards16");
    }

    function testFailReDeposit() public {
        setupDeploy();
        lockDeposit(MIN_EPOCHS);
        lockDeposit(1);
    }

    function testIncreaseAmount() public {
        setupDeploy();
        lockDeposit(MIN_EPOCHS);
        lockDeposit(0);
        assertTrue(lockRewards16.balanceOf(USER) == AMOUNT_DEPOSIT * 2, "balance of lockRewards16");
    }

    //Deposits after the first epoch starts, cant claim on 2nd epoch, can claim on 3rd epoch
    function testDepositAfter1Epoch() public{
        setupDeploy();
        vm.warp(EPOCH_START + 1);
        console.log("Epoch 1");
        lockDeposit(MIN_EPOCHS);
        assertTrue(lockRewards16.balanceOf(USER) == AMOUNT_DEPOSIT, "balance of lockRewards16");
        (uint lockedEpochs, uint rewardedY2k, uint rewardedWeth) = viewAccount16();
        assertTrue(rewardedY2k == 0, "rewardedY2k");
        assertTrue(rewardedWeth == 0, "rewardedWeth");
        assertTrue(lockedEpochs == MIN_EPOCHS, "lockedEpochs");

        startNextEpoch(block.timestamp + EPOCH_DURATION_IN_DAYS * 1 days);
        console.log("Epoch 2");
        (lockedEpochs, rewardedY2k, rewardedWeth) = viewAccount16();
        assertTrue(rewardedY2k == 0, "rewardedY2k");
        assertTrue(rewardedWeth == 0, "rewardedWeth");
        assertTrue(lockedEpochs == MIN_EPOCHS, "lockedEpochs");

        startNextEpoch(block.timestamp + EPOCH_DURATION_IN_DAYS * 1 days);
        console.log("Epoch 3");

        claimRewards();
    }

    //Deposits before the first epoch starts, can claim on 2nd epoch
    function testDepositBefore1Epoch() public{
        setupDeploy();
        lockDeposit(MIN_EPOCHS);
        assertTrue(lockRewards16.balanceOf(USER) == AMOUNT_DEPOSIT, "balance of lockRewards16");
        (uint lockedEpochs, uint rewardedY2k, uint rewardedWeth) = viewAccount16();
        assertTrue(rewardedY2k == 0, "rewardedY2k");
        assertTrue(rewardedWeth == 0, "rewardedWeth");
        assertTrue(lockedEpochs == MIN_EPOCHS, "lockedEpochs");

        vm.warp(EPOCH_START + 1);
        // console.log("Epoch 2");
        startNextEpoch(block.timestamp + EPOCH_DURATION_IN_DAYS * 1 days);
        (uint lockedEpochsNew, uint rewardedY2kNew, uint rewardedWethNew) = viewAccount16();
        emit log_named_uint("lockedEpochsNew", lockedEpochsNew);
        emit log_named_uint("rewardedY2kNew", rewardedY2kNew);
        emit log_named_uint("rewardedWethNew", rewardedWethNew);
        assertTrue(rewardedY2kNew >= rewardedY2k, "rewardedY2k");
        assertTrue(rewardedWethNew >= rewardedWeth, "rewardedWeth");
        assertTrue(lockedEpochsNew == MIN_EPOCHS - 1, "lockedEpochs");

        claimRewards();
    }

    //******************************************************************************/
    /*                                      EPOCHS
    ////////// ///////////////////////////////////////////////////////////////////*/
    // function testRealEpoch() public {
    //     address _lock = 0xbDAA858Fd7b0DC05F8256330fAcB35de86283cA0;
    //     //address _y2k = 0x65c936f008BC34fE819bce9Fa5afD9dc2d49977f;
    //     address _weth = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    //     uint _rewardAmount = 14100000000000000000;
    //     uint _days = 7;

    //     vm.prank(0x5c84CF4d91Dc0acDe638363ec804792bB2108258); // treasury
    //     ERC20(_weth).transfer(address(_lock), _rewardAmount);

    //     vm.prank(0x16cBaDA408F7523452fF91c8387b1784d00d10D8); // y2k ops
    //     LockRewards(_lock).setNextEpoch_start(0, _rewardAmount, _days, 1672444844);

    //     (uint256 _start, uint256 _finish, uint256 _locked, uint256 _rewards1, uint256 _rewards2, bool _isSet) = LockRewards(_lock).getCurrentEpoch();
    //     emit log_named_uint("start", _start);
    //     emit log_named_uint("finish", _finish);
    //     emit log_named_uint("locked", _locked);
    //     emit log_named_uint("rewards1", _rewards1);
    //     emit log_named_uint("rewards2", _rewards2);
    //     if(_isSet) {
    //         emit log_named_string("isSet", "true");
    //     } else {
    //         emit log_named_string("isSet", "false");
    //     }
    // }

    function testClaimRealEpoch() public {
        address _lock = 0xbDAA858Fd7b0DC05F8256330fAcB35de86283cA0;
        //address _y2k = 0x65c936f008BC34fE819bce9Fa5afD9dc2d49977f;
        address _weth = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
        uint _rewardAmount = 14100000000000000000;
        uint _days = 1;

        vm.prank(0x5c84CF4d91Dc0acDe638363ec804792bB2108258); // treasury
        ERC20(_weth).transfer(address(_lock), _rewardAmount);

        vm.prank(0x16cBaDA408F7523452fF91c8387b1784d00d10D8); // y2k ops
        LockRewards(_lock).setNextEpoch(0, _rewardAmount, _days);

        (uint256 _start, uint256 _finish, uint256 _locked, uint256 _rewards1, uint256 _rewards2, bool _isSet) = LockRewards(_lock).getCurrentEpoch();
        emit log_named_uint("start", _start);
        emit log_named_uint("finish", _finish);
        emit log_named_uint("locked", _locked);
        emit log_named_uint("rewards1", _rewards1);
        emit log_named_uint("rewards2", _rewards2);
        if(_isSet) {
            emit log_named_string("isSet", "true");
        } else {
            emit log_named_string("isSet", "false");
        }

        vm.warp(block.timestamp + 1 days + 1);

        address anyUser = 0x35171ca1cee33E4A0047902804907D1a8BE92Cc3;
        vm.prank(anyUser); //user that staked
        (uint rewarded1, uint rewarded2) = LockRewards(_lock).claimReward();
        emit log_named_uint("rewarded1", rewarded1);
        emit log_named_uint("rewarded2", rewarded2);

    }

    function startNextEpoch(uint warpTime) public {
        vm.warp(warpTime);
        console2.log("block.timestamp", block.timestamp);
        
        vm.startPrank(USER);
        ERC20(Y2K).transfer(address(lockRewards16), REWARDS_Y2K);
        ERC20(Y2K).transfer(address(lockRewards16), REWARDS_Y2K);
        // emit log_named_uint("balance of Y2K", ERC20(Y2K).balanceOf(USER));
        ERC20(WETH).transfer(address(lockRewards16), REWARDS_WETH);
        ERC20(WETH).transfer(address(lockRewards16), REWARDS_WETH);

        // emit log_named_uint("balance of y2k16 ", ERC20(Y2K).balanceOf(address(lockRewards16)));
        // emit log_named_uint("balance of weth16", ERC20(WETH).balanceOf(address(lockRewards16)));

        lockRewards16.setNextEpoch(REWARDS_Y2K, REWARDS_WETH, EPOCH_DURATION_IN_DAYS);
        vm.stopPrank();

        (uint start, uint finish, uint locked, , , ) = lockRewards16.getNextEpoch();
        emit log_named_uint("start", start);
        emit log_named_uint("finish", finish);
        emit log_named_uint("locked", locked);
        // emit log_named_uint("rewards1", rewards1);
        // emit log_named_uint("rewards2", rewards2);
        viewCurrentEpoch();
    }
    
    function testWarpNextEpoch() public {
        setupDeploy();
        //epoch 1
        viewCurrentEpoch();
        console.log("Current epoch");
        console2.log("block.timestamp", block.timestamp);
        
        //epoch 2
        vm.warp(EPOCH_START + 1 days);
        lockRewards16.updateEpochs();
        console.log("Warp to next epoch");
        console2.log("block.timestamp", block.timestamp);
        viewCurrentEpoch();

        //epoch 3
        vm.warp(block.timestamp + (EPOCH_DURATION_IN_DAYS * 200 * 1 days));
        lockRewards16.updateEpochs();
        console.log("Warp to next epoch");
        console2.log("block.timestamp", block.timestamp);
        viewCurrentEpoch();
    }

    function testMultipleEpochs(uint any) public {
        vm.assume(any > 0 && any < MAX_EPOCHS - 1);
        setupDeploy();
        transitionNextEpoch();
        for(uint i = 0; i <= any; i++) {
            viewCurrentEpoch();
            startNextEpoch(block.timestamp +  1 days + 2);
            console.log("Warp to next epoch");
            console2.log("i current epoch", i);
        }
    }

    function transitionNextEpoch() public {
        (uint256 start,
        uint256 finish,
        uint256 locked,
        ,
        ,
        bool isSet) = lockRewards16.getCurrentEpoch();
        emit log_named_uint("start", start);
        emit log_named_uint("finish", finish);
        emit log_named_uint("locked", locked);
        // emit log_named_uint("rewards1", rewards1);
        // emit log_named_uint("rewards2", rewards2);
        if(isSet) {
            emit log_named_uint("isSet", 1);
        }else{
            emit log_named_uint("isSet", 0);
        }

        (uint256 start2,
        uint256 finish2,
        uint256 locked2,
        uint256 rewards12,
        uint256 rewards22,
        bool isSet2) = lockRewards16.getNextEpoch(); 
        emit log_named_uint("start2", start2);
        emit log_named_uint("finish2", finish2);
        emit log_named_uint("locked2", locked2);
        // emit log_named_uint("rewards12", rewards12);
        // emit log_named_uint("rewards22", rewards22);
        if(isSet2) {
            emit log_named_uint("isSet2", 1);
        }else{  
            emit log_named_uint("isSet2", 0);
        }

        console2.log("block.timestamp", block.timestamp);
        assertTrue(start < start2, "start < start2");
        assertTrue(finish < finish2, "finish < finish2");
        assertTrue(finish + 1 == start2, "finish == start2");
        
        // viewCurrentEpoch();
        startNextEpoch(start2);
        assertTrue(block.timestamp > finish, "block.timestamp > finish");
        // viewCurrentEpoch();

    }

    //******************************************************************************/
    /*                                      CLAIM
    ////////// ///////////////////////////////////////////////////////////////////*/

    function claimRewards() public {
        uint oldBalanceY2k = ERC20(Y2K).balanceOf(USER);
        uint oldBalanceWeth = ERC20(WETH).balanceOf(USER);
        
        vm.startPrank(USER);
        (uint rewarded1, uint rewarded2) = lockRewards16.claimReward();
        emit log_named_uint("rewarded Y2K ", rewarded1);
        emit log_named_uint("rewarded WETH", rewarded2);
        assertTrue(rewarded1 > 0, "rewarded1_16 > 0");
        assertTrue(rewarded2 > 0, "rewarded2_16 > 0");
        vm.stopPrank();

        uint newBalanceY2k = ERC20(Y2K).balanceOf(USER);
        uint newBalanceWeth = ERC20(WETH).balanceOf(USER);
        
        //balance of Y2K
        emit log_named_uint("old balance of Y2K ", oldBalanceY2k);
        emit log_named_uint("new balance of Y2K ", newBalanceY2k);
        //balance of WETH
        emit log_named_uint("old balance of WETH", oldBalanceWeth);
        emit log_named_uint("new balance of WETH", newBalanceWeth);

        viewCurrentEpoch();

        assertTrue(newBalanceY2k > oldBalanceY2k, "newBalanceY2k > oldBalanceY2k");
        assertTrue(newBalanceWeth > oldBalanceWeth, "newBalanceWeth > oldBalanceWeth");
    }

    function testClaimRewards() public {

        setupDeploy();
        lockDeposit(MIN_EPOCHS);
        console.log("Claim Rewards");

        //skip 1st epoch
        vm.warp(EPOCH_START + 1 days);
        (, uint y2kRewards16Old, uint wethRewards16Old) = viewAccount16();
        viewAccount16();

        claimRewards();        
        (, uint y2kRewards16New, uint wethRewards16New) = viewAccount16();

        assertTrue(y2kRewards16New < y2kRewards16Old, "y2kRewards16New < y2kRewards16Old");
        assertTrue(wethRewards16New < wethRewards16Old, "wethRewards16New < wethRewards16Old");

    }

    // write test for compound lock check if rewards are accrued
    function testCompoundRewards() public {
        testClaimRewards();
        (uint lockEpochs16Old, uint y2kBal16Old, uint wethBal16Old) = viewAccount16();
        lockDeposit(0);
        console.log("Compound rewards");
        startNextEpoch(block.timestamp + 1 days + 2);
        (uint lockEpochs16New, uint y2kBal16New, uint wethBal16New) = viewAccount16();

        assertTrue(y2kBal16New > y2kBal16Old, "y2kBal16New > y2kBal16Old");
        assertTrue(wethBal16New > wethBal16Old, "wethBal16New > wethBal16Old");
        assertTrue(lockEpochs16New == lockEpochs16Old - 1, "lockEpochs16New == lockEpochs16Old");
        emit log_named_uint("lockEpochs16New", lockEpochs16New);
        emit log_named_uint("lockEpochs16Old", lockEpochs16Old);

        claimRewards();
    }

    function testFuzzCompoundRewards(uint any) public {
        vm.assume(any < MIN_EPOCHS - 1 && any > 0);
        testClaimRewards();
        for(uint i = 0; i <= any; i++){
            (uint lockEpochs16Old, uint y2kBal16Old, uint wethBal16Old) = viewAccount16();
            lockDeposit(0);
            console.log("Compound rewards");
            startNextEpoch(block.timestamp + 1 days + 2);
            (uint lockEpochs16New, uint y2kBal16New, uint wethBal16New) = viewAccount16();

            assertTrue(y2kBal16New > y2kBal16Old, "y2kBal16New > y2kBal16Old");
            assertTrue(wethBal16New > wethBal16Old, "wethBal16New > wethBal16Old");
            assertTrue(lockEpochs16New == lockEpochs16Old - 1, "lockEpochs16New == lockEpochs16Old");
            emit log_named_uint("lockEpochs16New", lockEpochs16New);
            emit log_named_uint("lockEpochs16Old", lockEpochs16Old);

            claimRewards();
        }
    }
    // test for IncreaseLockEpochsNotGTZero()
    function testFailCompoundRewards() public {
        testClaimRewards();
        for(uint i = 0; i <= MIN_EPOCHS; i++){
            lockDeposit(0);
            console.log("Compound rewards");
            startNextEpoch(block.timestamp + 1 days + 2);
            viewAccount16();

            claimRewards();
        }
        // vm.expectRevert(LockRewards.selector.IncreaseLockEpochsNotGTZero());
    }
    
    //******************************************************************************/
    /*                                      EXECUTION
    ////////// ///////////////////////////////////////////////////////////////////*/

    function testFlow() public {
        setupDeploy();

        uint userAmount = 2 ether;

        //DEPOSIT
        console.log("Deposit");
        emit log_named_uint("user balance", ERC20(LP).balanceOf(USER));

        vm.startPrank(USER);

        ERC20(LP).approve(address(lockRewards16), userAmount);
        lockRewards16.deposit(userAmount, MIN_EPOCHS);
        emit log_named_uint("USER locked ", lockRewards16.balanceOf(USER));

        vm.stopPrank();

        //SKIP deposit period to 1st EPOCH
        vm.warp(EPOCH_START + 2);

        //SKIP 1ST EPOCH to 2nd EPOCH
        viewCurrentEpoch();
        (uint lockEpochs16Old, uint y2kBal16Old, uint wethBal16Old) = viewAccount16();
        emit log_named_uint("y2kBal16Old ", y2kBal16Old);
        emit log_named_uint("wethBal16Old", wethBal16Old);

        startNextEpoch(block.timestamp + 1 days + 2);
        (uint lockEpochs16New, uint y2kBal16New, uint wethBal16New) = viewAccount16();

        assertTrue(y2kBal16New > y2kBal16Old, "y2kBal16New > y2kBal16Old");
        assertTrue(wethBal16New > wethBal16Old, "wethBal16New > wethBal16Old");
        emit log_named_uint("y2kBal16New ", y2kBal16New);
        emit log_named_uint("wethBal16New", wethBal16New);

        //CLAIM REWARDS
        vm.startPrank(USER);

        (uint rewarded1, uint rewarded2) = lockRewards16.claimReward();
        emit log_named_uint("rewarded Y2K ", rewarded1);
        emit log_named_uint("rewarded WETH", rewarded2);
        assertTrue(rewarded1 > 0, "rewardedY2K_16 > 0");
        assertTrue(rewarded2 > 0, "rewardedWETH_16 > 0");

        vm.stopPrank();

        //COMPOUND REWARDS
        vm.startPrank(USER);

        ERC20(LP).approve(address(lockRewards16), rewarded1);
        lockRewards16.deposit(rewarded1, MIN_EPOCHS);
        emit log_named_uint("USER locked ", lockRewards16.balanceOf(USER));
        assertTrue(lockRewards16.balanceOf(USER) == userAmount + rewarded1, "USER locked == compounded");

        vm.stopPrank();

        //SKIP 2nd EPOCH to 3rd EPOCH
        console.log("check 3rd epoch compounded rewards");
        viewCurrentEpoch();
        (lockEpochs16Old, y2kBal16Old, wethBal16Old) = viewAccount16();
        emit log_named_uint("y2kBal16Old ", y2kBal16Old);
        emit log_named_uint("wethBal16Old", wethBal16Old);

        startNextEpoch(block.timestamp + 1 days + 2);
        (lockEpochs16New, y2kBal16New, wethBal16New) = viewAccount16();

        assertTrue(y2kBal16New > y2kBal16Old, "y2kBal16New > y2kBal16Old");
        assertTrue(wethBal16New > wethBal16Old, "wethBal16New > wethBal16Old");
        emit log_named_uint("y2kBal16New ", y2kBal16New);
        emit log_named_uint("wethBal16New", wethBal16New);

        //create a new epoch SKIP 3rd EPOCH to 4th EPOCH
        console.log("create a new 4th epoch AND SEE COMPOUNDED REWARDS");
        startNextEpoch(block.timestamp + 1 days + 2);
        (lockEpochs16New, y2kBal16New, wethBal16New) = viewAccount16();

        assertTrue(y2kBal16New > y2kBal16Old, "y2kBal16New > y2kBal16Old");
        assertTrue(wethBal16New > wethBal16Old, "wethBal16New > wethBal16Old");
        emit log_named_uint("y2kBal16New ", y2kBal16New);
        emit log_named_uint("wethBal16New", wethBal16New);
        
    }

    //******************************************************************************/
    /*                                      VIEW
    ////////// ///////////////////////////////////////////////////////////////////*/

    function viewAccount16() public returns(uint, uint, uint){
        console.log("View account 16");
        vm.startPrank(USER);
        (uint256 balance, uint256 lockEpochs, uint256 lastEpochPaid, 
        uint256 rewards1, uint256 rewards2) = lockRewards16.updateAccount();
        emit log_named_uint("balance", balance);
        emit log_named_uint("epochs locked", lockEpochs);
        emit log_named_uint("last epoch paid", lastEpochPaid);
        // emit log_named_uint("Y2K rewards1 ", rewards1);
        // emit log_named_uint("WETH rewards2", rewards2);
        vm.stopPrank();

        uint y2kBal = rewards1;
        uint wethBal = rewards2;
        return (lockEpochs, y2kBal, wethBal);
    }

    function viewCurrentEpoch() public {
        //lockrewards16 current epoch
        uint epoch16 = lockRewards16.currentEpoch();
        emit log_named_uint("current epoch16", epoch16);
    }
}