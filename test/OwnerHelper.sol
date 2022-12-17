// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Test.sol";
import {Vault} from "../src/Vault.sol";
import {VaultFactory, TimeLock} from "../src/VaultFactory.sol";
import {Controller} from "../src/Controller.sol";
import {FakeOracle} from "./oracles/FakeOracle.sol";
import {Owned} from "../src/rewards/Owned.sol";

/// @author MiguelBits
/// @author NexusFlip

contract OwnerHelper is Test {

    VaultFactory vaultFactory;
    Controller controller;
    TimeLock timelocker;
    Vault vHedge;
    FakeOracle fakeOracle;
    Owned owned;

    address constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address constant tokenFRAX = 0x17FC002b466eEc40DaE837Fc4bE5c67993ddBd6F;
    address constant oracleFRAX = 0x0809E3d38d1B4214958faf06D8b1B1a2b73f2ab8;
    address constant tokenUSDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address constant oracleUSDC = 0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3;
    address constant arbitrum_sequencer = 0xFdB631F5EE196F0ed6FAa767959853A9F217697D;
    address constant admin = address(1);
    address constant alice = address(2);
    address constant bob = address(3);

    uint256 constant FEE = 5;
    uint256 constant SINGLE_MARKET_INDEX = 1;
    uint256 constant MARKET_OVERFLOW = 3;
    uint256 constant AMOUNT = 10 ether;
    uint256 constant BEGIN_DAYS = 2 days;
    uint256 constant END_DAYS = 30 days;
    int256 constant DEPEG_AAA = 995555555555555555;
    int256 constant STRIKE_PRICE_FAKE_ORACLE = 90995265;

    uint256 endEpoch;
    uint256 beginEpoch;

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