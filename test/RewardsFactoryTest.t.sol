// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Test.sol";
import {Vault} from "../src/Vault.sol";
import {VaultFactory} from "../src/VaultFactory.sol";
import {Controller} from "../src/Controller.sol";
import {RewardsFactory} from "../src/rewards/RewardsFactory.sol";
import {RewardsFactoryHelper} from "./RewardsFactoryHelper.sol";
import {FakeOracle} from "./oracles/FakeOracle.sol";
import {StakingRewards} from "../src/rewards/StakingRewards.sol";

/// @author nexusflip

contract RewardsFactoryTest is RewardsFactoryHelper {
    /*///////////////////////////////////////////////////////////////
                           ASSERT cases
    //////////////////////////////////////////////////////////////*/

    function testStakingRewards() public {
        //address exists
        vm.startPrank(admin);
        vaultFactory.createNewMarket(FEE, tokenSTETH, DEPEG_AAA, beginEpoch, endEpoch, oracleFRAX, "y2kSTETH_99*");
        //to-do:expect emit CreatedStakingReward
        rewardsFactory.createStakingRewards(SINGLE_MARKET_INDEX, endEpoch);
        //to-do: assert if rewards exist and != 0
        (,address firstAdd) = rewardsFactory.createStakingRewards(SINGLE_MARKET_INDEX, endEpoch);
        (address secondAdd,) = rewardsFactory.createStakingRewards(SINGLE_MARKET_INDEX, endEpoch);
        assert((firstAdd != address(0)) && (secondAdd != address(0)));
        vm.stopPrank();

        //works for multiple/all markets
        vm.startPrank(admin);
        // Create FRAX markets
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_99*");
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_BBB, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_97*");
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_CCC, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_95*");

        // Create MIM markets
        vaultFactory.createNewMarket(FEE, tokenMIM, DEPEG_AAA, beginEpoch, endEpoch, oracleMIM, "y2kMIM_99*");
        vaultFactory.createNewMarket(FEE, tokenMIM, DEPEG_BBB, beginEpoch, endEpoch, oracleMIM, "y2kMIM_97*");
        vaultFactory.createNewMarket(FEE, tokenMIM, DEPEG_CCC, beginEpoch, endEpoch, oracleMIM, "y2kMIM_95*");

        // Create FEI markets
        vaultFactory.createNewMarket(FEE, tokenFEI, DEPEG_AAA, beginEpoch, endEpoch, oracleFEI, "y2kFEI_99*");
        vaultFactory.createNewMarket(FEE, tokenFEI, DEPEG_BBB, beginEpoch, endEpoch, oracleFEI, "y2kFEI_97*");
        vaultFactory.createNewMarket(FEE, tokenFEI, DEPEG_CCC, beginEpoch, endEpoch, oracleFEI, "y2kFEI_95*");

        // Create USDC markets
        vaultFactory.createNewMarket(FEE, tokenUSDC, DEPEG_AAA, beginEpoch, endEpoch, oracleUSDC, "y2kUSDC_99*");
        vaultFactory.createNewMarket(FEE, tokenUSDC, DEPEG_BBB, beginEpoch, endEpoch, oracleUSDC, "y2kUSDC_97*");
        vaultFactory.createNewMarket(FEE, tokenUSDC, DEPEG_CCC, beginEpoch, endEpoch, oracleUSDC, "y2kUSDC_95*");

        // Create DAI markets
        vaultFactory.createNewMarket(FEE, tokenDAI, DEPEG_AAA, beginEpoch, endEpoch, oracleDAI, "y2kDAI_99*");
        vaultFactory.createNewMarket(FEE, tokenDAI, DEPEG_BBB, beginEpoch, endEpoch, oracleDAI, "y2kDAI_97*");
        vaultFactory.createNewMarket(FEE, tokenDAI, DEPEG_CCC, beginEpoch, endEpoch, oracleDAI, "y2kDAI_95*");

        //to-do:change counter to non static variable
        for (uint256 i = SINGLE_MARKET_INDEX; i <= ALL_MARKETS_INDEX; i++){
            rewardsFactory.createStakingRewards(i, endEpoch);
            (,address firstAddLoop) = rewardsFactory.createStakingRewards(SINGLE_MARKET_INDEX, endEpoch);
            (address secondAddLoop,) = rewardsFactory.createStakingRewards(SINGLE_MARKET_INDEX, endEpoch);
            assert(((firstAddLoop != address(0))) && (secondAddLoop != address(0)));
        }
        vm.stopPrank();
    
    }


    function testPauseRewards() public {
        vm.startPrank(admin);
        vaultFactory.createNewMarket(FEE, tokenSTETH, DEPEG_AAA, beginEpoch, endEpoch, oracleFRAX, "y2kSTETH_99*");
        (address rHedge, address rRisk) = rewardsFactory.createStakingRewards(1, endEpoch);

        StakingRewards(rHedge).pause();
        StakingRewards(rRisk).pause();
        
        assertTrue(StakingRewards(rHedge).paused() == true);
        assertTrue(StakingRewards(rRisk).paused() == true);
        vm.stopPrank();
    }

    /*///////////////////////////////////////////////////////////////
                           REVERT cases
    //////////////////////////////////////////////////////////////*/

    function testFailRewardsFactoryAdminMod() public {
        vm.startPrank(admin);
        vaultFactory.createNewMarket(FEE, tokenSTETH, DEPEG_AAA, beginEpoch, endEpoch, oracleFRAX, "y2kSTETH_99*");
        vm.stopPrank();

        //expecting revert
        vm.startPrank(alice);
        //vm.expectRevert(RewardsFactory.AddressNotAdmin.selector);
        rewardsFactory.createStakingRewards(SINGLE_MARKET_INDEX, endEpoch);
        vm.stopPrank();
    }

    function testRewardsEpochDoesNotExist() public {
        vm.startPrank(admin);
        vaultFactory.createNewMarket(FEE, tokenSTETH, DEPEG_AAA, beginEpoch, endEpoch, oracleFRAX, "y2kSTETH_99*");
        vm.stopPrank();

        //expecting revert
        vm.startPrank(admin);
        vm.expectRevert(RewardsFactory.EpochDoesNotExist.selector);
        rewardsFactory.createStakingRewards(SINGLE_MARKET_INDEX, endEpoch + 2 days);
        vm.stopPrank();
    }

    function testWhenNotPaused() public {
        vm.startPrank(admin);
        vaultFactory.createNewMarket(FEE, tokenSTETH, DEPEG_AAA, beginEpoch, endEpoch, oracleFRAX, "y2kSTETH_99*");
        (hedge, risk) = rewardsFactory.createStakingRewards(1, endEpoch);

        StakingRewards(hedge).pause();
        StakingRewards(risk).pause();
        emit log_named_uint("Paused", 1);
        
        vm.expectRevert(bytes("Pausable: paused"));
        StakingRewards(hedge).getReward();
        vm.stopPrank();
    }

}