// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "forge-std/Test.sol";
import {Vault} from "../src/Vault.sol";
import {VaultFactory} from "../src/VaultFactory.sol";
import {Controller} from "../src/Controller.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";
import "@chainlink/interfaces/AggregatorV3Interface.sol";


import {IWETH} from "./interfaces/IWETH.sol";

contract AssertTest is Test {

    VaultFactory vaultFactory;
    Controller controller;

    address WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

    address tokenFRAX = 0x17FC002b466eEc40DaE837Fc4bE5c67993ddBd6F;
    address tokenMIM = 0xFEa7a6a0B346362BF88A9e4A88416B77a57D6c2A;
    address tokenFEI = 0x4A717522566C7A09FD2774cceDC5A8c43C5F9FD2;
    address tokenUSDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address tokenDAI = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;

    address oracleFRAX = 0x0809E3d38d1B4214958faf06D8b1B1a2b73f2ab8;
    address oracleMIM = 0x87121F6c9A9F6E90E59591E4Cf4804873f54A95b;
    address oracleFEI = 0x7c4720086E6feb755dab542c46DE4f728E88304d;
    address oracleUSDC = 0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3;
    address oracleDAI = 0xc5C8E77B397E531B8EC06BFb0048328B30E9eCfB;

    address admin = address(1);

    address alice = address(2);
    address bob = address(3);
    address chad = address(4);
    address degen = address(5);

    int256 depegAAA = 99;
    int256 depegBBB = 97;
    int256 depegCCC = 95;
    int256 depegPrice = 109;

    uint256 endEpoch;
    uint256 beginEpoch;
    
    function setUp() public {
        vaultFactory = new VaultFactory(admin,WETH,admin);
        controller = new Controller(address(vaultFactory),admin);

        vm.prank(admin);
        vaultFactory.setController(address(controller));

        endEpoch = block.timestamp + 30 days;
        beginEpoch = block.timestamp + 2 days;
    }

    function testALLMarketsCreation() public {
        vm.startPrank(admin);

        // Create FRAX market
        //index 1
        vaultFactory.createNewMarket(50, tokenFRAX, depegAAA, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_99*SET");
        // assertTrue(Vault(vaultFactory.getVaults(1)[0]).strikePrice() == 99 * 10e16, "Decimals incorrect");
        //index 2
        vaultFactory.createNewMarket(50, tokenFRAX, depegBBB, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_97*SET");
        //index 3
        vaultFactory.createNewMarket(50, tokenFRAX, depegCCC, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_95*SET");

        // Create MIM market
        //index 4
        vaultFactory.createNewMarket(50, tokenMIM, depegAAA, beginEpoch, endEpoch, oracleMIM, "y2kMIM_99*SET");
        //index 5
        vaultFactory.createNewMarket(50, tokenMIM, depegBBB, beginEpoch, endEpoch, oracleMIM, "y2kMIM_97*SET");
        //index 6
        vaultFactory.createNewMarket(50, tokenMIM, depegCCC, beginEpoch, endEpoch, oracleMIM, "y2kMIM_95*SET");

        // Create FEI market
        //index 7
        vaultFactory.createNewMarket(50, tokenFEI, depegAAA, beginEpoch, endEpoch, oracleFEI, "y2kFEI_99*SET");
        //index 8
        vaultFactory.createNewMarket(50, tokenFEI, depegBBB, beginEpoch, endEpoch, oracleFEI, "y2kFEI_97*SET");
        //index 9
        vaultFactory.createNewMarket(50, tokenFEI, depegCCC, beginEpoch, endEpoch, oracleFEI, "y2kFEI_95*SET");

        // Create USDC market
        //index 10
        vaultFactory.createNewMarket(50, tokenUSDC, depegAAA, beginEpoch, endEpoch, oracleUSDC, "y2kUSDC_99*SET");
        //index 11
        vaultFactory.createNewMarket(50, tokenUSDC, depegBBB, beginEpoch, endEpoch, oracleUSDC, "y2kUSDC_97*SET");
        //index 12
        vaultFactory.createNewMarket(50, tokenUSDC, depegCCC, beginEpoch, endEpoch, oracleUSDC, "y2kUSDC_95*SET");

        // Create DAI market
        //index 13
        vaultFactory.createNewMarket(50, tokenDAI, depegAAA, beginEpoch, endEpoch, oracleDAI, "y2kDAI_99*SET");
        //index 14
        vaultFactory.createNewMarket(50, tokenDAI, depegBBB, beginEpoch, endEpoch, oracleDAI, "y2kDAI_97*SET");
        //index 15
        vaultFactory.createNewMarket(50, tokenDAI, depegCCC, beginEpoch, endEpoch, oracleDAI, "y2kDAI_95*SET");
        
        vm.stopPrank();
    }

    function testALLMarketsDeployMore() public {

        testALLMarketsCreation();

        vm.startPrank(admin);

        // Deploy more FRAX market
        vaultFactory.deployMoreAssets(1, beginEpoch + 30 days, endEpoch + 30 days);
        vaultFactory.deployMoreAssets(2, beginEpoch + 30 days, endEpoch + 30 days);
        vaultFactory.deployMoreAssets(3, beginEpoch + 30 days, endEpoch + 30 days);

        // Deploy more MIM market
        vaultFactory.deployMoreAssets(4, beginEpoch + 30 days, endEpoch + 30 days);
        vaultFactory.deployMoreAssets(5, beginEpoch + 30 days, endEpoch + 30 days);
        vaultFactory.deployMoreAssets(6, beginEpoch + 30 days, endEpoch + 30 days);

        // Deploy more FEI market
        vaultFactory.deployMoreAssets(7, beginEpoch + 30 days, endEpoch + 30 days);
        vaultFactory.deployMoreAssets(8, beginEpoch + 30 days, endEpoch + 30 days);
        vaultFactory.deployMoreAssets(9, beginEpoch + 30 days, endEpoch + 30 days);

        // Deploy more USDC market
        vaultFactory.deployMoreAssets(10, beginEpoch + 30 days, endEpoch + 30 days);
        vaultFactory.deployMoreAssets(11, beginEpoch + 30 days, endEpoch + 30 days);
        vaultFactory.deployMoreAssets(12, beginEpoch + 30 days, endEpoch + 30 days);

        // Deploy more DAI market
        vaultFactory.deployMoreAssets(13, beginEpoch + 30 days, endEpoch + 30 days);
        vaultFactory.deployMoreAssets(14, beginEpoch + 30 days, endEpoch + 30 days);
        vaultFactory.deployMoreAssets(15, beginEpoch + 30 days, endEpoch + 30 days);

        vm.stopPrank();
    }

    function testDeposit() public {
        vm.deal(alice, 10 ether);
        vm.deal(bob, 20 ether);
        vm.deal(chad, 100 ether);
        vm.deal(degen, 200 ether);

        vm.prank(admin);
        vaultFactory.createNewMarket(50, tokenFRAX, depegAAA, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_99*SET");

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

    function DepositDepeg() public {
        vm.deal(alice, 10 ether);
        vm.deal(bob, 20 ether);
        vm.deal(chad, 100 ether);
        vm.deal(degen, 200 ether);

        vm.prank(admin);
        vaultFactory.createNewMarket(50, tokenFRAX, depegPrice, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_99*SET");

        address hedge = vaultFactory.getVaults(1)[0];
        address risk = vaultFactory.getVaults(1)[1];
        
        Vault vHedge = Vault(hedge);
        Vault vRisk = Vault(risk);

        //ALICE hedge DEPOSIT
        vm.startPrank(alice);
        ERC20(WETH).approve(hedge, 10 ether);
        vHedge.depositETH{value: 10 ether}(endEpoch, alice);

        assertTrue(vHedge.balanceOf(alice,endEpoch) == (10 ether));
        vm.stopPrank();

        //BOB hedge DEPOSIT
        vm.startPrank(bob);
        ERC20(WETH).approve(hedge, 20 ether);
        vHedge.depositETH{value: 20 ether}(endEpoch, bob);

        assertTrue(vHedge.balanceOf(bob,endEpoch) == (20 ether));
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

        vm.stopPrank();

        //BOB hedge WITHDRAW
        vm.startPrank(bob);
        assets = vHedge.balanceOf(bob,endEpoch);
        vHedge.withdraw(endEpoch, assets, bob, bob);

        vm.stopPrank();

        //CHAD risk WITHDRAW
        vm.startPrank(chad);
        assets = vRisk.balanceOf(chad,endEpoch);
        vRisk.withdraw(endEpoch, assets, chad, chad);

        vm.stopPrank();

        //DEGEN risk WITHDRAW
        vm.startPrank(degen);
        assets = vRisk.balanceOf(degen,endEpoch);
        vRisk.withdraw(endEpoch, assets, degen, degen);

        vm.stopPrank();

    }
}