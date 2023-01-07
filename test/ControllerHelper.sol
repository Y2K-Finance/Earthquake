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
    
    Controller public controller;
    Controller public testController;

    VaultFactory public vaultFactory;
    VaultFactory public testFactory;
    TimeLock public timelocker;

    Vault public vHedge;
    Vault public vRisk;

    DepegOracle public depegOracle;
    FakeOracle public fakeOracle;
    PegOracle public pegOracle;
    PegOracle public pegOracle2;
    PegOracle public pegOracle3;

    address public constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address public constant TOKEN_FRAX = 0x17FC002b466eEc40DaE837Fc4bE5c67993ddBd6F;
    address public constant TOKEN_FEI = 0x4A717522566C7A09FD2774cceDC5A8c43C5F9FD2;
    address public constant TOKEN_STETH = 0xEfa0dB536d2c8089685630fafe88CF7805966FC3;

    address public constant ORACLE_FRAX = 0x0809E3d38d1B4214958faf06D8b1B1a2b73f2ab8;
    address public constant ORACLE_FEI = 0x7c4720086E6feb755dab542c46DE4f728E88304d;
    address public constant ORACLE_ETH = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
    address public constant ORACLE_STETH = 0x07C5b924399cc23c24a95c8743DE4006a32b7f2a;

    address public constant ARBITRUM_SEQUENCER = 0xFdB631F5EE196F0ed6FAa767959853A9F217697D;

    address public constant ADMIN = address(1);
    address public constant ALICE = address(2);
    address public constant BOB = address(3);
    address public constant CHAD = address(4);
    address public constant DEGEN = address(5);

    uint256 public constant FEE = 5;
    uint256 public constant SINGLE_MARKET_INDEX = 1;
    uint256 public constant NULL_BALANCE = 0;
    uint256 public constant AMOUNT = 10 ether;
    uint256 public constant BEGIN_DAYS = 2 days;
    uint256 public constant END_DAYS = 30 days;
    uint256 public constant BOB_MULTIPLIER = 2;
    uint256 public constant CHAD_MULTIPLIER = 10;
    uint256 public constant DEGEN_MULTIPLIER = 20;

    int256 public constant STRIKE_PRICE_FAKE_ORACLE = 90995265;
    int256 public constant CREATION_STRK = 129919825000;
    int256 public constant DEPEG_AAA = 995555555555555555;
    int256 public constant DEPEG_BBB = 975555555555555555;
    int256 public constant DEPEG_CCC = 955555555555555555;

    address public hedge;
    address public risk;

    uint256 public endEpoch;
    uint256 public beginEpoch;
    uint256 public entitledShares;

    uint public assets;

    int256 public oracle1price1;
    int256 public oracle1price2;
    int256 public oracle2price1;
    int256 public oracle2price2;
    int256 public oracle3price1;
    int256 public oracle3price2;
    int256 public price;

    address[] public farms;
    
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

    /*///////////////////////////////////////////////////////////////
                           CONTROLLER functions
    //////////////////////////////////////////////////////////////*/

    function controllerEndEpoch(address _token, uint256 _index) public{

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

        uint feeRisk = vRisk.calculateWithdrawalFeeValue(vHedge.idFinalTVL(endEpoch), endEpoch);
        assertTrue(vRisk.idClaimTVL(endEpoch) == vHedge.idFinalTVL(endEpoch) + vRisk.idFinalTVL(endEpoch) - feeRisk, "Claim TVL not total");
        assertTrue(NULL_BALANCE == vHedge.idClaimTVL(endEpoch), "Hedge Claim TVL not zero");
    }

    function controllerDepeg(address _token, uint256 _index) public{

        hedge = vaultFactory.getVaults(_index)[0];
        risk = vaultFactory.getVaults(_index)[1];

        vHedge = Vault(hedge);
        vRisk = Vault(risk);

        emit log_named_int("strike price", vHedge.strikePrice());
        emit log_named_int("oracle price", controller.getLatestPrice(_token));

        controller.triggerDepeg(_index, endEpoch);

        if(vHedge.idFinalTVL(endEpoch) > vRisk.idFinalTVL(endEpoch)){
            emit log_named_uint("hedge final tvl", vHedge.idFinalTVL(endEpoch));
            emit log_named_uint("risk final tvl ", vRisk.idFinalTVL(endEpoch));
            uint feeRisk = vRisk.calculateWithdrawalFeeValue(vHedge.idFinalTVL(endEpoch) - vRisk.idFinalTVL(endEpoch), endEpoch);
            emit log_named_uint("risk fee", feeRisk);
            assertTrue(vHedge.idClaimTVL(endEpoch) == vRisk.idFinalTVL(endEpoch) + feeRisk, "Hedge Claim TVL not equal");
            assertTrue(vRisk.idClaimTVL(endEpoch) == vHedge.idFinalTVL(endEpoch), "Risk Claim TVL not equal");
        }
        if(vHedge.idFinalTVL(endEpoch) < vRisk.idFinalTVL(endEpoch)){
            emit log_named_uint("hedge final tvl", vHedge.idFinalTVL(endEpoch));
            emit log_named_uint("risk final tvl ", vRisk.idFinalTVL(endEpoch));
            uint feeHedge = vHedge.calculateWithdrawalFeeValue(vRisk.idFinalTVL(endEpoch) - vHedge.idFinalTVL(endEpoch), endEpoch);
            emit log_named_uint("hedge fee", feeHedge);
            assertTrue(vHedge.idClaimTVL(endEpoch) == vRisk.idFinalTVL(endEpoch) - feeHedge, "Hedge Claim TVL not equal");
            assertTrue(vRisk.idClaimTVL(endEpoch) == vHedge.idFinalTVL(endEpoch), "Risk Claim TVL not equal");
        }
    }

    /*///////////////////////////////////////////////////////////////
                           deposit functions
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256 _index) public {
        deal(ALICE, AMOUNT);
        deal(BOB, AMOUNT * BOB_MULTIPLIER);
        vm.deal(CHAD, AMOUNT * CHAD_MULTIPLIER);
        vm.deal(DEGEN, AMOUNT * DEGEN_MULTIPLIER);

        vaultFactory.createNewMarket(FEE, TOKEN_FRAX, DEPEG_AAA, beginEpoch, endEpoch, ORACLE_FRAX, "y2kFRAX_99*");

        hedge = vaultFactory.getVaults(_index)[0];
        risk = vaultFactory.getVaults(_index)[1];
        
        vHedge = Vault(hedge);
        vRisk = Vault(risk);

        //ALICE hedge deposit
        vm.startPrank(ALICE);
        vHedge.depositETH{value: AMOUNT}(endEpoch, ALICE);
        vm.stopPrank();

        //BOB hedge deposit
        vm.startPrank(BOB);
        vHedge.depositETH{value: AMOUNT * BOB_MULTIPLIER}(endEpoch, BOB);

        assertTrue(vHedge.balanceOf(BOB,endEpoch) == 20 ether);
        vm.stopPrank();

        vHedge.totalAssets(endEpoch);
        emit log_named_uint("vHedge.totalAssets(endEpoch)", vHedge.totalAssets(endEpoch));

        //CHAD risk deposit
        vm.startPrank(CHAD);
        vRisk.depositETH{value: AMOUNT * CHAD_MULTIPLIER}(endEpoch, CHAD);

        assertTrue(vRisk.balanceOf(CHAD,endEpoch) == (AMOUNT * CHAD_MULTIPLIER));
        vm.stopPrank();

        //DEGEN risk deposit
        vm.startPrank(DEGEN);
        vRisk.depositETH{value: AMOUNT * DEGEN_MULTIPLIER}(endEpoch, DEGEN);

        assertTrue(vRisk.balanceOf(DEGEN,endEpoch) == (AMOUNT * DEGEN_MULTIPLIER));
        vm.stopPrank();

        vRisk.totalAssets(endEpoch);
        emit log_named_uint("vRisk.totalAssets(endEpoch)", vRisk.totalAssets(endEpoch));
        emit log_named_uint("FEE value", vRisk.calculateWithdrawalFeeValue(AMOUNT, endEpoch));
    }

    function depositDepeg() public {
        vm.deal(ALICE, AMOUNT);
        vm.deal(BOB, AMOUNT * BOB_MULTIPLIER);
        vm.deal(CHAD, AMOUNT * CHAD_MULTIPLIER);
        vm.deal(DEGEN, AMOUNT * DEGEN_MULTIPLIER);

        vm.startPrank(ADMIN);
        fakeOracle = new FakeOracle(ORACLE_FRAX, STRIKE_PRICE_FAKE_ORACLE);
        vaultFactory.createNewMarket(FEE, TOKEN_FRAX, DEPEG_AAA, beginEpoch, endEpoch, address(fakeOracle), "y2kFRAX_99*");
        vm.stopPrank();

        hedge = vaultFactory.getVaults(1)[0];
        risk = vaultFactory.getVaults(1)[1];
        
        vHedge = Vault(hedge);
        vRisk = Vault(risk);

        //ALICE hedge deposit
        vm.startPrank(ALICE);
        vHedge.depositETH{value: AMOUNT}(endEpoch, ALICE);

        assertTrue(vHedge.balanceOf(ALICE,endEpoch) == (AMOUNT), "ALICE hedge deposit not equal");
        vm.stopPrank();

        //BOB hedge deposit
        vm.startPrank(BOB);
        vHedge.depositETH{value: AMOUNT * BOB_MULTIPLIER}(endEpoch, BOB);

        assertTrue(vHedge.balanceOf(BOB,endEpoch) == (AMOUNT * BOB_MULTIPLIER), "BOB hedge deposit not equal");
        vm.stopPrank();

        //CHAD risk deposit
        vm.startPrank(CHAD);
        vRisk.depositETH{value: AMOUNT * CHAD_MULTIPLIER}(endEpoch, CHAD);

        assertTrue(vRisk.balanceOf(CHAD,endEpoch) == (AMOUNT * CHAD_MULTIPLIER), "CHAD risk deposit not equal");
        vm.stopPrank();

        //DEGEN risk deposit
        vm.startPrank(DEGEN);
        vRisk.depositETH{value: AMOUNT * DEGEN_MULTIPLIER}(endEpoch, DEGEN);

        assertTrue(vRisk.balanceOf(DEGEN,endEpoch) == (AMOUNT * DEGEN_MULTIPLIER), "DEGEN risk deposit not equal");
        vm.stopPrank();
    }

    function fuzzDepositDepeg(uint256 ethValue) public {
        vm.deal(ALICE, ethValue);
        vm.deal(BOB, ethValue * BOB_MULTIPLIER);
        vm.deal(CHAD, ethValue * CHAD_MULTIPLIER);
        vm.deal(DEGEN, ethValue * DEGEN_MULTIPLIER);

        vm.startPrank(ADMIN);
        fakeOracle = new FakeOracle(ORACLE_FRAX, STRIKE_PRICE_FAKE_ORACLE);
        vaultFactory.createNewMarket(FEE, TOKEN_FRAX, DEPEG_AAA, beginEpoch, endEpoch, address(fakeOracle), "y2kFRAX_99*");
        vm.stopPrank();

        hedge = vaultFactory.getVaults(1)[0];
        risk = vaultFactory.getVaults(1)[1];
        
        vHedge = Vault(hedge);
        vRisk = Vault(risk);

        //ALICE hedge deposit
        vm.startPrank(ALICE);
        vHedge.depositETH{value: ethValue}(endEpoch, ALICE);

        assertTrue(vHedge.balanceOf(ALICE,endEpoch) == (ethValue));
        vm.stopPrank();

        //BOB hedge deposit
        vm.startPrank(BOB);
        vHedge.depositETH{value: ethValue * BOB_MULTIPLIER}(endEpoch, BOB);

        assertTrue(vHedge.balanceOf(BOB,endEpoch) == (ethValue * BOB_MULTIPLIER));
        vm.stopPrank();

        //CHAD risk deposit
        vm.startPrank(CHAD);
        vRisk.depositETH{value: ethValue * CHAD_MULTIPLIER}(endEpoch, CHAD);

        assertTrue(vRisk.balanceOf(CHAD,endEpoch) == (ethValue * CHAD_MULTIPLIER));
        vm.stopPrank();

        //DEGEN risk deposit
        vm.startPrank(DEGEN);
        vRisk.depositETH{value: ethValue * DEGEN_MULTIPLIER}(endEpoch, DEGEN);

        assertTrue(vRisk.balanceOf(DEGEN,endEpoch) == (ethValue * DEGEN_MULTIPLIER));
        vm.stopPrank();
    }

    /*///////////////////////////////////////////////////////////////
                           WITHDRAW functions
    //////////////////////////////////////////////////////////////*/

    function withdrawEndEpoch() public {

        hedge = vaultFactory.getVaults(1)[0];
        risk = vaultFactory.getVaults(1)[1];

        vHedge = Vault(hedge);
        vRisk = Vault(risk);

        assets;

        //ALICE hedge WITHDRAW
        vm.startPrank(ALICE);
        assets = vHedge.balanceOf(ALICE,endEpoch);
        vHedge.withdraw(endEpoch, assets, ALICE, ALICE);

        assertTrue(vHedge.balanceOf(ALICE,endEpoch) == NULL_BALANCE);
        entitledShares = vHedge.previewWithdraw(endEpoch, assets);

        vm.stopPrank();

        //BOB hedge WITHDRAW
        vm.startPrank(BOB);
        assets = vHedge.balanceOf(BOB,endEpoch);
        vHedge.withdraw(endEpoch, assets, BOB, BOB);
        
        assertTrue(vHedge.balanceOf(BOB,endEpoch) == NULL_BALANCE);

        vm.stopPrank();

        emit log_named_uint("hedge balance", ERC20(WETH).balanceOf(address(vHedge)));

        //CHAD risk WITHDRAW
        vm.startPrank(CHAD);
        assets = vRisk.balanceOf(CHAD,endEpoch);
        vRisk.withdraw(endEpoch, assets, CHAD, CHAD);

        assertTrue(vRisk.balanceOf(CHAD,endEpoch) == NULL_BALANCE);
        entitledShares = vRisk.previewWithdraw(endEpoch, assets);
        assertTrue(entitledShares - vRisk.calculateWithdrawalFeeValue(entitledShares - assets, endEpoch) == ERC20(WETH).balanceOf(CHAD));

        vm.stopPrank();

        //DEGEN risk WITHDRAW
        vm.startPrank(DEGEN);
        assets = vRisk.balanceOf(DEGEN,endEpoch);
        vRisk.withdraw(endEpoch, assets, DEGEN, DEGEN);

        assertTrue(vRisk.balanceOf(DEGEN,endEpoch) == NULL_BALANCE);
        entitledShares = vRisk.previewWithdraw(endEpoch, assets);
        assertTrue(entitledShares - vRisk.calculateWithdrawalFeeValue(entitledShares - assets, endEpoch) == ERC20(WETH).balanceOf(DEGEN));

        vm.stopPrank();

        emit log_named_uint("risk balance", ERC20(WETH).balanceOf(address(vRisk)));
    }

}