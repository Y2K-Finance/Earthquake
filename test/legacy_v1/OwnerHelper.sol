// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import {Vault} from "../../src/legacy_v1/Vault.sol";
import {VaultFactory, TimeLock} from "../../src/legacy_v1/VaultFactory.sol";
import {Controller} from "../../src/legacy_v1/Controller.sol";
import {FakeOracle} from "../oracles/FakeOracle.sol";
import {Owned} from "../../src/legacy_v1/rewards/Owned.sol";

/// @author nexusflip

contract OwnerHelper is Test {
    Controller public controller;

    VaultFactory public vaultFactory;
    TimeLock public timelocker;

    Vault public vHedge;

    FakeOracle public fakeOracle;
    
    Owned public owned;

    address public constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address public constant TOKEN_FRAX = 0x17FC002b466eEc40DaE837Fc4bE5c67993ddBd6F;
    address public constant ORACLE_FRAX = 0x0809E3d38d1B4214958faf06D8b1B1a2b73f2ab8;

    address public constant ARBITRUM_SEQUENCER = 0xFdB631F5EE196F0ed6FAa767959853A9F217697D;

    address public constant ADMIN = address(1);
    address public constant ALICE = address(2);
    address public constant BOB = address(3);

    uint256 public constant FEE = 5;
    uint256 public constant AMOUNT = 10 ether;
    uint256 public constant BEGIN_DAYS = 2 days;
    uint256 public constant END_DAYS = 30 days;
    
    int256 public constant DEPEG_AAA = 995555555555555555;
    int256 public constant STRIKE_PRICE_FAKE_ORACLE = 90995265;

    uint256 public endEpoch;
    uint256 public beginEpoch;

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