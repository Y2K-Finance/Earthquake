// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Test.sol";
import {Vault} from "../src/Vault.sol";
import {VaultFactory} from "../src/VaultFactory.sol";
import {Controller} from "../src/Controller.sol";
import {PegOracle} from "../src/oracles/PegOracle.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";
import "@chainlink/interfaces/AggregatorV3Interface.sol";
import {Helper} from "./Helper.sol";
import {RewardsFactory} from "../src/rewards/RewardsFactory.sol";

import {FakeOracle} from "./oracles/FakeOracle.sol";
import {IWETH} from "./interfaces/IWETH.sol";

contract RevertTest is Helper {

    /*///////////////////////////////////////////////////////////////
                           CONTROLLER reverts
    //////////////////////////////////////////////////////////////*/
    
    function testSequencerDown() public {
        //create invalid controller(w/any address other than arbitrum_sequencer)
        controller = new Controller(address(vaultFactory), oracleFEI);

        //create fake oracle for price feed
        vm.startPrank(admin);
        FakeOracle fakeOracle = new FakeOracle(oracleFRAX, STRIKE_PRICE_FAKE_ORACLE);
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, address(fakeOracle), "y2kFRAX_99*");
        vm.stopPrank();

        //expect SequencerDown
        vm.startPrank(admin);
        vm.expectRevert(Controller.SequencerDown.selector);
        controller.getLatestPrice(tokenFRAX);
        vm.stopPrank();
    }

    function testControllerMarketDoesNotExist() public {
        //create fake oracle for price feed
        vm.startPrank(admin);
        //FakeOracle fakeOracle = new FakeOracle(oracleFRAX, STRIKE_PRICE_FAKE_ORACLE);
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_99*");
        vm.stopPrank();

        //expect MarketDoesNotExist
        vm.startPrank(admin);
        emit log_named_uint("Number of markets", vaultFactory.marketIndex());
        vm.warp(endEpoch);
        vm.expectRevert(abi.encodeWithSelector(Controller.MarketDoesNotExist.selector, MARKET_OVERFLOW));
        controller.triggerDepeg(1, endEpoch);
        vm.stopPrank();
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

    function testControllerDoubleTrigger2() public {
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
        FakeOracle fakeOracle = new FakeOracle(oracleFRAX, 1);
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
        FakeOracle fakeOracle = new FakeOracle(oracleFRAX, 0);
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, address(fakeOracle), "y2kFRAX_99*");
        vm.expectRevert(Controller.OraclePriceZero.selector);
        controller.getLatestPrice(tokenFRAX);
        vm.stopPrank();
    }

    function testFailEpochNotStarted() public {
        vm.startPrank(admin);
        FakeOracle fakeOracle = new FakeOracle(oracleFRAX, 1);
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, address(fakeOracle), "y2kFRAX_99*");
        //vm.expectRevert(Controller.EpochNotStarted.selector);
        controller.triggerDepeg(vaultFactory.marketIndex(), endEpoch);
        vm.stopPrank();
    }

    function testFailEpochExpired() public {
        vm.startPrank(admin);
        FakeOracle fakeOracle = new FakeOracle(oracleFRAX, 1);
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

        address hedge = vaultFactory.getVaults(1)[0];
        Vault vHedge = Vault(hedge);
        address risk = vaultFactory.getVaults(1)[1];
        Vault vRisk = Vault(risk);

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

        address hedge = vaultFactory.getVaults(1)[0];
        Vault vHedge = Vault(hedge);
        address risk = vaultFactory.getVaults(1)[1];
        Vault vRisk = Vault(risk);

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
        address hedge = vaultFactory.getVaults(1)[0];
        Vault vHedge = Vault(hedge);
        //vm.expectRevert(abi.encodeWithSelector(Controller.PriceNotAtStrikePrice.selector, controller.getLatestPrice(vHedge.tokenInsured())));
        controller.triggerDepeg(vaultFactory.marketIndex(), endEpoch);
        vm.stopPrank();
    }


    /*///////////////////////////////////////////////////////////////
                           VAULTFACTORY reverts
    //////////////////////////////////////////////////////////////*/

    function testMarketDoesNotExist() public {
        //create fake oracle for price feed
        vm.startPrank(admin);
        FakeOracle fakeOracle = new FakeOracle(oracleFRAX, STRIKE_PRICE_FAKE_ORACLE);
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, address(fakeOracle), "y2kFRAX_99*");
        vm.stopPrank();

        //expect MarketDoesNotExist
        vm.startPrank(admin);
        vm.expectRevert(abi.encodeWithSelector(VaultFactory.MarketDoesNotExist.selector, MARKET_OVERFLOW));
        vaultFactory.deployMoreAssets(MARKET_OVERFLOW, beginEpoch, endEpoch, FEE);
        vm.stopPrank();
    }

    function testAddressZero() public {
        vm.startPrank(admin);
        VaultFactory testFactory = new VaultFactory(admin, WETH, admin);
        vm.expectRevert(VaultFactory.AddressZero.selector);
        testFactory.setController(address(0));
        vm.stopPrank();
        
        //expect null treasury address
        vm.startPrank(admin);
        vm.expectRevert(VaultFactory.AddressZero.selector);
        testFactory = new VaultFactory(address(0), address(tokenFRAX), address(admin));
        vm.stopPrank();

        //expect null WETH address
        vm.startPrank(admin);
        vm.expectRevert(VaultFactory.AddressZero.selector);
        testFactory = new VaultFactory(address(controller), address(0), address(admin));
        vm.stopPrank();

        //expect null admin address
        vm.startPrank(admin);
        vm.expectRevert(VaultFactory.AddressZero.selector);
        testFactory = new VaultFactory(address(controller), address(tokenFRAX), address(0));
        vm.stopPrank();
    }

    function testAddressNotAdmin() public {
        vm.startPrank(alice);
        VaultFactory testFactory = new VaultFactory(admin, WETH, admin);
        vm.expectRevert(abi.encodeWithSelector(VaultFactory.AddressNotAdmin.selector, address(alice)));
        testFactory.setController(address(controller));
        vm.stopPrank();         
    }

    function testAddressFactoryNotInController() public {
        vm.startPrank(admin);
        VaultFactory testFactory = new VaultFactory(admin, WETH, admin);
        testFactory.setController(address(controller));
        vm.expectRevert(VaultFactory.AddressFactoryNotInController.selector);
        testFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_99*");
        vm.stopPrank();
    }

    function testControllerNotSet() public {
        vm.startPrank(admin);
        VaultFactory testFactory = new VaultFactory(admin, WETH, admin);
        vm.expectRevert(VaultFactory.ControllerNotSet.selector);
        testFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_99*");
        vm.stopPrank();
    }


    /*///////////////////////////////////////////////////////////////
                           VAULT reverts
    //////////////////////////////////////////////////////////////*/

    function testFeeMoreThan() public {
        vm.startPrank(admin);
        Vault testVault = new Vault(tokenFRAX, "Frax stable", "FRAX", admin, oracleFRAX, VAULT_STRIKE_PRICE, address(controller));
        vm.expectRevert(abi.encodeWithSelector(Vault.FeeMoreThan150.selector, 151));
        testVault.createAssets(beginEpoch, endEpoch, 151);
        vm.stopPrank();
    }

    function testFeeCannotBeZero() public {
        vm.startPrank(admin);
        Vault testVault = new Vault(tokenFRAX, "Frax stable", "FRAX", admin, oracleFRAX, VAULT_STRIKE_PRICE, address(controller));
        vm.expectRevert(Vault.FeeCannotBe0.selector);
        testVault.createAssets(beginEpoch, endEpoch, 0);
        vm.stopPrank();
    }

    function testVaultMarketEpochDoesNotExist() public {
        vm.startPrank(admin);
        Vault testVault = new Vault(tokenFRAX, "Frax stable", "FRAX", admin, oracleFRAX, VAULT_STRIKE_PRICE, address(controller));
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_99*");
        vm.expectRevert(Vault.MarketEpochDoesNotExist.selector);
        testVault.deposit(endEpoch, 100, alice);
        vm.stopPrank();
    }

    function testEpochEndMustBeAfterBegin() public {
        vm.startPrank(admin);
        Vault testVault = new Vault(tokenFRAX, "Frax stable", "FRAX", admin, oracleFRAX, VAULT_STRIKE_PRICE, address(controller));
        vm.expectRevert(Vault.EpochEndMustBeAfterBegin.selector);
        testVault.createAssets(endEpoch, beginEpoch, FEE);
        vm.stopPrank();    
    }

    function testOwnerDidNotAuthorize() public {
        vm.deal(alice, 10 ether);
        
        vm.startPrank(admin);
        FakeOracle fakeOracle = new FakeOracle(oracleFRAX, STRIKE_PRICE_FAKE_ORACLE);
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, address(fakeOracle), "y2kFRAX_99*");
        vm.stopPrank();

        address hedge = vaultFactory.getVaults(1)[0];
        Vault vHedge = Vault(hedge);

        vm.startPrank(alice);
        ERC20(WETH).approve(hedge, 10 ether);
        vHedge.depositETH{value: 10 ether}(endEpoch, alice);

        assertTrue(vHedge.balanceOf(alice,endEpoch) == (10 ether));
        vm.stopPrank();

        vm.startPrank(bob);
        vm.warp(endEpoch + 1 days);
        controller.triggerEndEpoch(vaultFactory.marketIndex(), endEpoch);
        vm.expectRevert(abi.encodeWithSelector(Vault.OwnerDidNotAuthorize.selector, address(bob), address(alice)));
        vHedge.withdraw(endEpoch, 10 ether, bob, alice);
        vm.stopPrank();
    }

    function testAddressNotFactory() public {
        vm.startPrank(admin);
        Vault testVault = new Vault(tokenFRAX, "Frax stable", "FRAX", admin, oracleFRAX, VAULT_STRIKE_PRICE, address(controller));
        vm.stopPrank();
        
        vm.startPrank(alice);
        vm.expectRevert(abi.encodeWithSelector(Vault.AddressNotFactory.selector, address(alice)));
        testVault.changeTreasury(admin);
        vm.stopPrank(); 
    }

    

    function testVaultAddressNotController() public {
        vm.startPrank(admin);
        Vault testVault = new Vault(tokenFRAX, "Frax stable", "FRAX", admin, oracleFRAX, VAULT_STRIKE_PRICE, address(controller));
        vm.stopPrank();

        vm.startPrank(alice);
        vm.expectRevert(abi.encodeWithSelector(Vault.AddressNotController.selector, address(alice)));
        testVault.endEpoch(endEpoch);
        vm.stopPrank();       
    }

    function testVaultEpochNotFinished() public {
        vm.deal(alice, 10 ether);
        
        vm.startPrank(admin);
        FakeOracle fakeOracle = new FakeOracle(oracleFRAX, STRIKE_PRICE_FAKE_ORACLE);
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, address(fakeOracle), "y2kFRAX_99*");
        vm.stopPrank();

        address hedge = vaultFactory.getVaults(1)[0];
        Vault vHedge = Vault(hedge);

        vm.startPrank(alice);
        ERC20(WETH).approve(hedge, 10 ether);
        vHedge.depositETH{value: 10 ether}(endEpoch, alice);

        assertTrue(vHedge.balanceOf(alice,endEpoch) == (10 ether));
        vm.stopPrank();

        vm.startPrank(bob);
        vm.expectRevert(Vault.EpochNotFinished.selector);
        vHedge.withdraw(endEpoch, 10 ether, bob, alice);
        vm.stopPrank();
    }

    function testVaultEpochAlreadyStarted() public {
        vm.deal(alice, 20 ether);
        
        vm.startPrank(admin);
        FakeOracle fakeOracle = new FakeOracle(oracleFRAX, STRIKE_PRICE_FAKE_ORACLE);
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, address(fakeOracle), "y2kFRAX_99*");
        vm.stopPrank();

        address hedge = vaultFactory.getVaults(1)[0];
        Vault vHedge = Vault(hedge);

        vm.startPrank(alice);
        ERC20(WETH).approve(hedge, 10 ether);
        vHedge.depositETH{value: 10 ether}(endEpoch, alice);
        vm.warp(beginEpoch + 1 days);
        vm.expectRevert(Vault.EpochAlreadyStarted.selector);
        vHedge.deposit(endEpoch, 10 ether, alice);

        assertTrue(vHedge.balanceOf(alice,endEpoch) == (10 ether));
        vm.stopPrank();     
    }

    function testFailMarketEpochExists() public {
        vm.startPrank(admin);
        Vault testVault = new Vault(tokenFRAX, "Frax stable", "FRAX", admin, oracleFRAX, VAULT_STRIKE_PRICE, address(controller));
        testVault.createAssets(beginEpoch, endEpoch, FEE);
        testVault.createAssets(beginEpoch, endEpoch, FEE);
        vm.stopPrank();
    }

    function testVaultAddressZero() public {
        vm.startPrank(admin);
        Vault testVault = new Vault(tokenFRAX, "Frax stable", "FRAX", admin, oracleFRAX, VAULT_STRIKE_PRICE, address(controller));
        vm.stopPrank();

        vm.startPrank(admin);
        vm.warp(0);
        vm.expectRevert(Vault.AddressZero.selector);
        testVault.changeTreasury(address(0));
        vm.stopPrank();

        vm.startPrank(admin);
        vm.expectRevert(Vault.AddressZero.selector);
        testVault.changeController(address(0));
        vm.stopPrank();
    }

    function testFailZeroValue() public {
        vm.deal(alice, 20 ether);
        
        vm.startPrank(admin);
        FakeOracle fakeOracle = new FakeOracle(oracleFRAX, STRIKE_PRICE_FAKE_ORACLE);
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, address(fakeOracle), "y2kFRAX_99*");
        vm.stopPrank();

        address hedge = vaultFactory.getVaults(1)[0];
        Vault vHedge = Vault(hedge);

        vm.startPrank(alice);
        ERC20(WETH).approve(hedge, 10 ether);
        //vm.expectRevert(bytes("ZeroValue"));
        vHedge.depositETH{value: 0 ether}(endEpoch, alice);
        
        vm.warp(endEpoch + 1 days);
        //vm.expectRevert(bytes("ZeroValue"));
        vHedge.deposit(endEpoch, 0 ether, alice);
        vm.stopPrank();  
    }

    function testFailTimelocked() public {
        //forge can't compare reverts if the function that is called is not on the same contract as the revert)
        //(can only make internal comparisons)
        //all cases revert TimeLocked()
        vm.startPrank(admin);
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, address(oracleFRAX), "y2kFRAX_99*");
        vm.warp(block.timestamp + 6 days);
        vm.expectRevert(Vault.TimeLocked.selector);
        vaultFactory.changeTreasury(alice, vaultFactory.marketIndex());
        vm.expectRevert(Vault.TimeLocked.selector);
        vaultFactory.changeController(vaultFactory.marketIndex(), alice);
        vm.expectRevert(Vault.TimeLocked.selector);
        vaultFactory.changeTimewindow(vaultFactory.marketIndex(), 1);
        vm.stopPrank();
    }

    /*///////////////////////////////////////////////////////////////
                           REWARDSFACTORY reverts
    //////////////////////////////////////////////////////////////*/

    function testRewardsFactoryAdminMod() public {
        vm.startPrank(admin);
        vaultFactory.createNewMarket(FEE, tokenSTETH, DEPEG_AAA, beginEpoch, endEpoch, oracleFRAX, "y2kSTETH_99*");
        vm.stopPrank();

        //expecting revert
        vm.startPrank(alice);
        vm.expectRevert(RewardsFactory.AddressNotAdmin.selector);
        rewardsFactory.createStakingRewards(SINGLE_MARKET_INDEX, endEpoch, REWARDS_DURATION, REWARD_RATE);
        vm.stopPrank();
    }

    function testRewardsEpochDoesNotExist() public {
        vm.startPrank(admin);
        vaultFactory.createNewMarket(FEE, tokenSTETH, DEPEG_AAA, beginEpoch, endEpoch, oracleFRAX, "y2kSTETH_99*");
        vm.stopPrank();

        //expecting revert
        vm.startPrank(admin);
        vm.expectRevert(RewardsFactory.EpochDoesNotExist.selector);
        rewardsFactory.createStakingRewards(SINGLE_MARKET_INDEX, endEpoch + 2 days, REWARDS_DURATION, REWARD_RATE);
        vm.stopPrank();
    }


     /*//////////////////////////////////////////////////////////////
                           PEGORACLE functions
    //////////////////////////////////////////////////////////////*/

    function testPegOracleSameOracle() public {
        vm.startPrank(admin);
        vm.expectRevert(bytes("Cannot be same Oracle"));
        PegOracle pegOracle = new PegOracle(oracleSTETH, oracleSTETH);
        vm.stopPrank();
    }

    function testPegOracleZeroAddress() public {
        vm.startPrank(admin);
        vm.expectRevert(bytes("oracle1 cannot be the zero address"));
        PegOracle pegOracle = new PegOracle(address(0), oracleSTETH);
        vm.expectRevert(bytes("oracle2 cannot be the zero address"));
        PegOracle pegOracle2 = new PegOracle(oracleSTETH, address(0));
        vm.stopPrank();
    }

    function testPegOracleDifDecimals() public {
        vm.startPrank(admin);
        vm.expectRevert(bytes("Decimals must be the same"));
        PegOracle pegOracle = new PegOracle(btcEthOracle, oracleUSDC);
        vm.stopPrank();
    }

}