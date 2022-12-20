// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Test.sol";
import {Vault} from "../src/Vault.sol";
import {VaultFactory, TimeLock} from "../src/VaultFactory.sol";
import {Controller} from "../src/Controller.sol";
import {StakingRewards} from "../src/rewards/StakingRewards.sol";
import {RewardsBalanceHelper} from "./RewardsBalanceHelper.sol";
import {RewardBalances} from "../src/rewards/RewardBalances.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/// @author nexusflip
/// @author definedNever

contract RewardsBalanceTest is RewardsBalanceHelper {

    /*///////////////////////////////////////////////////////////////
                           ASSERT cases
    //////////////////////////////////////////////////////////////*/

    function testAppendStakingContractAddress() public {
        // Test adding staking contract to the list of staking contracts.
        vm.startPrank(admin);
        rewardBalances.appendStakingContractAddress(address(10));
        assertTrue(rewardBalances.stakingRewardsContracts(2) == address(10));
        vm.stopPrank();
    }

    function testAppendStakingContractAddressLoop() public {
        //Test adding looping staking contract set to the list of staking contracts.
        vm.startPrank(admin);

        address[] memory appendAddresses = new address[](2);
        appendAddresses[0] = address(11);
        appendAddresses[1] = address(12);

        rewardBalances.appendStakingContractAddressesLoop(appendAddresses);
        
        assertTrue(rewardBalances.stakingRewardsContracts(2) == address(11) 
        && rewardBalances.stakingRewardsContracts(3) == address(12));
    }

    function testRemoveStakingContractAddress() public {
        // Test removing staking contract to the list of staking contracts.
        vm.startPrank(admin);
        rewardBalances.removeStakingContractAddress(1);
        assertTrue(rewardBalances.stakingRewardsContracts(1) == address(0));
        vm.stopPrank();
    }

    function testBalanceOfRewards() public {
        //Test checking reward balance of an address that has rewards to claim
        vm.startPrank(admin);
        
        rewardsBal = 19333333333333209600;
        
        vm.deal(admin, AMOUNT * 2);
        vm.warp(beginEpoch - 1 days);
        
        StakingRewards(hedgeAddr).notifyRewardAmount(AMOUNT);
        StakingRewards(riskAddr).notifyRewardAmount(AMOUNT);

        Vault(hedge).depositETH{value: AMOUNT}(endEpoch, admin);
        Vault(risk).depositETH{value: AMOUNT}(endEpoch, admin);

        IERC1155(hedge).setApprovalForAll(hedgeAddr, true);
        IERC1155(risk).setApprovalForAll(riskAddr, true);
        StakingRewards(hedgeAddr).stake(AMOUNT);
        StakingRewards(riskAddr).stake(AMOUNT);

        rewardDuration = endEpoch - block.timestamp;
        periodFinish = block.timestamp + rewardDuration;

        vm.warp(periodFinish);

        StakingRewards(hedgeAddr).notifyRewardAmount(0);
        StakingRewards(riskAddr).notifyRewardAmount(0);

        address[] memory balanceAddresses = new address[](2);
        balanceAddresses[0] = hedgeAddr;
        balanceAddresses[1] = riskAddr;
        RewardBalances initBalance = new RewardBalances(balanceAddresses);

        uint256 balOfAdmin = initBalance.balanceOf(admin);
        emit log_named_uint("balOfAdmin", balOfAdmin);
        
        assertTrue(balOfAdmin == rewardsBal);

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                           REVERT cases
    //////////////////////////////////////////////////////////////*/
    
    function testRevertStakingContractAddresses() public {
        vm.startPrank(alice);
        vm.expectRevert(bytes("RewardBalances: FORBIDDEN"));
        rewardBalances.appendStakingContractAddress(address(1));
        vm.stopPrank();

        vm.startPrank(alice);
        vm.expectRevert(bytes("RewardBalances: FORBIDDEN"));
        rewardBalances.removeStakingContractAddress(1);
        vm.stopPrank();

        vm.startPrank(admin);
        vm.expectRevert(bytes("RewardBalances: OUT_OF_BOUNDS"));
        rewardBalances.removeStakingContractAddress(10);
        vm.stopPrank();
    }


}