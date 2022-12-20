// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Test.sol";
import {Vault} from "../src/Vault.sol";
import {VaultFactory, TimeLock} from "../src/VaultFactory.sol";
import {Controller} from "../src/Controller.sol"; 
import {PegOracle} from "../src/oracles/PegOracle.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";
import {FakeOracle} from "./oracles/FakeOracle.sol";
import {DepegOracle} from "./oracles/DepegOracle.sol";

/// @author nexusflip

contract ControllerHelper is Test {

    VaultFactory vaultFactory;
    VaultFactory testFactory;
    Controller controller;
    Controller testController;
    TimeLock timelocker;
    DepegOracle depegOracle;
    FakeOracle fakeOracle;

    address constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address constant tokenFRAX = 0x17FC002b466eEc40DaE837Fc4bE5c67993ddBd6F;
    address constant tokenFEI = 0x4A717522566C7A09FD2774cceDC5A8c43C5F9FD2;
    address constant oracleFRAX = 0x0809E3d38d1B4214958faf06D8b1B1a2b73f2ab8;
    address constant oracleFEI = 0x7c4720086E6feb755dab542c46DE4f728E88304d;
    address constant arbitrum_sequencer = 0xFdB631F5EE196F0ed6FAa767959853A9F217697D;
    address constant admin = address(1);
    address constant alice = address(2);
    address constant bob = address(3);
    address constant chad = address(4);
    address constant degen = address(5);

    uint256 constant FEE = 5;
    uint256 constant SINGLE_MARKET_INDEX = 1;
    uint256 constant NULL_BALANCE = 0;
    uint256 constant NULL_VALUE = 0;
    uint256 constant AMOUNT = 10 ether;
    uint256 constant BEGIN_DAYS = 2 days;
    uint256 constant END_DAYS = 30 days;
    uint256 constant BOB_MULTIPLIER = 2;
    uint256 constant CHAD_MULTIPLIER = 10;
    uint256 constant DEGEN_MULTIPLIER = 20;
    int256 constant STRIKE_PRICE_FAKE_ORACLE = 90995265;
    int256 constant DEPEG_AAA = 995555555555555555;

    address hedge;
    address risk;

    Vault vHedge;
    Vault vRisk;

    uint256 endEpoch;
    uint256 beginEpoch;
    uint256 entitledShares;
    uint assets;


    address[] public farms;
    
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

    /*///////////////////////////////////////////////////////////////
                           DEPOSIT functions
    //////////////////////////////////////////////////////////////*/

    function Deposit(uint256 _index) public {
        deal(alice, AMOUNT);
        deal(bob, AMOUNT * BOB_MULTIPLIER);
        vm.deal(chad, AMOUNT * CHAD_MULTIPLIER);
        vm.deal(degen, AMOUNT * DEGEN_MULTIPLIER);

        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_99*");

        hedge = vaultFactory.getVaults(_index)[0];
        risk = vaultFactory.getVaults(_index)[1];
        
        vHedge = Vault(hedge);
        vRisk = Vault(risk);

        //ALICE hedge DEPOSIT
        vm.startPrank(alice);
        vHedge.depositETH{value: AMOUNT}(endEpoch, alice);
        vm.stopPrank();

        //BOB hedge DEPOSIT
        vm.startPrank(bob);
        vHedge.depositETH{value: AMOUNT * BOB_MULTIPLIER}(endEpoch, bob);

        assertTrue(vHedge.balanceOf(bob,endEpoch) == 20 ether);
        vm.stopPrank();

        vHedge.totalAssets(endEpoch);
        emit log_named_uint("vHedge.totalAssets(endEpoch)", vHedge.totalAssets(endEpoch));

        //CHAD risk DEPOSIT
        vm.startPrank(chad);
        vRisk.depositETH{value: AMOUNT * CHAD_MULTIPLIER}(endEpoch, chad);

        assertTrue(vRisk.balanceOf(chad,endEpoch) == (AMOUNT * CHAD_MULTIPLIER));
        vm.stopPrank();

        //DEGEN risk DEPOSIT
        vm.startPrank(degen);
        vRisk.depositETH{value: AMOUNT * DEGEN_MULTIPLIER}(endEpoch, degen);

        assertTrue(vRisk.balanceOf(degen,endEpoch) == (AMOUNT * DEGEN_MULTIPLIER));
        vm.stopPrank();

        vRisk.totalAssets(endEpoch);
        emit log_named_uint("vRisk.totalAssets(endEpoch)", vRisk.totalAssets(endEpoch));
        emit log_named_uint("FEE value", vRisk.calculateWithdrawalFeeValue(AMOUNT, endEpoch));
    }

    function DepositDepeg() public {
        vm.deal(alice, AMOUNT);
        vm.deal(bob, AMOUNT * BOB_MULTIPLIER);
        vm.deal(chad, AMOUNT * CHAD_MULTIPLIER);
        vm.deal(degen, AMOUNT * DEGEN_MULTIPLIER);

        vm.startPrank(admin);
        fakeOracle = new FakeOracle(oracleFRAX, STRIKE_PRICE_FAKE_ORACLE);
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, address(fakeOracle), "y2kFRAX_99*");
        vm.stopPrank();

        hedge = vaultFactory.getVaults(1)[0];
        risk = vaultFactory.getVaults(1)[1];
        
        vHedge = Vault(hedge);
        vRisk = Vault(risk);

        //ALICE hedge DEPOSIT
        vm.startPrank(alice);
        vHedge.depositETH{value: AMOUNT}(endEpoch, alice);

        assertTrue(vHedge.balanceOf(alice,endEpoch) == (AMOUNT));
        vm.stopPrank();

        //BOB hedge DEPOSIT
        vm.startPrank(bob);
        vHedge.depositETH{value: AMOUNT * BOB_MULTIPLIER}(endEpoch, bob);

        assertTrue(vHedge.balanceOf(bob,endEpoch) == (AMOUNT * BOB_MULTIPLIER));
        vm.stopPrank();

        //CHAD risk DEPOSIT
        vm.startPrank(chad);
        vRisk.depositETH{value: AMOUNT * CHAD_MULTIPLIER}(endEpoch, chad);

        assertTrue(vRisk.balanceOf(chad,endEpoch) == (AMOUNT * CHAD_MULTIPLIER));
        vm.stopPrank();

        //DEGEN risk DEPOSIT
        vm.startPrank(degen);
        vRisk.depositETH{value: AMOUNT * DEGEN_MULTIPLIER}(endEpoch, degen);

        assertTrue(vRisk.balanceOf(degen,endEpoch) == (AMOUNT * DEGEN_MULTIPLIER));
        vm.stopPrank();
    }

    /*///////////////////////////////////////////////////////////////
                           CONTROLLER functions
    //////////////////////////////////////////////////////////////*/

    function ControllerEndEpoch(address _token, uint256 _index) public{

        hedge = vaultFactory.getVaults(_index)[0];
        risk = vaultFactory.getVaults(_index)[1];

        vHedge = Vault(hedge);
        vRisk = Vault(risk);

        vm.warp(endEpoch + 1 days);

        emit log_named_int("strike price", vHedge.strikePrice());
        emit log_named_int("oracle price", controller.getLatestPrice(_token));

        controller.triggerEndEpoch(_index, endEpoch);

        emit log_named_uint("vHedge.idFinalTVL(endEpoch)", vHedge.idFinalTVL(endEpoch));
        emit log_named_uint("vRisk.idFinalTVL(endEpoch) ", vRisk.idFinalTVL(endEpoch));
        emit log_named_uint("vRisk.idClaimTVL(endEpoch) ", vRisk.idClaimTVL(endEpoch));

        assertTrue(vRisk.idClaimTVL(endEpoch) == vHedge.idFinalTVL(endEpoch) + vRisk.idFinalTVL(endEpoch), "Claim TVL not total");
        assertTrue(NULL_BALANCE == vHedge.idClaimTVL(endEpoch), "Hedge Claim TVL not zero");
    }

    function ControllerDepeg(address _token, uint256 _index) public{

        hedge = vaultFactory.getVaults(_index)[0];
        risk = vaultFactory.getVaults(_index)[1];

        vHedge = Vault(hedge);
        vRisk = Vault(risk);

        emit log_named_int("strike price", vHedge.strikePrice());
        emit log_named_int("oracle price", controller.getLatestPrice(_token));

        controller.triggerDepeg(_index, endEpoch);

        assertTrue(vHedge.totalAssets(endEpoch) == vRisk.idClaimTVL(endEpoch), "Claim TVL not equal");
        assertTrue(vRisk.totalAssets(endEpoch) == vHedge.idClaimTVL(endEpoch), "Risk Claim TVL not equal");
    }

}