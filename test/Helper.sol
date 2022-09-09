// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Test.sol";
import {Vault} from "../src/Vault.sol";
import {VaultFactory} from "../src/VaultFactory.sol";
import {Controller} from "../src/Controller.sol";
import {PegOracle} from "../src/oracles/PegOracle.sol";
import {RewardsFactory} from "../src/rewards/RewardsFactory.sol";
import {GovToken} from "./GovToken.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";
import "@chainlink/interfaces/AggregatorV3Interface.sol";

import {FakeOracle} from "./oracles/FakeOracle.sol";
import {IWETH} from "./interfaces/IWETH.sol";


contract Helper is Test {

    VaultFactory vaultFactory;
    Controller controller;
    GovToken govToken;
    RewardsFactory rewardsFactory;

    address WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

    address tokenFRAX = 0x17FC002b466eEc40DaE837Fc4bE5c67993ddBd6F;
    address tokenMIM = 0xFEa7a6a0B346362BF88A9e4A88416B77a57D6c2A;
    address tokenFEI = 0x4A717522566C7A09FD2774cceDC5A8c43C5F9FD2;
    address tokenUSDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address tokenDAI = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;
    address tokenSTETH = 0xEfa0dB536d2c8089685630fafe88CF7805966FC3;

    address oracleFRAX = 0x0809E3d38d1B4214958faf06D8b1B1a2b73f2ab8;
    address oracleMIM = 0x87121F6c9A9F6E90E59591E4Cf4804873f54A95b;
    address oracleFEI = 0x7c4720086E6feb755dab542c46DE4f728E88304d;
    address oracleUSDC = 0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3;
    address oracleDAI = 0xc5C8E77B397E531B8EC06BFb0048328B30E9eCfB;
    address oracleSTETH = 0x07C5b924399cc23c24a95c8743DE4006a32b7f2a;
    address oracleETH = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;

    address arbitrum_sequencer = 0xFdB631F5EE196F0ed6FAa767959853A9F217697D;

    address admin = address(1);

    address alice = address(2);
    address bob = address(3);
    address chad = address(4);
    address degen = address(5);

    int256 depegAAA = 995555555555555555;
    int256 depegBBB = 975555555555555555;
    int256 depegCCC = 955555555555555555;

    uint256 FEE = 55;

    uint256 endEpoch;
    uint256 beginEpoch;
    
    function setUp() public {
        vaultFactory = new VaultFactory(admin,WETH,admin);
        controller = new Controller(address(vaultFactory),admin, arbitrum_sequencer);

        vm.prank(admin);
        vaultFactory.setController(address(controller));

        endEpoch = block.timestamp + 30 days;
        beginEpoch = block.timestamp + 2 days;

        govToken = new GovToken();
        rewardsFactory = new RewardsFactory(address(govToken), address(vaultFactory), admin);

    }

    /*///////////////////////////////////////////////////////////////
                           DEPOSIT functions
    //////////////////////////////////////////////////////////////*/

    function Deposit(uint256 _index) public {
        deal(alice, 10 ether);
        deal(bob, 20 ether);
        vm.deal(chad, 100 ether);
        vm.deal(degen, 200 ether);

        address hedge = vaultFactory.getVaults(_index)[0];
        address risk = vaultFactory.getVaults(_index)[1];
        
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

        vHedge.totalAssets(endEpoch);
        emit log_named_uint("vHedge.totalAssets(endEpoch)", vHedge.totalAssets(endEpoch));

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

        vRisk.totalAssets(endEpoch);
        emit log_named_uint("vRisk.totalAssets(endEpoch)", vRisk.totalAssets(endEpoch));
    }

    function DepositDepeg() public {
        vm.deal(alice, 10 ether);
        vm.deal(bob, 20 ether);
        vm.deal(chad, 100 ether);
        vm.deal(degen, 200 ether);

        vm.startPrank(admin);
        FakeOracle fakeOracle = new FakeOracle(oracleFRAX, 90995265);
        vaultFactory.createNewMarket(50, tokenFRAX, depegAAA, beginEpoch, endEpoch, address(fakeOracle), "y2kFRAX_99*");
        vm.stopPrank();

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

    /*///////////////////////////////////////////////////////////////
                           CONTROLLER functions
    //////////////////////////////////////////////////////////////*/

    function ControllerEndEpoch(address _token, uint256 _index) public{

        address hedge = vaultFactory.getVaults(_index)[0];
        address risk = vaultFactory.getVaults(_index)[1];

        Vault vHedge = Vault(hedge);
        Vault vRisk = Vault(risk);

        vm.warp(endEpoch + 1 days);

        emit log_named_int("strike price", vHedge.strikePrice());
        emit log_named_int("oracle price", controller.getLatestPrice(_token));

        controller.triggerEndEpoch(_index, endEpoch);

        assertTrue(vHedge.totalAssets(endEpoch) == vRisk.idClaimTVL(endEpoch), "Claim TVL not equal");
        //emit log_named_uint("claim tvl", vHedge.idClaimTVL(endEpoch));
        assertTrue(0 == vHedge.idClaimTVL(endEpoch), "Hedge Claim TVL not zero");
    }

    /*///////////////////////////////////////////////////////////////
                           WITHDRAW functions
    //////////////////////////////////////////////////////////////*/

    function Withdraw() public {

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
