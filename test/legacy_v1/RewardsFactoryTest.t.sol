// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Test.sol";
import {Vault} from "../../src/legacy_v1/Vault.sol";
import {VaultFactory} from "../../src/legacy_v1/VaultFactory.sol";
import {Controller} from "../../src/legacy_v1/Controller.sol";
import {RewardsFactory} from "../../src/legacy_v1/rewards/RewardsFactory.sol";
import {RewardsFactoryHelper} from "./RewardsFactoryHelper.sol";
import {FakeOracle} from "../oracles/FakeOracle.sol";
import {StakingRewards} from "../../src/legacy_v1/rewards/StakingRewards.sol";

/// @author nexusflip

contract RewardsFactoryTest is RewardsFactoryHelper {
    
    /*///////////////////////////////////////////////////////////////
                           ASSERT cases
    //////////////////////////////////////////////////////////////*/

    function testStakingRewards() public {
        //address exists
        vm.startPrank(ADMIN);
        vaultFactory.createNewMarket(FEE, TOKEN_STETH, DEPEG_AAA, beginEpoch, endEpoch, ORACLE_FRAX, "y2kSTETH_99*");
        rewardsFactory.createStakingRewards(SINGLE_MARKET_INDEX, endEpoch);
        (hedge, risk) = rewardsFactory.createStakingRewards(SINGLE_MARKET_INDEX, endEpoch);
        assert((hedge != address(0)) && (risk != address(0)));
        vm.stopPrank();

        //works for multiple/all markets
        vm.startPrank(ADMIN);
        // Create FRAX markets
        vaultFactory.createNewMarket(FEE, TOKEN_FRAX, DEPEG_AAA, beginEpoch, endEpoch, ORACLE_FRAX, "y2kFRAX_99*");
        vaultFactory.createNewMarket(FEE, TOKEN_FRAX, DEPEG_BBB, beginEpoch, endEpoch, ORACLE_FRAX, "y2kFRAX_97*");
        vaultFactory.createNewMarket(FEE, TOKEN_FRAX, DEPEG_CCC, beginEpoch, endEpoch, ORACLE_FRAX, "y2kFRAX_95*");

        // Create MIM markets
        vaultFactory.createNewMarket(FEE, TOKEN_MIM, DEPEG_AAA, beginEpoch, endEpoch, ORACLE_MIM, "y2kMIM_99*");
        vaultFactory.createNewMarket(FEE, TOKEN_MIM, DEPEG_BBB, beginEpoch, endEpoch, ORACLE_MIM, "y2kMIM_97*");
        vaultFactory.createNewMarket(FEE, TOKEN_MIM, DEPEG_CCC, beginEpoch, endEpoch, ORACLE_MIM, "y2kMIM_95*");

        // Create FEI markets
        vaultFactory.createNewMarket(FEE, TOKEN_FEI, DEPEG_AAA, beginEpoch, endEpoch, ORACLE_FEI, "y2kFEI_99*");
        vaultFactory.createNewMarket(FEE, TOKEN_FEI, DEPEG_BBB, beginEpoch, endEpoch, ORACLE_FEI, "y2kFEI_97*");
        vaultFactory.createNewMarket(FEE, TOKEN_FEI, DEPEG_CCC, beginEpoch, endEpoch, ORACLE_FEI, "y2kFEI_95*");

        // Create USDC markets
        vaultFactory.createNewMarket(FEE, TOKEN_USDC, DEPEG_AAA, beginEpoch, endEpoch, ORACLE_USDC, "y2kUSDC_99*");
        vaultFactory.createNewMarket(FEE, TOKEN_USDC, DEPEG_BBB, beginEpoch, endEpoch, ORACLE_USDC, "y2kUSDC_97*");
        vaultFactory.createNewMarket(FEE, TOKEN_USDC, DEPEG_CCC, beginEpoch, endEpoch, ORACLE_USDC, "y2kUSDC_95*");

        // Create DAI markets
        vaultFactory.createNewMarket(FEE, TOKEN_DAI, DEPEG_AAA, beginEpoch, endEpoch, ORACLE_DAI, "y2kDAI_99*");
        vaultFactory.createNewMarket(FEE, TOKEN_DAI, DEPEG_BBB, beginEpoch, endEpoch, ORACLE_DAI, "y2kDAI_97*");
        vaultFactory.createNewMarket(FEE, TOKEN_DAI, DEPEG_CCC, beginEpoch, endEpoch, ORACLE_DAI, "y2kDAI_95*");

        //to-do:change counter to non static variable
        for (uint256 i = SINGLE_MARKET_INDEX; i <= ALL_MARKETS_INDEX; i++){
            rewardsFactory.createStakingRewards(i, endEpoch);
            (hedgeLoop, riskLoop) = rewardsFactory.createStakingRewards(SINGLE_MARKET_INDEX, endEpoch);
            assert(((hedgeLoop != address(0))) && (riskLoop != address(0)));
        }
        vm.stopPrank();
    
    }


    function testPauseRewards() public {
        vm.startPrank(ADMIN);
        vaultFactory.createNewMarket(FEE, TOKEN_STETH, DEPEG_AAA, beginEpoch, endEpoch, ORACLE_FRAX, "y2kSTETH_99*");
        (hedge, risk) = rewardsFactory.createStakingRewards(1, endEpoch);

        StakingRewards(hedge).pause();
        StakingRewards(risk).pause();
        
        assertTrue(StakingRewards(hedge).paused() == true);
        assertTrue(StakingRewards(risk).paused() == true);
        vm.stopPrank();
    }

    /*///////////////////////////////////////////////////////////////
                           REVERT cases
    //////////////////////////////////////////////////////////////*/

    function testFailRewardsFactoryAdminMod() public {
        vm.startPrank(ADMIN);
        vaultFactory.createNewMarket(FEE, TOKEN_STETH, DEPEG_AAA, beginEpoch, endEpoch, ORACLE_FRAX, "y2kSTETH_99*");
        vm.stopPrank();

        //expecting revert
        vm.startPrank(ALICE);
        //vm.expectRevert(RewardsFactory.AddressNotAdmin.selector);
        rewardsFactory.createStakingRewards(SINGLE_MARKET_INDEX, endEpoch);
        vm.stopPrank();
    }

    function testRewardsEpochDoesNotExist() public {
        vm.startPrank(ADMIN);
        vaultFactory.createNewMarket(FEE, TOKEN_STETH, DEPEG_AAA, beginEpoch, endEpoch, ORACLE_FRAX, "y2kSTETH_99*");
        vm.stopPrank();

        //expecting revert
        vm.startPrank(ADMIN);
        vm.expectRevert(RewardsFactory.EpochDoesNotExist.selector);
        rewardsFactory.createStakingRewards(SINGLE_MARKET_INDEX, endEpoch + 2 days);
        vm.stopPrank();
    }

    function testWhenNotPaused() public {
        vm.startPrank(ADMIN);
        vaultFactory.createNewMarket(FEE, TOKEN_STETH, DEPEG_AAA, beginEpoch, endEpoch, ORACLE_FRAX, "y2kSTETH_99*");
        (hedge, risk) = rewardsFactory.createStakingRewards(1, endEpoch);

        StakingRewards(hedge).pause();
        StakingRewards(risk).pause();
        emit log_named_uint("Paused", 1);
        
        vm.expectRevert(bytes("Pausable: paused"));
        StakingRewards(hedge).getReward();
        vm.stopPrank();
    }

    /*///////////////////////////////////////////////////////////////
                           FUZZ cases
    //////////////////////////////////////////////////////////////*/

    function testFuzzRewardsFactoryAdminMod(uint256 index) public {
        //testing for ADMIN
        vm.assume(index >= SINGLE_MARKET_INDEX && index <= ALL_MARKETS_INDEX);
        vm.startPrank(ADMIN);
        for (uint256 i = 1; i <= index; i++){
            vaultFactory.createNewMarket(FEE, TOKEN_FRAX, DEPEG_AAA, beginEpoch, endEpoch, ORACLE_FRAX, "y2kFRAX_99*");
        }
        rewardsFactory.createStakingRewards(index, endEpoch);
        assertEq(vaultFactory.marketIndex(), index);
        vm.stopPrank();   
    }
}