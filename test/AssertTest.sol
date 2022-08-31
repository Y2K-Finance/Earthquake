// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "forge-std/Test.sol";
import {Vault} from "../src/Vault.sol";
import {VaultFactory} from "../src/VaultFactory.sol";
import {Controller} from "../src/Controller.sol";
import {PegOracle} from "../src/oracles/PegOracle.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";
import "@chainlink/interfaces/AggregatorV3Interface.sol";
import {Helper} from "./Helper.sol";

import {FakeOracle} from "./oracles/FakeOracle.sol";
import {IWETH} from "./interfaces/IWETH.sol";


contract AssertTest is Helper {

    /*///////////////////////////////////////////////////////////////
                           CREATION functions
    //////////////////////////////////////////////////////////////*/

    function testPegOracleMarketCreation() public {
        PegOracle pegOracle = new PegOracle(oracleSTETH, oracleETH);
        PegOracle pegOracle2 = new PegOracle(oracleFRAX, oracleFEI);

        // //Eth price feed minus something to trigger depeg
        FakeOracle fakeOracle = new FakeOracle(oracleETH, 129919825000);
        PegOracle pegOracle3 = new PegOracle(address(fakeOracle), oracleETH);

        vm.startPrank(admin);
        vaultFactory.createNewMarket(FEE, tokenSTETH, depegAAA, beginEpoch, endEpoch, address(pegOracle), "y2kSTETH_99*SET");
        vaultFactory.createNewMarket(FEE, tokenFEI, depegBBB, beginEpoch, endEpoch, address(pegOracle2), "y2kSTETH_97*SET");
        vaultFactory.createNewMarket(FEE, WETH, depegCCC, beginEpoch, endEpoch, address(pegOracle3), "y2kSTETH_95*SET");
        vm.stopPrank();

        Deposit(1);
        Deposit(2);
        Deposit(3);

        int256 oracle1price1 = pegOracle.getOracle1_Price();
        int256 oracle1price2 = pegOracle.getOracle2_Price();
        emit log_named_int("oracle1price1", oracle1price1);
        emit log_named_int("oracle1price2", oracle1price2);
        (
            ,
            int256 price,
            ,
            ,
            
        ) = pegOracle.latestRoundData();
        emit log_named_int("oracle1price1 / oracle1price2", price);

        int256 oracle2price1 = pegOracle2.getOracle1_Price();
        int256 oracle2price2 = pegOracle2.getOracle2_Price();
        emit log_named_int("oracle2price1", oracle2price1);
        emit log_named_int("oracle2price2", oracle2price2);
        (
            ,
            price,
            ,
            ,
            
        ) = pegOracle2.latestRoundData();
        emit log_named_int("oracle2price1 / oracle2price2", price);

        int256 oracle3price1 = pegOracle3.getOracle1_Price();
        int256 oracle3price2 = pegOracle3.getOracle2_Price();
        emit log_named_int("oracle3price1", oracle3price1);
        emit log_named_int("oracle3price2", oracle3price2);
        (
            ,
            price,
            ,
            ,
            
        ) = pegOracle3.latestRoundData();
        emit log_named_int("oracle3price1 / oracle3price2", price);

        ControllerEndEpoch(tokenSTETH,1);
        ControllerEndEpoch(tokenFEI,2);
        ControllerEndEpoch(WETH,3);

        Withdraw();
    }

    function testALLMarketsCreation() public {
        vm.startPrank(admin);

        // Create FRAX market
        //index 1
        vaultFactory.createNewMarket(FEE, tokenFRAX, depegAAA, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_99*SET");
        assertTrue(Vault(vaultFactory.getVaults(1)[0]).strikePrice() == 99 * 10e16, "Decimals incorrect");
        //index 2
        vaultFactory.createNewMarket(FEE, tokenFRAX, depegBBB, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_97*SET");
        //index 3
        vaultFactory.createNewMarket(FEE, tokenFRAX, depegCCC, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_95*SET");

        // Create MIM market
        //index 4
        vaultFactory.createNewMarket(FEE, tokenMIM, depegAAA, beginEpoch, endEpoch, oracleMIM, "y2kMIM_99*SET");
        //index 5
        vaultFactory.createNewMarket(FEE, tokenMIM, depegBBB, beginEpoch, endEpoch, oracleMIM, "y2kMIM_97*SET");
        //index 6
        vaultFactory.createNewMarket(FEE, tokenMIM, depegCCC, beginEpoch, endEpoch, oracleMIM, "y2kMIM_95*SET");

        // Create FEI market
        //index 7
        vaultFactory.createNewMarket(FEE, tokenFEI, depegAAA, beginEpoch, endEpoch, oracleFEI, "y2kFEI_99*SET");
        //index 8
        vaultFactory.createNewMarket(FEE, tokenFEI, depegBBB, beginEpoch, endEpoch, oracleFEI, "y2kFEI_97*SET");
        //index 9
        vaultFactory.createNewMarket(FEE, tokenFEI, depegCCC, beginEpoch, endEpoch, oracleFEI, "y2kFEI_95*SET");

        // Create USDC market
        //index 10
        vaultFactory.createNewMarket(FEE, tokenUSDC, depegAAA, beginEpoch, endEpoch, oracleUSDC, "y2kUSDC_99*SET");
        //index 11
        vaultFactory.createNewMarket(FEE, tokenUSDC, depegBBB, beginEpoch, endEpoch, oracleUSDC, "y2kUSDC_97*SET");
        //index 12
        vaultFactory.createNewMarket(FEE, tokenUSDC, depegCCC, beginEpoch, endEpoch, oracleUSDC, "y2kUSDC_95*SET");

        // Create DAI market
        //index 13
        vaultFactory.createNewMarket(FEE, tokenDAI, depegAAA, beginEpoch, endEpoch, oracleDAI, "y2kDAI_99*SET");
        //index 14
        vaultFactory.createNewMarket(FEE, tokenDAI, depegBBB, beginEpoch, endEpoch, oracleDAI, "y2kDAI_97*SET");
        //index 15
        vaultFactory.createNewMarket(FEE, tokenDAI, depegCCC, beginEpoch, endEpoch, oracleDAI, "y2kDAI_95*SET");
        
        vm.stopPrank();
    }

    function testALLMarketsDeployMore() public {

        testALLMarketsCreation();

        vm.startPrank(admin);

        // Deploy more FRAX market
        vaultFactory.deployMoreAssets(1, beginEpoch + 30 days, endEpoch + 30 days, FEE);
        vaultFactory.deployMoreAssets(2, beginEpoch + 30 days, endEpoch + 30 days, FEE);
        vaultFactory.deployMoreAssets(3, beginEpoch + 30 days, endEpoch + 30 days, FEE);

        // Deploy more MIM market
        vaultFactory.deployMoreAssets(4, beginEpoch + 30 days, endEpoch + 30 days, FEE);
        vaultFactory.deployMoreAssets(5, beginEpoch + 30 days, endEpoch + 30 days, FEE);
        vaultFactory.deployMoreAssets(6, beginEpoch + 30 days, endEpoch + 30 days, FEE);

        // Deploy more FEI market
        vaultFactory.deployMoreAssets(7, beginEpoch + 30 days, endEpoch + 30 days, FEE);
        vaultFactory.deployMoreAssets(8, beginEpoch + 30 days, endEpoch + 30 days, FEE);
        vaultFactory.deployMoreAssets(9, beginEpoch + 30 days, endEpoch + 30 days, FEE);

        // Deploy more USDC market
        vaultFactory.deployMoreAssets(10, beginEpoch + 30 days, endEpoch + 30 days, FEE);
        vaultFactory.deployMoreAssets(11, beginEpoch + 30 days, endEpoch + 30 days, FEE);
        vaultFactory.deployMoreAssets(12, beginEpoch + 30 days, endEpoch + 30 days, FEE);

        // Deploy more DAI market
        vaultFactory.deployMoreAssets(13, beginEpoch + 30 days, endEpoch + 30 days, FEE);
        vaultFactory.deployMoreAssets(14, beginEpoch + 30 days, endEpoch + 30 days, FEE);
        vaultFactory.deployMoreAssets(15, beginEpoch + 30 days, endEpoch + 30 days, FEE);

        vm.stopPrank();
    }

    /*///////////////////////////////////////////////////////////////
                           DEPOSIT functions
    //////////////////////////////////////////////////////////////*/

    function testDeposit() public {
        vm.deal(alice, 10 ether);
        vm.deal(bob, 20 ether);
        vm.deal(chad, 100 ether);
        vm.deal(degen, 200 ether);

        vm.prank(admin);
        vaultFactory.createNewMarket(FEE, tokenFRAX, depegAAA, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_99*SET");

        address hedge = vaultFactory.getVaults(1)[0];
        address risk = vaultFactory.getVaults(1)[1];
        
        Vault vHedge = Vault(hedge);
        Vault vRisk = Vault(risk);

        //ALICE hedge DEPOSIT
        vm.startPrank(alice);
        ERC20(WETH).approve(hedge, 10 ether);
        vHedge.depositETH{value: 10 ether}(endEpoch, alice);
        vm.stopPrank();

        //BOB hedge DEPOSIT
        vm.startPrank(bob);
        ERC20(WETH).approve(hedge, 20 ether);
        vHedge.depositETH{value: 20 ether}(endEpoch, bob);

        assertTrue(vHedge.balanceOf(bob,endEpoch) == 20 ether);
        vm.stopPrank();

        //CHAD risk DEPOSIT
        vm.startPrank(chad);
        ERC20(WETH).approve(risk, 100 ether);
        vRisk.depositETH{value: 100 ether}(endEpoch, chad);

        assertTrue(vRisk.balanceOf(chad,endEpoch) == (100 ether));
        vm.stopPrank();

        //DEGEN risk DEPOSIT
        vm.startPrank(degen);
        ERC20(WETH).approve(risk, 200 ether);
        vRisk.depositETH{value: 200 ether}(endEpoch, degen);

        assertTrue(vRisk.balanceOf(degen,endEpoch) == (200 ether));
        vm.stopPrank();
    }

    /*///////////////////////////////////////////////////////////////
                           CONTROLLER functions
    //////////////////////////////////////////////////////////////*/

    function testControllerDepeg() public{

        DepositDepeg();

        address hedge = vaultFactory.getVaults(1)[0];
        address risk = vaultFactory.getVaults(1)[1];

        Vault vHedge = Vault(hedge);
        Vault vRisk = Vault(risk);

        vm.warp(beginEpoch + 10 days);

        emit log_named_int("strike price", vHedge.strikePrice());
        emit log_named_int("oracle price", controller.getLatestPrice(tokenFRAX));

        controller.triggerDepeg(1, endEpoch);

        assertTrue(vHedge.totalAssets(endEpoch) == vRisk.idClaimTVL(endEpoch), "Claim TVL Risk not equal to Total Tvl Hedge");
        assertTrue(vRisk.totalAssets(endEpoch) == vHedge.idClaimTVL(endEpoch), "Claim TVL Hedge not equal to Total Tvl Risk");
    }

    function testControllerEndEpoch() public{

        testDeposit();

        address hedge = vaultFactory.getVaults(1)[0];
        address risk = vaultFactory.getVaults(1)[1];

        Vault vHedge = Vault(hedge);
        Vault vRisk = Vault(risk);

        vm.warp(endEpoch + 1 days);

        emit log_named_int("strike price", vHedge.strikePrice());
        emit log_named_int("oracle price", controller.getLatestPrice(tokenFRAX));

        controller.triggerEndEpoch(1, endEpoch);

        assertTrue(vHedge.totalAssets(endEpoch) == vRisk.idClaimTVL(endEpoch), "Claim TVL not equal");
        //emit log_named_uint("claim tvl", vHedge.idClaimTVL(endEpoch));
        assertTrue(0 == vHedge.idClaimTVL(endEpoch), "Hedge Claim TVL not zero");
    }

    /*///////////////////////////////////////////////////////////////
                           WITHDRAW functions
    //////////////////////////////////////////////////////////////*/

    function testWithdrawDepeg() public {
        testControllerDepeg();

        address hedge = vaultFactory.getVaults(1)[0];
        address risk = vaultFactory.getVaults(1)[1];

        Vault vHedge = Vault(hedge);
        Vault vRisk = Vault(risk);

        uint assets;

        //ALICE hedge WITHDRAW
        vm.startPrank(alice);
        assets = vHedge.balanceOf(alice,endEpoch);
        vHedge.withdraw(endEpoch, assets, alice, alice);

        assertTrue(vHedge.balanceOf(alice,endEpoch) == 0);
        uint256 entitledShares = vHedge.beforeWithdraw(endEpoch, assets);
        assertTrue(entitledShares - vHedge.calculateWithdrawalFeeValue(entitledShares,endEpoch) == ERC20(WETH).balanceOf(alice));

        vm.stopPrank();

        //BOB hedge WITHDRAW
        vm.startPrank(bob);
        assets = vHedge.balanceOf(bob,endEpoch);
        vHedge.withdraw(endEpoch, assets, bob, bob);
        
        assertTrue(vHedge.balanceOf(bob,endEpoch) == 0);
        entitledShares = vHedge.beforeWithdraw(endEpoch, assets);
        assertTrue(entitledShares - vHedge.calculateWithdrawalFeeValue(entitledShares,endEpoch) == ERC20(WETH).balanceOf(bob));

        vm.stopPrank();

        emit log_named_uint("hedge balance", ERC20(WETH).balanceOf(address(vHedge)));

        //CHAD risk WITHDRAW
        vm.startPrank(chad);
        assets = vRisk.balanceOf(chad,endEpoch);
        vRisk.withdraw(endEpoch, assets, chad, chad);

        assertTrue(vRisk.balanceOf(chad,endEpoch) == 0);
        entitledShares = vRisk.beforeWithdraw(endEpoch, assets);
        assertTrue(entitledShares - vRisk.calculateWithdrawalFeeValue(entitledShares,endEpoch) == ERC20(WETH).balanceOf(chad));

        vm.stopPrank();

        //DEGEN risk WITHDRAW
        vm.startPrank(degen);
        assets = vRisk.balanceOf(degen,endEpoch);
        vRisk.withdraw(endEpoch, assets, degen, degen);

        assertTrue(vRisk.balanceOf(degen,endEpoch) == 0);
        entitledShares = vRisk.beforeWithdraw(endEpoch, assets);
        assertTrue(entitledShares - vRisk.calculateWithdrawalFeeValue(entitledShares,endEpoch) == ERC20(WETH).balanceOf(degen));

        vm.stopPrank();

        emit log_named_uint("risk balance", ERC20(WETH).balanceOf(address(vRisk)));
    }
}