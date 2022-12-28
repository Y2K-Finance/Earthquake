// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Test.sol";
import {Vault} from "../src/Vault.sol";
import {VaultFactory, TimeLock} from "../src/VaultFactory.sol";
import {Controller} from "../src/Controller.sol"; 
import {FakeOracle} from "./oracles/FakeOracle.sol";

/// @author nexusflip
/// @author MiguelBits

contract VaultFactoryHelper is Test {

    Controller controller;

    VaultFactory vaultFactory;
    VaultFactory testFactory;
    TimeLock timelocker;

    FakeOracle fakeOracle;

    address constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address constant tokenFRAX = 0x17FC002b466eEc40DaE837Fc4bE5c67993ddBd6F;
    address constant tokenUSDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address constant tokenFEI = 0x4A717522566C7A09FD2774cceDC5A8c43C5F9FD2;
    address constant tokenDAI = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;
    address constant tokenMIM = 0xFEa7a6a0B346362BF88A9e4A88416B77a57D6c2A;

    address constant oracleFRAX = 0x0809E3d38d1B4214958faf06D8b1B1a2b73f2ab8;
    address constant oracleUSDC = 0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3;
    address constant oracleFEI = 0x7c4720086E6feb755dab542c46DE4f728E88304d;
    address constant oracleDAI = 0xc5C8E77B397E531B8EC06BFb0048328B30E9eCfB;
    address constant oracleMIM = 0x87121F6c9A9F6E90E59591E4Cf4804873f54A95b;

    address constant arbitrum_sequencer = 0xFdB631F5EE196F0ed6FAa767959853A9F217697D;
    
    address constant admin = address(1);
    address constant alice = address(2);

    uint256 constant FEE = 5;
    uint256 constant MARKET_OVERFLOW = 3;
    uint256 constant BEGIN_DAYS = 2 days;
    uint256 constant END_DAYS = 30 days;
    uint256 constant SINGLE_MARKET_INDEX = 1;
    uint256 constant ALL_MARKETS_INDEX = 15;

    int256 constant DEPEG_AAA = 995555555555555555;
    int256 constant DEPEG_BBB = 975555555555555555;
    int256 constant DEPEG_CCC = 955555555555555555;
    int256 constant STRIKE_PRICE_FAKE_ORACLE = 90995265;

    uint256 endEpoch;
    uint256 beginEpoch;
    uint timestamper;
    uint index;
    
    address newValue;
    address tokenValue;
    address factory;
    
    function setUp() public {
        vm.startPrank(admin);

        vaultFactory = new VaultFactory(admin,WETH,admin);
        testFactory = new VaultFactory(admin, WETH, admin);
        controller = new Controller(address(vaultFactory), arbitrum_sequencer);
        vaultFactory.setController(address(controller));
        timelocker = vaultFactory.timelocker();

        endEpoch = block.timestamp + END_DAYS;
        beginEpoch = block.timestamp + BEGIN_DAYS;

        vm.stopPrank();
    }
}