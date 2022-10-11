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

/// @author NexusFlip

contract FuzzHelper is Test {
    VaultFactory vaultFactory;
    Controller controller;
    GovToken govToken;
    RewardsFactory rewardsFactory;

    uint256 immutable AMOUNT = 10 ether;
    uint256 immutable BOB_MULTIPLIER = 2;
    uint256 immutable CHAD_MULTIPLIER = 10;
    uint256 immutable DEGEN_MULTIPLIER = 20;
    uint256 immutable SINGLE_MARKET_INDEX = 1;
    uint256 immutable ALL_MARKETS_INDEX = 15;
    uint256 immutable DEFAULT_TEST_FEE = 50;
    uint256 immutable NULL_VALUE = 0;
    uint256 immutable REWARDS_DURATION = 10 days;
    uint256 immutable REWARD_RATE = 10;
    int256 immutable STRIKE_PRICE_FAKE_ORACLE = 90995265;

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
    address btcEthOracle = 0xc5a90A6d7e4Af242dA238FFe279e9f2BA0c64B2e;

    address arbitrum_sequencer = 0xFdB631F5EE196F0ed6FAa767959853A9F217697D;

    address admin = address(1);

    address alice = address(2);
    address bob = address(3);
    address chad = address(4);
    address degen = address(5);

    int256 immutable DEPEG_AAA = 995555555555555555;
    int256 immutable DEPEG_BBB = 975555555555555555;
    int256 immutable DEPEG_CCC = 955555555555555555;
    uint256 FEE = 55;

    uint256 endEpoch;
    uint256 beginEpoch;
    
    function setUp() public {
        vm.prank(admin);
        vaultFactory = new VaultFactory(admin,WETH, admin);
        controller = new Controller(address(vaultFactory), arbitrum_sequencer);

        vm.prank(admin);
        vaultFactory.setController(address(controller));

        endEpoch = block.timestamp + 30 days;
        beginEpoch = block.timestamp + 2 days;

        govToken = new GovToken();
        vm.prank(admin);
        rewardsFactory = new RewardsFactory(address(govToken), address(vaultFactory));

    }

    function DepositDepeg(uint256 index) public {
        vm.deal(alice, index);
        vm.deal(bob, index * BOB_MULTIPLIER);
        vm.deal(chad, index * CHAD_MULTIPLIER);
        vm.deal(degen, index * DEGEN_MULTIPLIER);

        vm.startPrank(admin);
        FakeOracle fakeOracle = new FakeOracle(oracleFRAX, STRIKE_PRICE_FAKE_ORACLE);
        vaultFactory.createNewMarket(50, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, address(fakeOracle), "y2kFRAX_99*");
        vm.stopPrank();

        address hedge = vaultFactory.getVaults(1)[0];
        address risk = vaultFactory.getVaults(1)[1];
        
        Vault vHedge = Vault(hedge);
        Vault vRisk = Vault(risk);

        //ALICE hedge DEPOSIT
        vm.startPrank(alice);
        ERC20(WETH).approve(hedge, index);
        vHedge.depositETH{value: index}(endEpoch, alice);

        assertTrue(vHedge.balanceOf(alice,endEpoch) == (index));
        vm.stopPrank();

        //BOB hedge DEPOSIT
        vm.startPrank(bob);
        ERC20(WETH).approve(hedge, index * BOB_MULTIPLIER);
        vHedge.depositETH{value: index * BOB_MULTIPLIER}(endEpoch, bob);

        assertTrue(vHedge.balanceOf(bob,endEpoch) == (index * BOB_MULTIPLIER));
        vm.stopPrank();

        //CHAD risk DEPOSIT
        vm.startPrank(chad);
        ERC20(WETH).approve(risk, index * CHAD_MULTIPLIER);
        vRisk.depositETH{value: index * CHAD_MULTIPLIER}(endEpoch, chad);

        assertTrue(vRisk.balanceOf(chad,endEpoch) == (index * CHAD_MULTIPLIER));
        vm.stopPrank();

        //DEGEN risk DEPOSIT
        vm.startPrank(degen);
        ERC20(WETH).approve(risk, index * DEGEN_MULTIPLIER);
        vRisk.depositETH{value: index * DEGEN_MULTIPLIER}(endEpoch, degen);

        assertTrue(vRisk.balanceOf(degen,endEpoch) == (index * DEGEN_MULTIPLIER));
        vm.stopPrank();
    }

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

    
}