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
        vm.deal(ALICE, AMOUNT);
        vm.deal(BOB, AMOUNT * BOB_MULTIPLIER);
        vm.deal(CHAD, AMOUNT * CHAD_MULTIPLIER);
        vm.deal(DEGEN, AMOUNT * DEGEN_MULTIPLIER);

        vm.prank(ADMIN);
        vaultFactory.createNewMarket(FEE, TOKEN_FRAX, DEPEG_AAA, beginEpoch, endEpoch, ORACLE_FRAX, "y2kFRAX_99*");

        hedge = vaultFactory.getVaults(1)[0];
        risk = vaultFactory.getVaults(1)[1];
        
        vHedge = Vault(hedge);
        vRisk = Vault(risk);

        //ALICE hedge deposit
        vm.startPrank(ALICE);
        ERC20(WETH).approve(hedge, AMOUNT);
        vHedge.depositETH{value: AMOUNT}(endEpoch, ALICE);
        vm.stopPrank();

        //BOB hedge deposit
        vm.startPrank(BOB);
        ERC20(WETH).approve(hedge, AMOUNT * BOB_MULTIPLIER);
        vHedge.depositETH{value: AMOUNT * BOB_MULTIPLIER}(endEpoch, BOB);

        assertTrue(vHedge.balanceOf(BOB,endEpoch) == AMOUNT * BOB_MULTIPLIER);
        vm.stopPrank();

        //CHAD risk deposit
        vm.startPrank(CHAD);
        ERC20(WETH).approve(risk, AMOUNT * CHAD_MULTIPLIER);
        vRisk.depositETH{value: AMOUNT * CHAD_MULTIPLIER}(endEpoch, CHAD);

        assertTrue(vRisk.balanceOf(CHAD,endEpoch) == (AMOUNT * CHAD_MULTIPLIER));
        vm.stopPrank();

        //DEGEN risk deposit
        vm.startPrank(DEGEN);
        ERC20(WETH).approve(risk, AMOUNT * DEGEN_MULTIPLIER);
        vRisk.depositETH{value: AMOUNT * DEGEN_MULTIPLIER}(endEpoch, DEGEN);

        assertTrue(vRisk.balanceOf(DEGEN,endEpoch) == (AMOUNT * DEGEN_MULTIPLIER));
        vm.stopPrank();
    }

    function testControllerFeesEndEpoch() public {
        uint wethBALPrev = ERC20(WETH).balanceOf(ADMIN);
        emit log_named_uint("treasury bal", wethBALPrev);
        testControllerEndEpoch();
        uint wethBALAfter = ERC20(WETH).balanceOf(ADMIN);
        emit log_named_uint("treasury bal", wethBALAfter);
        assertTrue(wethBALAfter > wethBALPrev, "treasury balance should increase");
    }

    function testControllerFeesDepeg() public {
        uint wethBALPrev = ERC20(WETH).balanceOf(ADMIN);
        emit log_named_uint("treasury bal", wethBALPrev);
        testControllerDepeg();
        uint wethBALAfter = ERC20(WETH).balanceOf(ADMIN);
        emit log_named_uint("treasury bal", wethBALAfter);
        assertTrue(wethBALAfter > wethBALPrev, "treasury balance should increase");
    }

    function testWithdrawDepeg() public {
        testControllerDepeg();

        hedge = vaultFactory.getVaults(1)[0];
        risk = vaultFactory.getVaults(1)[1];

        vHedge = Vault(hedge);
        vRisk = Vault(risk);

        //ALICE hedge WITHDRAW
        vm.startPrank(ALICE);
        assets = vHedge.balanceOf(ALICE,endEpoch);
        vHedge.withdraw(endEpoch, assets, ALICE, ALICE);

        assertTrue(vHedge.balanceOf(ALICE,endEpoch) == NULL_BALANCE);
        entitledShares = vHedge.previewWithdraw(endEpoch, assets);
        // assertTrue(entitledShares - vHedge.calculateWithdrawalFeeValue(entitledShares - assets, endEpoch) == ERC20(WETH).balanceOf(ALICE));
    	// assertTrue(vHedge.calculateWithdrawalFeeValue(10 ether, endEpoch) == 0.05 ether);
        vm.stopPrank();

        //alice balance
        emit log_named_uint("ALICE hedge balance", entitledShares);
        //hedge balance
        emit log_named_uint("hedge balance      ", ERC20(WETH).balanceOf(address(vHedge)));

        //BOB hedge WITHDRAW
        vm.startPrank(BOB);
        assets = vHedge.balanceOf(BOB,endEpoch);
        vHedge.withdraw(endEpoch, assets, BOB, BOB);
        
        assertTrue(vHedge.balanceOf(BOB,endEpoch) == NULL_BALANCE);
        entitledShares = vHedge.previewWithdraw(endEpoch, assets);
        // assertTrue(entitledShares - vHedge.calculateWithdrawalFeeValue(entitledShares - assets, endEpoch) == ERC20(WETH).balanceOf(BOB));
        // assertTrue(vHedge.calculateWithdrawalFeeValue(20 ether, endEpoch) == 0.1 ether);
        vm.stopPrank();

        //bob balance
        emit log_named_uint("BOB hedge balance", entitledShares);
        //hedge balance
        emit log_named_uint("hedge balance    ", ERC20(WETH).balanceOf(address(vHedge)));

        //CHAD risk WITHDRAW
        vm.startPrank(CHAD);
        assets = vRisk.balanceOf(CHAD,endEpoch);
        vRisk.withdraw(endEpoch, assets, CHAD, CHAD);

        assertTrue(vRisk.balanceOf(CHAD,endEpoch) == NULL_BALANCE);
        entitledShares = vRisk.previewWithdraw(endEpoch, assets);
        assertTrue(entitledShares == ERC20(WETH).balanceOf(CHAD));

        vm.stopPrank();

        //chad balance
        emit log_named_uint("CHAD risk balance", entitledShares);
        //risk balance
        emit log_named_uint("risk balance     ", ERC20(WETH).balanceOf(address(vRisk)));

        //DEGEN risk WITHDRAW
        vm.startPrank(DEGEN);
        assets = vRisk.balanceOf(DEGEN,endEpoch);
        vRisk.withdraw(endEpoch, assets, DEGEN, DEGEN);

        assertTrue(vRisk.balanceOf(DEGEN,endEpoch) == NULL_BALANCE);
        entitledShares = vRisk.previewWithdraw(endEpoch, assets);
        assertTrue(entitledShares == ERC20(WETH).balanceOf(DEGEN));
        vm.stopPrank();

        //degen balance
        emit log_named_uint("DEGEN risk balance", entitledShares);
        //risk balance
        emit log_named_uint("risk balance      ", ERC20(WETH).balanceOf(address(vRisk)));
    }

    function testWithdrawEndEpoch() public {
        testControllerEndEpoch();

        hedge = vaultFactory.getVaults(1)[0];
        risk = vaultFactory.getVaults(1)[1];

        vHedge = Vault(hedge);
        vRisk = Vault(risk);

        //ALICE hedge WITHDRAW
        vm.startPrank(ALICE);
        assets = vHedge.balanceOf(ALICE,endEpoch);
        vHedge.withdraw(endEpoch, assets, ALICE, ALICE);

        assertTrue(vHedge.balanceOf(ALICE,endEpoch) == NULL_BALANCE);
        entitledShares = vHedge.previewWithdraw(endEpoch, assets);
        assertTrue(entitledShares == ERC20(WETH).balanceOf(ALICE));
        console.log("Alice");
        vm.stopPrank();

        //BOB hedge WITHDRAW
        vm.startPrank(BOB);
        assets = vHedge.balanceOf(BOB,endEpoch);
        vHedge.withdraw(endEpoch, assets, BOB, BOB);
        
        assertTrue(vHedge.balanceOf(BOB,endEpoch) == NULL_BALANCE);
        entitledShares = vHedge.previewWithdraw(endEpoch, assets);
        assertTrue(entitledShares == ERC20(WETH).balanceOf(BOB));
        console.log("Bob");
        vm.stopPrank();

        emit log_named_uint("hedge balance", ERC20(WETH).balanceOf(address(vHedge)));

        //CHAD risk WITHDRAW
        vm.startPrank(CHAD);
        assets = vRisk.balanceOf(CHAD, endEpoch);
        vRisk.withdraw(endEpoch, assets, CHAD, CHAD);

        assertTrue(vRisk.balanceOf(CHAD,endEpoch) == NULL_BALANCE);
        entitledShares = vRisk.previewWithdraw(endEpoch, assets);
        //TODO assertTrue(entitledShares - vRisk.calculateWithdrawalFeeValue(entitledShares - assets, endEpoch) == ERC20(WETH).balanceOf(CHAD));
        console.log("Chad");
        vm.stopPrank();

        //DEGEN risk WITHDRAW
        vm.startPrank(DEGEN);
        assets = vRisk.balanceOf(DEGEN, endEpoch);
        vRisk.withdraw(endEpoch, assets, DEGEN, DEGEN);

        assertTrue(vRisk.balanceOf(DEGEN,endEpoch) == NULL_BALANCE);
        entitledShares = vRisk.previewWithdraw(endEpoch, assets);
        //TODO assertTrue(entitledShares - vRisk.calculateWithdrawalFeeValue(entitledShares - assets, endEpoch) == ERC20(WETH).balanceOf(DEGEN));
        console.log("Degen");
        vm.stopPrank();

        emit log_named_uint("risk balance", ERC20(WETH).balanceOf(address(vRisk)));

    }

    function testControllerDepeg() public{

        depositDepeg();

        hedge = vaultFactory.getVaults(1)[0];
        risk = vaultFactory.getVaults(1)[1];

        vHedge = Vault(hedge);
        vRisk = Vault(risk);

        vm.warp(beginEpoch + 10 days);

        emit log_named_int("strike price", vHedge.strikePrice());
        emit log_named_int("oracle price", controller.getLatestPrice(TOKEN_FRAX));
        assertTrue(controller.getLatestPrice(TOKEN_FRAX) > 900000000000000000 && controller.getLatestPrice(TOKEN_FRAX) < 1000000000000000000, "oracle price is not in range");
        assertTrue(vHedge.strikePrice() > 900000000000000000 && controller.getLatestPrice(TOKEN_FRAX) < 1000000000000000000, "strike price is not in range");

        controller.triggerDepeg(SINGLE_MARKET_INDEX, endEpoch);
        
        //whoever has the lowest tvl will be taken a fee, since the other side had more tvl,
        //since they swap tvl in depegs
        if(vRisk.idFinalTVL(endEpoch) > vHedge.idFinalTVL(endEpoch)){
            emit log_named_uint("risk fee", vRisk.epochTreasuryFee(endEpoch));
            emit log_named_uint("hedge fee", vHedge.epochTreasuryFee(endEpoch));
            uint feeFrom = vRisk.idFinalTVL(endEpoch) - vHedge.idFinalTVL(endEpoch);
            assertTrue(vHedge.epochTreasuryFee(endEpoch) == vHedge.calculateWithdrawalFeeValue(feeFrom, endEpoch), "hedge fee is not correct");
            assertTrue(vRisk.epochTreasuryFee(endEpoch) == 0, "risk fee is not 0");
        }
        if(vRisk.idFinalTVL(endEpoch) < vHedge.idFinalTVL(endEpoch)){
            emit log_named_uint("hedge fee", vHedge.epochTreasuryFee(endEpoch));
            emit log_named_uint("risk fee", vRisk.epochTreasuryFee(endEpoch));
            uint feeFrom = vHedge.idFinalTVL(endEpoch) - vRisk.idFinalTVL(endEpoch);
            assertTrue(vHedge.epochTreasuryFee(endEpoch) == 0, "hedge fee is not 0");
            assertTrue(vRisk.epochTreasuryFee(endEpoch) == vRisk.calculateWithdrawalFeeValue(feeFrom, endEpoch), "risk fee is not correct");
        }
    }

    function testControllerEndEpoch() public{

        testDeposit();

        hedge = vaultFactory.getVaults(1)[0];
        risk = vaultFactory.getVaults(1)[1];

        vHedge = Vault(hedge);
        vRisk = Vault(risk);

        vm.warp(endEpoch + 1 days);

        emit log_named_int("strike price", vHedge.strikePrice());
        emit log_named_int("oracle price", controller.getLatestPrice(TOKEN_FRAX));

        controller.triggerEndEpoch(SINGLE_MARKET_INDEX, endEpoch);
        
        emit log_named_uint("total assets value", vHedge.totalAssets(endEpoch));
        
        uint feeRisk = vRisk.calculateWithdrawalFeeValue(vHedge.idFinalTVL(endEpoch), endEpoch);
        assertTrue(feeRisk == vRisk.epochTreasuryFee(endEpoch), "fee not equal");
        assertTrue(vRisk.idClaimTVL(endEpoch) == vHedge.idFinalTVL(endEpoch) + vRisk.idFinalTVL(endEpoch), "Claim TVL not total");
        assertTrue(NULL_BALANCE == vHedge.idClaimTVL(endEpoch), "Hedge Claim TVL not zero");
    }

    function testCreateController() public {
        testController = new Controller(address(vaultFactory), ARBITRUM_SEQUENCER);
        assertEq(address(vaultFactory), address(testController.vaultFactory()));
    }

    function testTriggerDepeg() public {
        depositDepeg();
        vm.startPrank(ADMIN);
        depegOracle = new DepegOracle(address(ORACLE_FRAX), address(ADMIN));
        vaultFactory.createNewMarket(FEE, TOKEN_FRAX, DEPEG_AAA, beginEpoch, endEpoch, address(depegOracle), "y2kFRAX_99*");
        vm.stopPrank();

        vm.warp(beginEpoch + 1 days);
        controller.triggerDepeg(vaultFactory.marketIndex(), endEpoch);
        
    }

    function testTriggerEndEpoch() public {
        depositDepeg();
        vm.startPrank(ADMIN);
        
        vaultFactory.createNewMarket(FEE, TOKEN_FRAX, DEPEG_AAA, beginEpoch, endEpoch, ORACLE_FRAX, "y2kFRAX_99*");
        vm.warp(endEpoch + 1 days);
        controller.triggerEndEpoch(SINGLE_MARKET_INDEX, endEpoch);
        testFactory = controller.vaultFactory();
        assertEq(vaultFactory.getVaults(vaultFactory.marketIndex()), testFactory.getVaults(testFactory.marketIndex()));
        vm.stopPrank();
    }

    function testNullEpochHedge() public {

        vm.startPrank(ADMIN);
        vm.deal(DEGEN, AMOUNT);
        vaultFactory.createNewMarket(FEE, TOKEN_FRAX, DEPEG_AAA, beginEpoch, endEpoch, ORACLE_FRAX, "y2kFRAX_99*");
        vm.stopPrank();

        hedge = vaultFactory.getVaults(1)[0];
        risk = vaultFactory.getVaults(1)[1];
        vHedge = Vault(hedge);
        vRisk = Vault(risk);

        emit log_named_uint("WETH balance", ERC20(WETH).balanceOf(DEGEN));
        vm.startPrank(DEGEN);
        vHedge.depositETH{value: AMOUNT}(endEpoch, DEGEN);
        vm.stopPrank();

        emit log_named_uint("WETH balance", ERC20(WETH).balanceOf(hedge));

        vm.warp(vHedge.idEpochBegin(endEpoch));
        controller.triggerNullEpoch(vaultFactory.marketIndex(), endEpoch);
        assertTrue(vHedge.idClaimTVL(endEpoch) == AMOUNT && vRisk.idClaimTVL(endEpoch) == 0, "Claim TVL not zero");
        assertTrue(vHedge.idFinalTVL(endEpoch) == AMOUNT && vRisk.idFinalTVL(endEpoch) == 0, "Final TVL not zero");
        assertTrue(vHedge.totalAssets(endEpoch) == AMOUNT && vRisk.totalAssets(endEpoch) == 0, "Total TVL not zero");

        vm.startPrank(DEGEN);
        vHedge.withdraw(endEpoch, AMOUNT, DEGEN, DEGEN);
        vm.stopPrank();

        assertTrue(ERC20(WETH).balanceOf(DEGEN) == AMOUNT, "WETH not returned");
        emit log_named_uint("WETH balance", ERC20(WETH).balanceOf(DEGEN));
    }

    function testNullEpochRisk() public {

        vm.startPrank(ADMIN);
        vm.deal(DEGEN, AMOUNT);
        vaultFactory.createNewMarket(FEE, TOKEN_FRAX, DEPEG_AAA, beginEpoch, endEpoch, ORACLE_FRAX, "y2kFRAX_99*");
        vm.stopPrank();

        hedge = vaultFactory.getVaults(1)[0];
        risk = vaultFactory.getVaults(1)[1];
        vHedge = Vault(hedge);
        vRisk = Vault(risk);
        
        emit log_named_uint("WETH balance", ERC20(WETH).balanceOf(DEGEN));
        vm.startPrank(DEGEN);
        vRisk.depositETH{value: AMOUNT}(endEpoch, DEGEN);
        vm.stopPrank();

        vm.warp(vRisk.idEpochBegin(endEpoch));
        controller.triggerNullEpoch(vaultFactory.marketIndex(), endEpoch);
        assertTrue(vRisk.idClaimTVL(endEpoch) == AMOUNT && vHedge.idClaimTVL(endEpoch) == 0, "Claim TVL not zero");
        assertTrue(vRisk.idFinalTVL(endEpoch) == AMOUNT && vHedge.idFinalTVL(endEpoch) == 0, "Final TVL not zero");
        assertTrue(vRisk.totalAssets(endEpoch) == AMOUNT && vHedge.totalAssets(endEpoch) == 0, "Total TVL not zero");
        
        emit log_named_uint("WETH balance", ERC20(WETH).balanceOf(risk));

        vm.startPrank(DEGEN);
        vRisk.withdraw(endEpoch, AMOUNT, DEGEN, DEGEN);
        vm.stopPrank();

        assertTrue(ERC20(WETH).balanceOf(DEGEN) == AMOUNT, "WETH not returned");
        emit log_named_uint("WETH balance", ERC20(WETH).balanceOf(DEGEN));
    }

    function testPegOracleMarketCreation() public {
        pegOracle = new PegOracle(ORACLE_STETH, ORACLE_ETH);
        pegOracle2 = new PegOracle(ORACLE_FRAX, ORACLE_FEI);

        // //Eth price feed minus something to trigger depeg
        fakeOracle = new FakeOracle(ORACLE_ETH, CREATION_STRK);
        pegOracle3 = new PegOracle(address(fakeOracle), ORACLE_ETH);

        vm.startPrank(ADMIN);
        vaultFactory.createNewMarket(FEE, TOKEN_STETH, DEPEG_AAA, beginEpoch, endEpoch, address(pegOracle), "y2kSTETH_99*");
        vaultFactory.createNewMarket(FEE, TOKEN_FEI, DEPEG_BBB, beginEpoch, endEpoch, address(pegOracle2), "y2kSTETH_97*");
        vaultFactory.createNewMarket(FEE, WETH, DEPEG_CCC, beginEpoch, endEpoch, address(pegOracle3), "y2kSTETH_95*");
        vm.stopPrank();

        vm.prank(ADMIN);
        deposit(1);
        vm.prank(ADMIN);
        deposit(2);
        vm.prank(ADMIN);
        deposit(3);

        oracle1price1 = pegOracle.getOracle1_Price();
        oracle1price2 = pegOracle.getOracle2_Price();
        emit log_named_int("oracle1price1", oracle1price1);
        emit log_named_int("oracle1price2", oracle1price2);
        (
            ,
            price,
            ,
            ,
            
        ) = pegOracle.latestRoundData();
        emit log_named_int("oracle1price1 / oracle1price2", price);

        oracle2price1 = pegOracle2.getOracle1_Price();
        oracle2price2 = pegOracle2.getOracle2_Price();
        emit log_named_int("oracle2price1", oracle2price1);
        emit log_named_int("oracle2price2", oracle2price2);
        (
            ,
            price,
            ,
            ,
            
        ) = pegOracle2.latestRoundData();
        emit log_named_int("oracle2price1 / oracle2price2", price);

        oracle3price1 = pegOracle3.getOracle1_Price();
        oracle3price2 = pegOracle3.getOracle2_Price();
        emit log_named_int("oracle3price1", oracle3price1);
        emit log_named_int("oracle3price2", oracle3price2);
        (
            ,
            price,
            ,
            ,
            
        ) = pegOracle3.latestRoundData();
        emit log_named_int("oracle3price1 / oracle3price2", price);

        controllerEndEpoch(TOKEN_STETH,1);
        controllerEndEpoch(TOKEN_FEI,2);
        controllerEndEpoch(WETH,3);

        withdrawEndEpoch();
    }

    /*///////////////////////////////////////////////////////////////
                           REVERT cases
    //////////////////////////////////////////////////////////////*/
    
    function testSequencerDown() public {
        //create invalid controller(w/any address other than ARBITRUM_SEQUENCER)
        controller = new Controller(address(vaultFactory), ORACLE_FEI);

        //create fake oracle for price feed
        vm.startPrank(ADMIN);
        fakeOracle = new FakeOracle(ORACLE_FRAX, STRIKE_PRICE_FAKE_ORACLE);
        vaultFactory.createNewMarket(FEE, TOKEN_FRAX, DEPEG_AAA, beginEpoch, endEpoch, address(fakeOracle), "y2kFRAX_99*");
        vm.stopPrank();

        //expect SequencerDown
        vm.startPrank(ADMIN);
        vm.expectRevert(Controller.SequencerDown.selector);
        controller.getLatestPrice(TOKEN_FRAX);
        vm.stopPrank();
    }

    function testFailControllerMarketDoesNotExist() public {
        //create fake oracle for price feed
        depositDepeg();

        //expect MarketDoesNotExist
        emit log_named_uint("Number of markets", vaultFactory.marketIndex());
        vm.warp(endEpoch - 1 days);
        //vm.expectRevert(abi.encodeWithSelector(Controller.MarketDoesNotExist.selector, MARKET_OVERFLOW));
        controller.triggerDepeg(69, endEpoch);
    }

    function testFailControllerDoubleTrigger() public {
        //create fake oracle for price feed
        vm.startPrank(ADMIN);
        //FakeOracle fakeOracle = new FakeOracle(ORACLE_FRAX, STRIKE_PRICE_FAKE_ORACLE);
        vaultFactory.createNewMarket(FEE, TOKEN_FRAX, DEPEG_AAA, beginEpoch, endEpoch, ORACLE_FRAX, "y2kFRAX_99*");
        vm.stopPrank();

        deposit(1);
        vm.warp(endEpoch + 1);
        controller.triggerEndEpoch(1, endEpoch);

        controller.triggerEndEpoch(1, endEpoch);
    }

    function testFailControllerDoubleTrigger2() public {
        depositDepeg();
        vm.warp(beginEpoch + 5);
        controllerDepeg(TOKEN_FRAX, 1);
        //vm.expectRevert(Controller.EpochFinishedAlready.selector);
        controller.triggerNullEpoch(1, endEpoch);
    }

   function testControllerZeroAddress() public {    
        //expect ZeroAddress for ADMIN
        vm.startPrank(ADMIN);
        vaultFactory.createNewMarket(FEE, TOKEN_FRAX, DEPEG_AAA, beginEpoch, endEpoch, ORACLE_FRAX, "y2kFRAX_99*");
        vm.expectRevert(Controller.ZeroAddress.selector);
        controller = new Controller(address(0), ARBITRUM_SEQUENCER);
        vm.stopPrank();

        //expect ZeroAddress for ARBITRUM_SEQUENCER
        vm.startPrank(ADMIN);
        vaultFactory.createNewMarket(FEE, TOKEN_FRAX, DEPEG_AAA, beginEpoch, endEpoch, ORACLE_FRAX, "y2kFRAX_99*");
        vm.expectRevert(Controller.ZeroAddress.selector);
        controller = new Controller(address(ADMIN), address(0));
        vm.stopPrank();
    }

    function testFailControllerEpochNotExpired() public {
        vm.startPrank(ADMIN);
        vaultFactory.createNewMarket(FEE, TOKEN_FRAX, DEPEG_AAA, beginEpoch, endEpoch, ORACLE_FRAX, "y2kFRAX_99*");
        vm.stopPrank();

        //vm.expectRevert(Controller.EpochNotExpired.selector);
        //controller.triggerEndEpoch(vaultFactory.marketIndex(), endEpoch);

        vm.warp(endEpoch - 1);

        //vm.expectRevert(Controller.EpochNotExpired.selector);
        controller.triggerEndEpoch(vaultFactory.marketIndex(), endEpoch);
    }


    function testFailEpochNotExist() public {
        //testing triggerEndEpoch
        vm.startPrank(ADMIN);
        vaultFactory.createNewMarket(FEE, TOKEN_FRAX, DEPEG_AAA, beginEpoch, endEpoch, ORACLE_FRAX, "y2kFRAX_99*");
        vm.stopPrank();
        
        //vm.expectRevert(Controller.EpochNotExist.selector);
        controller.triggerEndEpoch(vaultFactory.marketIndex(), 2);
    }

    function testFailEpochNotExpired() public {
        //testing triggerEndEpoch
        vm.startPrank(ADMIN);
        vaultFactory.createNewMarket(FEE, TOKEN_FRAX, DEPEG_AAA, beginEpoch, endEpoch, ORACLE_FRAX, "y2kFRAX_99*");
        vm.stopPrank();
        
        vm.startPrank(ADMIN);
        vm.warp(endEpoch - 1 days);
        //vm.expectRevert(Controller.EpochNotExpired.selector);
        controller.triggerEndEpoch(vaultFactory.marketIndex(), endEpoch);
        

        //testing triggerDepeg
        vm.startPrank(ADMIN);
        fakeOracle = new FakeOracle(ORACLE_FRAX, 1);
        vaultFactory.createNewMarket(FEE, TOKEN_FRAX, DEPEG_AAA, beginEpoch, endEpoch, address(fakeOracle), "y2kFRAX_99*");
        //controller.triggerDepeg(vaultFactory.marketIndex(), endEpoch);
        //vm.expectRevert(Controller.EpochNotExpired.selector);
        //controller.triggerDepeg(vaultFactory.marketIndex(), endEpoch);
        vm.stopPrank();
    }

    function testFailPriceNotAtStrikePrice() public {
        vm.startPrank(ADMIN);
        vaultFactory.createNewMarket(FEE, TOKEN_FRAX, DEPEG_AAA, beginEpoch, endEpoch, ORACLE_FRAX, "y2kFRAX_99*");
        controller.triggerDepeg(vaultFactory.marketIndex(), endEpoch);
        vm.stopPrank();
    }

    function testOraclePriceZero() public {
        vm.startPrank(ADMIN);
        fakeOracle = new FakeOracle(ORACLE_FRAX, 0);
        vaultFactory.createNewMarket(FEE, TOKEN_FRAX, DEPEG_AAA, beginEpoch, endEpoch, address(fakeOracle), "y2kFRAX_99*");
        vm.expectRevert(Controller.OraclePriceZero.selector);
        controller.getLatestPrice(TOKEN_FRAX);
        vm.stopPrank();
    }

    function testFailEpochNotStarted() public {
        vm.startPrank(ADMIN);
        fakeOracle = new FakeOracle(ORACLE_FRAX, 1);
        vaultFactory.createNewMarket(FEE, TOKEN_FRAX, DEPEG_AAA, beginEpoch, endEpoch, address(fakeOracle), "y2kFRAX_99*");
        //vm.expectRevert(Controller.EpochNotStarted.selector);
        controller.triggerDepeg(vaultFactory.marketIndex(), endEpoch);
        vm.stopPrank();
    }

    function testFailEpochExpired() public {
        vm.startPrank(ADMIN);
        fakeOracle = new FakeOracle(ORACLE_FRAX, 1);
        vaultFactory.createNewMarket(FEE, TOKEN_FRAX, DEPEG_AAA, beginEpoch, endEpoch, address(fakeOracle), "y2kFRAX_99*");
        vm.warp(endEpoch + 1);
        //vm.expectRevert(Controller.EpochExpired.selector);
        controller.triggerDepeg(vaultFactory.marketIndex(), endEpoch);
        vm.stopPrank();
    }

    function testFailNullEpochRevEpochNotStarted() public {
        //need to fix triggerNullEpoch
        vm.startPrank(ADMIN);
        vm.deal(ALICE, DEGEN_MULTIPLIER * AMOUNT);
        vaultFactory.createNewMarket(FEE, TOKEN_FRAX, DEPEG_AAA, beginEpoch, endEpoch, ORACLE_FRAX, "y2kFRAX_99*");
        vm.stopPrank();

        hedge = vaultFactory.getVaults(1)[0];
        vHedge = Vault(hedge);
        risk = vaultFactory.getVaults(1)[1];
        vRisk = Vault(risk);

        vm.startPrank(ALICE);
        vHedge.depositETH{value: AMOUNT}(endEpoch, ALICE);
        vm.stopPrank();
        
        vm.startPrank(ADMIN);
        vm.warp(beginEpoch - 1 days);

        //EPOCH NOT STARTED
        //vm.expectRevert(Controller.EpochNotStarted.selector);
        controller.triggerNullEpoch(vaultFactory.marketIndex(), endEpoch);
        vm.stopPrank();
    }
    
    function testFailNullEpochRevNotZeroTvl() public {
        vm.startPrank(ADMIN);
        vm.deal(ALICE, DEGEN_MULTIPLIER * AMOUNT);
        vaultFactory.createNewMarket(FEE, TOKEN_FRAX, DEPEG_AAA, beginEpoch, endEpoch, ORACLE_FRAX, "y2kFRAX_99*");
        vm.stopPrank();

        hedge = vaultFactory.getVaults(1)[0];
        vHedge = Vault(hedge);
        risk = vaultFactory.getVaults(1)[1];
        vRisk = Vault(risk);

        vm.startPrank(ALICE);
        vHedge.depositETH{value: AMOUNT}(endEpoch, ALICE);
        vRisk.depositETH{value: AMOUNT}(endEpoch, ALICE);
        vm.stopPrank();
        
        vm.startPrank(ADMIN);
        vm.warp(beginEpoch + 1);
        
        //EPOCH NOT ZERO TVL
        //vm.expectRevert(Controller.VaultNotZeroTVL.selector);
        controller.triggerNullEpoch(vaultFactory.marketIndex(), endEpoch);
        
        vm.stopPrank();
    }

    function testFailNotStrikePrice() public {
        //revert working as expected but expectRevert not working
        vm.startPrank(ADMIN);
        vaultFactory.createNewMarket(FEE, TOKEN_FRAX, DEPEG_AAA, beginEpoch, endEpoch, ORACLE_FRAX, "y2kFRAX_99*");
        vm.warp(endEpoch);
        hedge = vaultFactory.getVaults(1)[0];
        vHedge = Vault(hedge);
        //vm.expectRevert(abi.encodeWithSelector(Controller.PriceNotAtStrikePrice.selector, controller.getLatestPrice(vHedge.tokenInsured())));
        controller.triggerDepeg(vaultFactory.marketIndex(), endEpoch);
        vm.stopPrank();
    }

    /*///////////////////////////////////////////////////////////////
                           FUZZ cases
    //////////////////////////////////////////////////////////////*/

    function testFuzzDeposit(uint256 ethValue) public {
        vm.assume(ethValue >= 1 && ethValue < 256);

        vm.deal(ALICE, ethValue);
        vm.deal(BOB, ethValue * BOB_MULTIPLIER);
        vm.deal(CHAD, ethValue * CHAD_MULTIPLIER);
        vm.deal(DEGEN, ethValue * DEGEN_MULTIPLIER);

        vm.prank(ADMIN);
        vaultFactory.createNewMarket(FEE, TOKEN_FRAX, DEPEG_AAA, beginEpoch, endEpoch, ORACLE_FRAX, "y2kFRAX_99*");

        hedge = vaultFactory.getVaults(1)[0];
        risk = vaultFactory.getVaults(1)[1];
        
        vHedge = Vault(hedge);
        vRisk = Vault(risk);

        //ALICE hedge deposit
        vm.startPrank(ALICE);
        ERC20(WETH).approve(hedge, ethValue);
        vHedge.depositETH{value: ethValue}(endEpoch, ALICE);
        vm.stopPrank();

        //BOB hedge deposit
        vm.startPrank(BOB);
        ERC20(WETH).approve(hedge, ethValue * BOB_MULTIPLIER);
        vHedge.depositETH{value: ethValue * BOB_MULTIPLIER}(endEpoch, BOB);

        assertTrue(vHedge.balanceOf(BOB,endEpoch) == (ethValue * BOB_MULTIPLIER));
        vm.stopPrank();

        //CHAD risk deposit
        vm.startPrank(CHAD);
        ERC20(WETH).approve(risk, ethValue * CHAD_MULTIPLIER);
        vRisk.depositETH{value: ethValue * CHAD_MULTIPLIER}(endEpoch, CHAD);

        assertTrue(vRisk.balanceOf(CHAD,endEpoch) == (ethValue * CHAD_MULTIPLIER));
        vm.stopPrank();

        //DEGEN risk deposit
        vm.startPrank(DEGEN);
        ERC20(WETH).approve(risk, ethValue * DEGEN_MULTIPLIER);
        vRisk.depositETH{value: ethValue * DEGEN_MULTIPLIER}(endEpoch, DEGEN);

        assertTrue(vRisk.balanceOf(DEGEN,endEpoch) == (ethValue * DEGEN_MULTIPLIER));
        vm.stopPrank();
    }

    function testFuzzControllerDepeg(uint256 ethValue) public{
        vm.assume(ethValue >= 1 && ethValue < 256);
        fuzzDepositDepeg(ethValue);

        hedge = vaultFactory.getVaults(1)[0];
        risk = vaultFactory.getVaults(1)[1];

        vHedge = Vault(hedge);
        vRisk = Vault(risk);

        vm.warp(beginEpoch + 10 days);

        emit log_named_int("strike price", vHedge.strikePrice());
        emit log_named_int("oracle price", controller.getLatestPrice(TOKEN_FRAX));
        assertTrue(controller.getLatestPrice(TOKEN_FRAX) > 900000000000000000 && controller.getLatestPrice(TOKEN_FRAX) < 1000000000000000000);
        assertTrue(vHedge.strikePrice() > 900000000000000000 && controller.getLatestPrice(TOKEN_FRAX) < 1000000000000000000);

        controller.triggerDepeg(SINGLE_MARKET_INDEX, endEpoch);

        assertTrue(vHedge.totalAssets(endEpoch) == vRisk.idClaimTVL(endEpoch), "Claim TVL Risk not equal to Total Tvl Hedge");
        assertTrue(vRisk.totalAssets(endEpoch) == vHedge.idClaimTVL(endEpoch), "Claim TVL Hedge not equal to Total Tvl Risk");
    }

    function testFuzzControllerEndEpoch(uint256 ethValue) public{

        testFuzzDeposit(ethValue);

        hedge = vaultFactory.getVaults(1)[0];
        risk = vaultFactory.getVaults(1)[1];

        vHedge = Vault(hedge);
        vRisk = Vault(risk);

        vm.warp(endEpoch + 1 days);

        emit log_named_int("strike price", vHedge.strikePrice());
        emit log_named_int("oracle price", controller.getLatestPrice(TOKEN_FRAX));

        controller.triggerEndEpoch(SINGLE_MARKET_INDEX, endEpoch);
        
        emit log_named_uint("total assets value", vHedge.totalAssets(endEpoch));
        
        uint feeRisk = vRisk.calculateWithdrawalFeeValue(vHedge.idFinalTVL(endEpoch), endEpoch);
        assertTrue(feeRisk == vRisk.epochTreasuryFee(endEpoch), "fee not equal");
        assertTrue(vRisk.idClaimTVL(endEpoch) == vHedge.idFinalTVL(endEpoch) + vRisk.idFinalTVL(endEpoch), "Claim TVL not total");
        assertTrue(NULL_BALANCE == vHedge.idClaimTVL(endEpoch), "Hedge Claim TVL not zero");
    }

    function testFuzzWithdrawDepeg(uint256 ethValue) public {
        vm.assume(ethValue >= 1 && ethValue < 256);
        testFuzzControllerDepeg(ethValue);

        hedge = vaultFactory.getVaults(1)[0];
        risk = vaultFactory.getVaults(1)[1];

        vHedge = Vault(hedge);
        vRisk = Vault(risk);

        //ALICE hedge WITHDRAW
        vm.startPrank(ALICE);
        assets = vHedge.balanceOf(ALICE,endEpoch);
        vHedge.withdraw(endEpoch, assets, ALICE, ALICE);

        assertTrue(vHedge.balanceOf(ALICE,endEpoch) == NULL_BALANCE);
        entitledShares = vHedge.previewWithdraw(endEpoch, assets);
        assertTrue(entitledShares - vHedge.calculateWithdrawalFeeValue(entitledShares - assets, endEpoch) == ERC20(WETH).balanceOf(ALICE));

        vm.stopPrank();

        //BOB hedge WITHDRAW
        vm.startPrank(BOB);
        assets = vHedge.balanceOf(BOB,endEpoch);
        vHedge.withdraw(endEpoch, assets, BOB, BOB);
        
        assertTrue(vHedge.balanceOf(BOB,endEpoch) == NULL_BALANCE);
        entitledShares = vHedge.previewWithdraw(endEpoch, assets);
        assertTrue(entitledShares - vHedge.calculateWithdrawalFeeValue(entitledShares - assets, endEpoch) == ERC20(WETH).balanceOf(BOB));

        vm.stopPrank();

        emit log_named_uint("hedge balance", ERC20(WETH).balanceOf(address(vHedge)));

        //CHAD risk WITHDRAW
        vm.startPrank(CHAD);
        assets = vRisk.balanceOf(CHAD, endEpoch);
        vRisk.withdraw(endEpoch, assets, CHAD, CHAD);

        assertTrue(vRisk.balanceOf(CHAD,endEpoch) == NULL_BALANCE);
        entitledShares = vRisk.previewWithdraw(endEpoch, assets);
        assertTrue(entitledShares == ERC20(WETH).balanceOf(CHAD));

        vm.stopPrank();

        //DEGEN risk WITHDRAW
        vm.startPrank(DEGEN);
        assets = vRisk.balanceOf(DEGEN, endEpoch);
        vRisk.withdraw(endEpoch, assets, DEGEN, DEGEN);

        assertTrue(vRisk.balanceOf(DEGEN,endEpoch) == NULL_BALANCE);
        entitledShares = vRisk.previewWithdraw(endEpoch, assets);
        assertTrue(entitledShares == ERC20(WETH).balanceOf(DEGEN));

        vm.stopPrank();

        emit log_named_uint("risk balance", ERC20(WETH).balanceOf(address(vRisk)));

    }

    function testFuzzWithdrawEndEpoch(uint256 ethValue) public {
        vm.assume(ethValue >= 1 && ethValue < 256);
        testFuzzControllerEndEpoch(ethValue);

        hedge = vaultFactory.getVaults(1)[0];
        risk = vaultFactory.getVaults(1)[1];

        vHedge = Vault(hedge);
        vRisk = Vault(risk);

        //ALICE hedge WITHDRAW
        vm.startPrank(ALICE);
        assets = vHedge.balanceOf(ALICE,endEpoch);
        vHedge.withdraw(endEpoch, assets, ALICE, ALICE);

        assertTrue(vHedge.balanceOf(ALICE,endEpoch) == NULL_BALANCE);
        entitledShares = vHedge.previewWithdraw(endEpoch, assets);
        assertTrue(entitledShares == ERC20(WETH).balanceOf(ALICE));

        vm.stopPrank();

        //BOB hedge WITHDRAW
        vm.startPrank(BOB);
        assets = vHedge.balanceOf(BOB,endEpoch);
        vHedge.withdraw(endEpoch, assets, BOB, BOB);
        
        assertTrue(vHedge.balanceOf(BOB,endEpoch) == NULL_BALANCE);
        entitledShares = vHedge.previewWithdraw(endEpoch, assets);
        assertTrue(entitledShares == ERC20(WETH).balanceOf(BOB));

        vm.stopPrank();

        emit log_named_uint("hedge balance", ERC20(WETH).balanceOf(address(vHedge)));

        //CHAD risk WITHDRAW
        vm.startPrank(CHAD);
        assets = vRisk.balanceOf(CHAD, endEpoch);
        vRisk.withdraw(endEpoch, assets, CHAD, CHAD);

        assertTrue(vRisk.balanceOf(CHAD,endEpoch) == NULL_BALANCE);
        entitledShares = vRisk.previewWithdraw(endEpoch, assets);
        //TODO assertTrue(entitledShares - vHedge.calculateWithdrawalFeeValue(entitledShares - assets, endEpoch) == ERC20(WETH).balanceOf(CHAD));

        vm.stopPrank();

        //DEGEN risk WITHDRAW
        vm.startPrank(DEGEN);
        assets = vRisk.balanceOf(DEGEN, endEpoch);
        vRisk.withdraw(endEpoch, assets, DEGEN, DEGEN);

        assertTrue(vRisk.balanceOf(DEGEN,endEpoch) == NULL_BALANCE);
        entitledShares = vRisk.previewWithdraw(endEpoch, assets);
        //TODO assertTrue(entitledShares - vHedge.calculateWithdrawalFeeValue(entitledShares - assets, endEpoch) == ERC20(WETH).balanceOf(DEGEN));

        vm.stopPrank();

        emit log_named_uint("risk balance", ERC20(WETH).balanceOf(address(vRisk)));

    }
}