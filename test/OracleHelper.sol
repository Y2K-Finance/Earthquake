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

    Controller public controller;

    VaultFactory public vaultFactory;
    VaultFactory public testFactory;
    TimeLock public timelocker;

    Vault public vHedge;

    FakeOracle public fakeOracle;
    FakeOracle public eightDec;
    FakeOracle public eighteenDec;

    FakeFakeOracle public sevenDec;
    FakeFakeOracle public plusDecimals;

    PegOracle public pegOracle;
    PegOracle public pegOracle2;

    AggregatorV3Interface public testOracle1;
    AggregatorV3Interface public testOracle2;

    address public constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address public constant ARBITRUM_SEQUENCER = 0xFdB631F5EE196F0ed6FAa767959853A9F217697D;
    address public constant TOKEN_FRAX = 0x17FC002b466eEc40DaE837Fc4bE5c67993ddBd6F;
    address public constant TOKEN_MIM = 0xFEa7a6a0B346362BF88A9e4A88416B77a57D6c2A;
    address public constant TOKEN_USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address public constant TOKEN_STETH = 0xEfa0dB536d2c8089685630fafe88CF7805966FC3;

    address public constant ORACLE_FRAX = 0x0809E3d38d1B4214958faf06D8b1B1a2b73f2ab8;
    address public constant ORACLE_MIM = 0x87121F6c9A9F6E90E59591E4Cf4804873f54A95b;
    address public constant ORACLE_USDC = 0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3;
    address public constant ORACLE_STETH = 0x07C5b924399cc23c24a95c8743DE4006a32b7f2a;
    address public constant ORACLE_ETH = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
    address public constant ORACLE_FEI = 0x7c4720086E6feb755dab542c46DE4f728E88304d;
    address public constant ORACLE_BTC_ETH = 0xc5a90A6d7e4Af242dA238FFe279e9f2BA0c64B2e;

    address public constant ADMIN = address(1);

    uint256 public constant FEE = 5;
    uint256 public constant BEGIN_DAYS = 2 days;
    uint256 public constant END_DAYS = 30 days;
    uint256 public constant DECIMALS = 18;

    int256 public constant DEPEG_AAA = 995555555555555555;
    int256 public constant DEPEG_BBB = 975555555555555555;
    int256 public constant DEPEG_CCC = 955555555555555555;

    uint256 public endEpoch;
    uint256 public beginEpoch;

    int256 public testPriceOne;
    int256 public testPriceTwo;
    int256 public testPriceThree;
    int256 public oracle1price1;
    int256 public oracle1price2;
    int256 public price;
    int256 public nowPrice;
    
    address public hedge;
    
    function setUp() public {
        vm.startPrank(ADMIN);

        vaultFactory = new VaultFactory(ADMIN,WETH,ADMIN);
        controller = new Controller(address(vaultFactory), ARBITRUM_SEQUENCER);
        vaultFactory.setController(address(controller));
        timelocker = vaultFactory.timelocker();

        endEpoch = block.timestamp + END_DAYS;
        beginEpoch = block.timestamp + BEGIN_DAYS;

        vm.stopPrank();
    }
}