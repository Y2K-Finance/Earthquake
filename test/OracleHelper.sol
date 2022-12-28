// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Test.sol";
import {Vault} from "../src/Vault.sol";
import {VaultFactory, TimeLock} from "../src/VaultFactory.sol";
import {Controller} from "../src/Controller.sol";
import {PegOracle} from "../src/oracles/PegOracle.sol";
import {FakeOracle} from "./oracles/FakeOracle.sol";
import {FakeFakeOracle} from "./oracles/FakeFakeOracle.sol";
import "@chainlink/interfaces/AggregatorV3Interface.sol";

/// @author nexusflip

contract OracleHelper is Test {

    Controller controller;

    VaultFactory vaultFactory;
    VaultFactory testFactory;
    TimeLock timelocker;

    Vault vHedge;

    FakeOracle fakeOracle;
    FakeOracle eightDec;
    FakeOracle eighteenDec;

    FakeFakeOracle sevenDec;
    FakeFakeOracle plusDecimals;

    PegOracle pegOracle;
    PegOracle pegOracle2;

    AggregatorV3Interface testOracle1;
    AggregatorV3Interface testOracle2;

    address constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address constant arbitrum_sequencer = 0xFdB631F5EE196F0ed6FAa767959853A9F217697D;
    address constant tokenFRAX = 0x17FC002b466eEc40DaE837Fc4bE5c67993ddBd6F;
    address constant tokenMIM = 0xFEa7a6a0B346362BF88A9e4A88416B77a57D6c2A;
    address constant tokenUSDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address constant tokenSTETH = 0xEfa0dB536d2c8089685630fafe88CF7805966FC3;

    address constant oracleFRAX = 0x0809E3d38d1B4214958faf06D8b1B1a2b73f2ab8;
    address constant oracleMIM = 0x87121F6c9A9F6E90E59591E4Cf4804873f54A95b;
    address constant oracleUSDC = 0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3;
    address constant oracleSTETH = 0x07C5b924399cc23c24a95c8743DE4006a32b7f2a;
    address constant oracleETH = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
    address constant oracleFEI = 0x7c4720086E6feb755dab542c46DE4f728E88304d;
    address constant btcEthOracle = 0xc5a90A6d7e4Af242dA238FFe279e9f2BA0c64B2e;

    address constant admin = address(1);
    address constant alice = address(2);
    address constant bob = address(3);

    uint256 constant FEE = 5;
    uint256 constant BEGIN_DAYS = 2 days;
    uint256 constant END_DAYS = 30 days;
    uint256 constant DECIMALS = 18;

    int256 constant DEPEG_AAA = 995555555555555555;
    int256 constant DEPEG_BBB = 975555555555555555;
    int256 constant DEPEG_CCC = 955555555555555555;

    uint256 endEpoch;
    uint256 beginEpoch;

    int256 testPriceOne;
    int256 testPriceTwo;
    int256 testPriceThree;
    int256 oracle1price1;
    int256 oracle1price2;
    int256 price;
    int256 nowPrice;
    
    address hedge;
    
    function setUp() public {
        vm.startPrank(admin);

        vaultFactory = new VaultFactory(admin,WETH,admin);
        controller = new Controller(address(vaultFactory), arbitrum_sequencer);
        vaultFactory.setController(address(controller));
        timelocker = vaultFactory.timelocker();

        endEpoch = block.timestamp + END_DAYS;
        beginEpoch = block.timestamp + BEGIN_DAYS;

        vm.stopPrank();
    }
}