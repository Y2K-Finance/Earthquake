// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Test.sol";
import {Vault} from "../src/Vault.sol";
import {VaultFactory} from "../src/VaultFactory.sol";
import {Controller} from "../src/Controller.sol";
import {PegOracle} from "../src/oracles/PegOracle.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";
import {ControllerHelper} from "./ControllerHelper.sol";
import {FakeOracle} from "./oracles/FakeOracle.sol";
import {DepegOracle} from "./oracles/DepegOracle.sol";

/// @author nexusflip
/// @author MiguelBits

contract ControllerTest is ControllerHelper {
    /*///////////////////////////////////////////////////////////////
                           ASSERT cases
    //////////////////////////////////////////////////////////////*/
    function testDeposit() public {
        vm.deal(alice, AMOUNT);
        vm.deal(bob, AMOUNT * BOB_MULTIPLIER);
        vm.deal(chad, AMOUNT * CHAD_MULTIPLIER);
        vm.deal(degen, AMOUNT * DEGEN_MULTIPLIER);

        vm.prank(admin);
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_99*");

        hedge = vaultFactory.getVaults(1)[0];
        risk = vaultFactory.getVaults(1)[1];
        
        vHedge = Vault(hedge);
        vRisk = Vault(risk);

        //ALICE hedge DEPOSIT
        vm.startPrank(alice);
        ERC20(WETH).approve(hedge, AMOUNT);
        vHedge.depositETH{value: AMOUNT}(endEpoch, alice);
        vm.stopPrank();

        //BOB hedge DEPOSIT
        vm.startPrank(bob);
        ERC20(WETH).approve(hedge, AMOUNT * BOB_MULTIPLIER);
        vHedge.depositETH{value: AMOUNT * BOB_MULTIPLIER}(endEpoch, bob);

        assertTrue(vHedge.balanceOf(bob,endEpoch) == AMOUNT * BOB_MULTIPLIER);
        vm.stopPrank();

        //CHAD risk DEPOSIT
        vm.startPrank(chad);
        ERC20(WETH).approve(risk, AMOUNT * CHAD_MULTIPLIER);
        vRisk.depositETH{value: AMOUNT * CHAD_MULTIPLIER}(endEpoch, chad);

        assertTrue(vRisk.balanceOf(chad,endEpoch) == (AMOUNT * CHAD_MULTIPLIER));
        vm.stopPrank();

        //DEGEN risk DEPOSIT
        vm.startPrank(degen);
        ERC20(WETH).approve(risk, AMOUNT * DEGEN_MULTIPLIER);
        vRisk.depositETH{value: AMOUNT * DEGEN_MULTIPLIER}(endEpoch, degen);

        assertTrue(vRisk.balanceOf(degen,endEpoch) == (AMOUNT * DEGEN_MULTIPLIER));
        vm.stopPrank();
    }

    function testWithdrawDepeg() public {
        testControllerDepeg();

        hedge = vaultFactory.getVaults(1)[0];
        risk = vaultFactory.getVaults(1)[1];

        vHedge = Vault(hedge);
        vRisk = Vault(risk);

        //ALICE hedge WITHDRAW
        vm.startPrank(alice);
        assets = vHedge.balanceOf(alice,endEpoch);
        vHedge.withdraw(endEpoch, assets, alice, alice);

        assertTrue(vHedge.balanceOf(alice,endEpoch) == NULL_BALANCE);
        entitledShares = vHedge.previewWithdraw(endEpoch, assets);
        assertTrue(entitledShares - vHedge.calculateWithdrawalFeeValue(entitledShares - assets, endEpoch) == ERC20(WETH).balanceOf(alice));
    	assertTrue(vHedge.calculateWithdrawalFeeValue(10 ether, endEpoch) == 0.05 ether);
        vm.stopPrank();

        //BOB hedge WITHDRAW
        vm.startPrank(bob);
        assets = vHedge.balanceOf(bob,endEpoch);
        vHedge.withdraw(endEpoch, assets, bob, bob);
        
        assertTrue(vHedge.balanceOf(bob,endEpoch) == NULL_BALANCE);
        entitledShares = vHedge.previewWithdraw(endEpoch, assets);
        assertTrue(entitledShares - vHedge.calculateWithdrawalFeeValue(entitledShares - assets, endEpoch) == ERC20(WETH).balanceOf(bob));
        assertTrue(vHedge.calculateWithdrawalFeeValue(20 ether, endEpoch) == 0.1 ether);


        vm.stopPrank();

        emit log_named_uint("hedge balance", ERC20(WETH).balanceOf(address(vHedge)));

        //CHAD risk WITHDRAW
        vm.startPrank(chad);
        assets = vRisk.balanceOf(chad,endEpoch);
        vRisk.withdraw(endEpoch, assets, chad, chad);

        assertTrue(vRisk.balanceOf(chad,endEpoch) == NULL_BALANCE);
        entitledShares = vRisk.previewWithdraw(endEpoch, assets);
        assertTrue(entitledShares == ERC20(WETH).balanceOf(chad));

        vm.stopPrank();

        //DEGEN risk WITHDRAW
        vm.startPrank(degen);
        assets = vRisk.balanceOf(degen,endEpoch);
        vRisk.withdraw(endEpoch, assets, degen, degen);

        assertTrue(vRisk.balanceOf(degen,endEpoch) == NULL_BALANCE);
        entitledShares = vRisk.previewWithdraw(endEpoch, assets);
        assertTrue(entitledShares == ERC20(WETH).balanceOf(degen));
        vm.stopPrank();

        emit log_named_uint("risk balance", ERC20(WETH).balanceOf(address(vRisk)));
    }

    function testControllerDepeg() public{

        DepositDepeg();

        hedge = vaultFactory.getVaults(1)[0];
        risk = vaultFactory.getVaults(1)[1];

        vHedge = Vault(hedge);
        vRisk = Vault(risk);

        vm.warp(beginEpoch + 10 days);

        emit log_named_int("strike price", vHedge.strikePrice());
        emit log_named_int("oracle price", controller.getLatestPrice(tokenFRAX));
        assertTrue(controller.getLatestPrice(tokenFRAX) > 900000000000000000 && controller.getLatestPrice(tokenFRAX) < 1000000000000000000);
        assertTrue(vHedge.strikePrice() > 900000000000000000 && controller.getLatestPrice(tokenFRAX) < 1000000000000000000);


        controller.triggerDepeg(SINGLE_MARKET_INDEX, endEpoch);

        assertTrue(vHedge.totalAssets(endEpoch) == vRisk.idClaimTVL(endEpoch), "Claim TVL Risk not equal to Total Tvl Hedge");
        assertTrue(vRisk.totalAssets(endEpoch) == vHedge.idClaimTVL(endEpoch), "Claim TVL Hedge not equal to Total Tvl Risk");
    }

    function testControllerEndEpoch() public{

        testDeposit();

        hedge = vaultFactory.getVaults(1)[0];
        risk = vaultFactory.getVaults(1)[1];

        vHedge = Vault(hedge);
        vRisk = Vault(risk);

        vm.warp(endEpoch + 1 days);

        emit log_named_int("strike price", vHedge.strikePrice());
        emit log_named_int("oracle price", controller.getLatestPrice(tokenFRAX));

        controller.triggerEndEpoch(SINGLE_MARKET_INDEX, endEpoch);
        
        emit log_named_uint("total assets value", vHedge.totalAssets(endEpoch));
        
        assertTrue(vRisk.idClaimTVL(endEpoch) == vHedge.idFinalTVL(endEpoch) + vRisk.idFinalTVL(endEpoch), "Claim TVL not total");
        assertTrue(NULL_BALANCE == vHedge.idClaimTVL(endEpoch), "Hedge Claim TVL not zero");
    }

    function testCreateController() public {
        testController = new Controller(address(vaultFactory), arbitrum_sequencer);
        assertEq(address(vaultFactory), address(testController.vaultFactory()));
    }

    function testTriggerDepeg() public {
        DepositDepeg();
        vm.startPrank(admin);
        depegOracle = new DepegOracle(address(oracleFRAX), address(admin));
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, address(depegOracle), "y2kFRAX_99*");
        vm.stopPrank();

        vm.warp(beginEpoch + 1 days);
        controller.triggerDepeg(vaultFactory.marketIndex(), endEpoch);
        VaultFactory testFactory = controller.vaultFactory();
        assertEq(vaultFactory.getVaults(vaultFactory.marketIndex()), testFactory.getVaults(testFactory.marketIndex()));
    }

    function testTriggerEndEpoch() public {
        DepositDepeg();
        vm.startPrank(admin);
        
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_99*");
        vm.warp(endEpoch + 1 days);
        controller.triggerEndEpoch(SINGLE_MARKET_INDEX, endEpoch);
        testFactory = controller.vaultFactory();
        assertEq(vaultFactory.getVaults(vaultFactory.marketIndex()), testFactory.getVaults(testFactory.marketIndex()));
        vm.stopPrank();
    }

    function testNullEpochHedge() public {

        vm.startPrank(admin);
        vm.deal(degen, AMOUNT);
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_99*");
        vm.stopPrank();

        hedge = vaultFactory.getVaults(1)[0];
        risk = vaultFactory.getVaults(1)[1];
        vHedge = Vault(hedge);
        vRisk = Vault(risk);

        emit log_named_uint("WETH balance", ERC20(WETH).balanceOf(degen));
        vm.startPrank(degen);
        vHedge.depositETH{value: AMOUNT}(endEpoch, degen);
        vm.stopPrank();

        emit log_named_uint("WETH balance", ERC20(WETH).balanceOf(hedge));

        vm.warp(vHedge.idEpochBegin(endEpoch));
        controller.triggerNullEpoch(vaultFactory.marketIndex(), endEpoch);
        assertTrue(vHedge.idClaimTVL(endEpoch) == AMOUNT && vRisk.idClaimTVL(endEpoch) == 0, "Claim TVL not zero");
        assertTrue(vHedge.idFinalTVL(endEpoch) == AMOUNT && vRisk.idFinalTVL(endEpoch) == 0, "Final TVL not zero");
        assertTrue(vHedge.totalAssets(endEpoch) == AMOUNT && vRisk.totalAssets(endEpoch) == 0, "Total TVL not zero");

        vm.startPrank(degen);
        vHedge.withdraw(endEpoch, AMOUNT, degen, degen);
        vm.stopPrank();

        assertTrue(ERC20(WETH).balanceOf(degen) == AMOUNT, "WETH not returned");
        emit log_named_uint("WETH balance", ERC20(WETH).balanceOf(degen));
    }

    function testNullEpochRisk() public {

        vm.startPrank(admin);
        vm.deal(degen, AMOUNT);
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_99*");
        vm.stopPrank();

        hedge = vaultFactory.getVaults(1)[0];
        risk = vaultFactory.getVaults(1)[1];
        vHedge = Vault(hedge);
        vRisk = Vault(risk);
        
        emit log_named_uint("WETH balance", ERC20(WETH).balanceOf(degen));
        vm.startPrank(degen);
        vRisk.depositETH{value: AMOUNT}(endEpoch, degen);
        vm.stopPrank();

        vm.warp(vRisk.idEpochBegin(endEpoch));
        controller.triggerNullEpoch(vaultFactory.marketIndex(), endEpoch);
        assertTrue(vRisk.idClaimTVL(endEpoch) == AMOUNT && vHedge.idClaimTVL(endEpoch) == 0, "Claim TVL not zero");
        assertTrue(vRisk.idFinalTVL(endEpoch) == AMOUNT && vHedge.idFinalTVL(endEpoch) == 0, "Final TVL not zero");
        assertTrue(vRisk.totalAssets(endEpoch) == AMOUNT && vHedge.totalAssets(endEpoch) == 0, "Total TVL not zero");
        
        emit log_named_uint("WETH balance", ERC20(WETH).balanceOf(risk));

        vm.startPrank(degen);
        vRisk.withdraw(endEpoch, AMOUNT, degen, degen);
        vm.stopPrank();

        assertTrue(ERC20(WETH).balanceOf(degen) == AMOUNT, "WETH not returned");
        emit log_named_uint("WETH balance", ERC20(WETH).balanceOf(degen));
    }

    /*///////////////////////////////////////////////////////////////
                           REVERT cases
    //////////////////////////////////////////////////////////////*/
    
    function testSequencerDown() public {
        //create invalid controller(w/any address other than arbitrum_sequencer)
        controller = new Controller(address(vaultFactory), oracleFEI);

        //create fake oracle for price feed
        vm.startPrank(admin);
        fakeOracle = new FakeOracle(oracleFRAX, STRIKE_PRICE_FAKE_ORACLE);
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, address(fakeOracle), "y2kFRAX_99*");
        vm.stopPrank();

        //expect SequencerDown
        vm.startPrank(admin);
        vm.expectRevert(Controller.SequencerDown.selector);
        controller.getLatestPrice(tokenFRAX);
        vm.stopPrank();
    }

    function testFailControllerMarketDoesNotExist() public {
        //create fake oracle for price feed
        DepositDepeg();

        //expect MarketDoesNotExist
        emit log_named_uint("Number of markets", vaultFactory.marketIndex());
        vm.warp(endEpoch - 1 days);
        //vm.expectRevert(abi.encodeWithSelector(Controller.MarketDoesNotExist.selector, MARKET_OVERFLOW));
        controller.triggerDepeg(69, endEpoch);
    }

    function testFailControllerDoubleTrigger() public {
        //create fake oracle for price feed
        vm.startPrank(admin);
        //FakeOracle fakeOracle = new FakeOracle(oracleFRAX, STRIKE_PRICE_FAKE_ORACLE);
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_99*");
        vm.stopPrank();

        Deposit(1);
        vm.warp(endEpoch + 1);
        controller.triggerEndEpoch(1, endEpoch);

        controller.triggerEndEpoch(1, endEpoch);
    }

    function testFailControllerDoubleTrigger2() public {
        DepositDepeg();
        vm.warp(beginEpoch + 5);
        ControllerDepeg(tokenFRAX, 1);
        //vm.expectRevert(Controller.EpochFinishedAlready.selector);
        controller.triggerNullEpoch(1, endEpoch);
    }

    // function testControllerZeroAddress() public {

        
    //     //expect ZeroAddress for admin
    //     vm.startPrank(admin);
    //     vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_99*");
    //     vm.expectRevert(Controller.ZeroAddress.selector);
    //     Controller controller = new Controller(address(0), arbitrum_sequencer);
    //     vm.stopPrank();

    //     //expect ZeroAddress for vaultFactory
    //     vm.startPrank(admin);  
    //     vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_99*"); 
    //     vm.expectRevert(Controller.ZeroAddress.selector);
    //     controller = new Controller(address(admin), arbitrum_sequencer);
    //     vm.stopPrank();

    //     //expected ZeroAddress for arbitrum_sequencer
    //     vm.startPrank(admin);
    //     vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_99*");
    //     vm.expectRevert(Controller.ZeroAddress.selector);
    //     controller = new Controller(address(admin), address(0));
    //     vm.stopPrank();
    // }

    function testFailControllerEpochNotExpired() public {
        vm.startPrank(admin);
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_99*");
        vm.stopPrank();

        //vm.expectRevert(Controller.EpochNotExpired.selector);
        //controller.triggerEndEpoch(vaultFactory.marketIndex(), endEpoch);

        vm.warp(endEpoch - 1);

        //vm.expectRevert(Controller.EpochNotExpired.selector);
        controller.triggerEndEpoch(vaultFactory.marketIndex(), endEpoch);
    }


    function testFailEpochNotExist() public {
        //testing triggerEndEpoch
        vm.startPrank(admin);
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_99*");
        vm.stopPrank();
        
        //vm.expectRevert(Controller.EpochNotExist.selector);
        controller.triggerEndEpoch(vaultFactory.marketIndex(), 2);
        

        //testing isDisaster
        //vm.expectRevert(Controller.EpochNotExist.selector);
        //controller.triggerDepeg(vaultFactory.marketIndex(), block.timestamp);

    }

    function testFailEpochNotExpired() public {
        //testing triggerEndEpoch
        vm.startPrank(admin);
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_99*");
        vm.stopPrank();
        
        vm.startPrank(admin);
        vm.warp(endEpoch - 1 days);
        //vm.expectRevert(Controller.EpochNotExpired.selector);
        controller.triggerEndEpoch(vaultFactory.marketIndex(), endEpoch);
        

        //testing triggerDepeg
        vm.startPrank(admin);
        fakeOracle = new FakeOracle(oracleFRAX, 1);
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, address(fakeOracle), "y2kFRAX_99*");
        //controller.triggerDepeg(vaultFactory.marketIndex(), endEpoch);
        //vm.expectRevert(Controller.EpochNotExpired.selector);
        //controller.triggerDepeg(vaultFactory.marketIndex(), endEpoch);
        vm.stopPrank();
    }

    function testFailPriceNotAtStrikePrice() public {
        vm.startPrank(admin);
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_99*");
        controller.triggerDepeg(vaultFactory.marketIndex(), endEpoch);
        vm.stopPrank();
    }

    function testOraclePriceZero() public {
        vm.startPrank(admin);
        fakeOracle = new FakeOracle(oracleFRAX, 0);
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, address(fakeOracle), "y2kFRAX_99*");
        vm.expectRevert(Controller.OraclePriceZero.selector);
        controller.getLatestPrice(tokenFRAX);
        vm.stopPrank();
    }

    function testFailEpochNotStarted() public {
        vm.startPrank(admin);
        fakeOracle = new FakeOracle(oracleFRAX, 1);
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, address(fakeOracle), "y2kFRAX_99*");
        //vm.expectRevert(Controller.EpochNotStarted.selector);
        controller.triggerDepeg(vaultFactory.marketIndex(), endEpoch);
        vm.stopPrank();
    }

    function testFailEpochExpired() public {
        vm.startPrank(admin);
        fakeOracle = new FakeOracle(oracleFRAX, 1);
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, address(fakeOracle), "y2kFRAX_99*");
        vm.warp(endEpoch + 1);
        //vm.expectRevert(Controller.EpochExpired.selector);
        controller.triggerDepeg(vaultFactory.marketIndex(), endEpoch);
        //vm.expectRevert(Controller.NotZeroTVL.selector);
        //controller.triggerDepeg(vaultFactory.marketIndex(), endEpoch);
        vm.stopPrank();
    }

    function testFailNullEpochRevEPOCHNOTSTARTED() public {
        //need to fix triggerNullEpoch
        vm.startPrank(admin);
        vm.deal(alice, DEGEN_MULTIPLIER * AMOUNT);
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_99*");
        vm.stopPrank();

        hedge = vaultFactory.getVaults(1)[0];
        vHedge = Vault(hedge);
        risk = vaultFactory.getVaults(1)[1];
        vRisk = Vault(risk);

        vm.startPrank(alice);
        vHedge.depositETH{value: AMOUNT}(endEpoch, alice);
        //vRisk.depositETH{value: AMOUNT}(endEpoch, alice);
        vm.stopPrank();
        
        vm.startPrank(admin);
        vm.warp(beginEpoch - 1 days);

        //EPOCH NOT STARTED
        //vm.expectRevert(Controller.EpochNotStarted.selector);
        controller.triggerNullEpoch(vaultFactory.marketIndex(), endEpoch);
        vm.stopPrank();
    }
    function testFailNullEpochRevNOTZEROTVL() public {
        //need to fix triggerNullEpoch
        vm.startPrank(admin);
        vm.deal(alice, DEGEN_MULTIPLIER * AMOUNT);
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_99*");
        vm.stopPrank();

        hedge = vaultFactory.getVaults(1)[0];
        vHedge = Vault(hedge);
        risk = vaultFactory.getVaults(1)[1];
        vRisk = Vault(risk);

        vm.startPrank(alice);
        vHedge.depositETH{value: AMOUNT}(endEpoch, alice);
        vRisk.depositETH{value: AMOUNT}(endEpoch, alice);
        vm.stopPrank();
        
        vm.startPrank(admin);
        vm.warp(beginEpoch + 1);
        
        //EPOCH NOT ZERO TVL
        //vm.expectRevert(Controller.VaultNotZeroTVL.selector);
        controller.triggerNullEpoch(vaultFactory.marketIndex(), endEpoch);
        
        vm.stopPrank();
    }

    function testFailNotStrikePrice() public {
        //revert working as expected but expectRevert not working
        vm.startPrank(admin);
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_99*");
        vm.warp(endEpoch);
        hedge = vaultFactory.getVaults(1)[0];
        vHedge = Vault(hedge);
        //vm.expectRevert(abi.encodeWithSelector(Controller.PriceNotAtStrikePrice.selector, controller.getLatestPrice(vHedge.tokenInsured())));
        controller.triggerDepeg(vaultFactory.marketIndex(), endEpoch);
        vm.stopPrank();
    }
}