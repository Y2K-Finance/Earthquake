// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Test.sol";
import {Vault} from "../src/Vault.sol";
import {VaultFactory} from "../src/VaultFactory.sol";
import {Controller} from "../src/Controller.sol";
import {PegOracle} from "../src/oracles/PegOracle.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";
import "@chainlink/interfaces/AggregatorV3Interface.sol";
import {FuzzHelper} from "./FuzzHelper.sol";
import {FakeOracle} from "./oracles/FakeOracle.sol";
import {IWETH} from "./interfaces/IWETH.sol";

contract FuzzTest is FuzzHelper{

    function testFuzzDeposit(uint256 ethValue) public {
        vm.deal(alice, ethValue);
        vm.deal(bob, ethValue * BOB_MULTIPLIER);
        vm.deal(chad, ethValue * CHAD_MULTIPLIER);
        vm.deal(degen, ethValue * DEGEN_MULTIPLIER);

        vm.prank(admin);
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_99*");

        address hedge = vaultFactory.getVaults(1)[0];
        address risk = vaultFactory.getVaults(1)[1];
        
        Vault vHedge = Vault(hedge);
        Vault vRisk = Vault(risk);

        //ALICE hedge DEPOSIT
        vm.startPrank(alice);
        ERC20(WETH).approve(hedge, ethValue);
        vHedge.depositETH{value: ethValue}(endEpoch, alice);
        vm.stopPrank();

        //BOB hedge DEPOSIT
        vm.startPrank(bob);
        ERC20(WETH).approve(hedge, ethValue * BOB_MULTIPLIER);
        vHedge.depositETH{value: ethValue * BOB_MULTIPLIER}(endEpoch, bob);

        assertTrue(vHedge.balanceOf(bob,endEpoch) == ethValue * BOB_MULTIPLIER);
        vm.stopPrank();

        //CHAD risk DEPOSIT
        vm.startPrank(chad);
        ERC20(WETH).approve(risk, ethValue * CHAD_MULTIPLIER);
        vRisk.depositETH{value: ethValue * CHAD_MULTIPLIER}(endEpoch, chad);

        assertTrue(vRisk.balanceOf(chad,endEpoch) == (ethValue * CHAD_MULTIPLIER));
        vm.stopPrank();

        //DEGEN risk DEPOSIT
        vm.startPrank(degen);
        ERC20(WETH).approve(risk, ethValue * DEGEN_MULTIPLIER);
        vRisk.depositETH{value: ethValue * DEGEN_MULTIPLIER}(endEpoch, degen);

        assertTrue(vRisk.balanceOf(degen,endEpoch) == (ethValue * DEGEN_MULTIPLIER));
        vm.stopPrank();
    }

    function testFuzzGetHashedIndex(uint256 index) public{
        vm.startPrank(admin);
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_99*");
        bytes32 hashedIndex = rewardsFactory.getHashedIndex(index, beginEpoch);
        assertEq(hashedIndex, keccak256(abi.encode(index, beginEpoch)));
        vm.stopPrank();
    }

    /*function testFuzzControllerDepeg(uint256 index) public{
        vm.assume(index >= SINGLE_MARKET_INDEX && index <= ALL_MARKETS_INDEX);
        vm.startPrank(admin);
        FakeOracle fakeOracle = new FakeOracle(oracleFRAX, 995);
        for (uint256 i = SINGLE_MARKET_INDEX; i <= index; i++){
            vaultFactory.createNewMarket(DEFAULT_TEST_FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, address(fakeOracle), "y2kFRAX_99*");
        }
        vm.stopPrank();

        Deposit(SINGLE_MARKET_INDEX);
        DepositDepeg(index);

        address hedge = vaultFactory.getVaults(1)[0];
        address risk = vaultFactory.getVaults(1)[1];

        Vault vHedge = Vault(hedge);
        Vault vRisk = Vault(risk);

        vm.warp(beginEpoch + 10 days);

        emit log_named_int("strike price", vHedge.strikePrice());
        emit log_named_int("oracle price", controller.getLatestPrice(tokenFRAX));

        controller.triggerDepeg(index, endEpoch);

        assertTrue(vHedge.totalAssets(endEpoch) == vRisk.idClaimTVL(endEpoch), "Claim TVL Risk not equal to Total Tvl Hedge");
        assertTrue(vRisk.totalAssets(endEpoch) == vHedge.idClaimTVL(endEpoch), "Claim TVL Hedge not equal to Total Tvl Risk");
    }*/

    function testFuzzVaultFactoryMarketCreation(uint256 index) public {
        vm.assume(index >= SINGLE_MARKET_INDEX && index <= ALL_MARKETS_INDEX);
        vm.startPrank(admin);
        FakeOracle fakeOracle = new FakeOracle(oracleFRAX, 90995265);
        for (uint256 i = 1; i <= index; i++){
            vaultFactory.createNewMarket(DEFAULT_TEST_FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, address(fakeOracle), "y2kFRAX_99*");
        }
        assertEq(vaultFactory.marketIndex(), index);
        vm.stopPrank();
    }

    function testFuzzRewardsFactoryAdminMod(uint256 index) public {
        //testing for admin
        vm.assume(index >= SINGLE_MARKET_INDEX && index <= ALL_MARKETS_INDEX);
        vm.startPrank(admin);
        for (uint256 i = 1; i <= index; i++){
            vaultFactory.createNewMarket(DEFAULT_TEST_FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_99*");
        }
        rewardsFactory.createStakingRewards(index, endEpoch, REWARDS_DURATION, REWARD_RATE);
        assertEq(vaultFactory.marketIndex(), index);
        vm.stopPrank();   
    }
    
    function testFuzzWithdraw(uint256 ethValue) public {
        vm.assume(ethValue >= 1);
        testFuzzDeposit(ethValue);

        address hedge = vaultFactory.getVaults(1)[0];
        address risk = vaultFactory.getVaults(1)[1];

        Vault vHedge = Vault(hedge);
        Vault vRisk = Vault(risk);

        uint assets;

        vm.startPrank(admin);
        vm.warp(endEpoch + 1 days);
        vm.stopPrank();
        controller.triggerEndEpoch(vaultFactory.marketIndex(), endEpoch);
        //ALICE hedge WITHDRAW
        vm.startPrank(alice);
        assets = vHedge.balanceOf(alice,endEpoch);
        vHedge.withdraw(endEpoch, assets, alice, alice);

        assertTrue(vHedge.balanceOf(alice,endEpoch) == NULL_VALUE);
        uint256 entitledShares = vHedge.beforeWithdraw(endEpoch, assets);
        assertTrue(entitledShares - vHedge.calculateWithdrawalFeeValue(entitledShares,endEpoch) == ERC20(WETH).balanceOf(alice));

        vm.stopPrank();

        //BOB hedge WITHDRAW
        vm.startPrank(bob);
        assets = vHedge.balanceOf(bob,endEpoch);
        vHedge.withdraw(endEpoch, assets, bob, bob);
        
        assertTrue(vHedge.balanceOf(bob,endEpoch) == NULL_VALUE);
        entitledShares = vHedge.beforeWithdraw(endEpoch, assets);
        assertTrue(entitledShares - vHedge.calculateWithdrawalFeeValue(entitledShares,endEpoch) == ERC20(WETH).balanceOf(bob));

        vm.stopPrank();

        emit log_named_uint("hedge balance", ERC20(WETH).balanceOf(address(vHedge)));

        //CHAD risk WITHDRAW
        vm.startPrank(chad);
        assets = vRisk.balanceOf(chad,endEpoch);
        vRisk.withdraw(endEpoch, assets, chad, chad);

        assertTrue(vRisk.balanceOf(chad,endEpoch) == NULL_VALUE);
        entitledShares = vRisk.beforeWithdraw(endEpoch, assets);
        assertTrue(entitledShares - vRisk.calculateWithdrawalFeeValue(entitledShares,endEpoch) == ERC20(WETH).balanceOf(chad));

        vm.stopPrank();

        //DEGEN risk WITHDRAW
        vm.startPrank(degen);
        assets = vRisk.balanceOf(degen,endEpoch);
        vRisk.withdraw(endEpoch, assets, degen, degen);

        assertTrue(vRisk.balanceOf(degen,endEpoch) == NULL_VALUE);
        entitledShares = vRisk.beforeWithdraw(endEpoch, assets);
        assertTrue(entitledShares - vRisk.calculateWithdrawalFeeValue(entitledShares,endEpoch) == ERC20(WETH).balanceOf(degen));

        vm.stopPrank();

        emit log_named_uint("risk balance", ERC20(WETH).balanceOf(address(vRisk)));

    }

    





}