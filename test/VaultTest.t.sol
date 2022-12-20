// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Test.sol";
import {Vault} from "../src/Vault.sol";
import {VaultFactory, TimeLock} from "../src/VaultFactory.sol";
import {Controller} from "../src/Controller.sol";
import {VaultHelper} from "./VaultHelper.sol";
import {FakeOracle} from "./oracles/FakeOracle.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";

/// @author nexusflip
/// @author MiguelBits

contract VaultTest is VaultHelper {
    
    /*///////////////////////////////////////////////////////////////
                           REVERT cases
    //////////////////////////////////////////////////////////////*/

    function testFeeMoreThan() public {
        vm.startPrank(admin);
        testVault = new Vault(tokenFRAX, "Frax stable", "FRAX", admin, oracleFRAX, VAULT_STRIKE_PRICE, address(controller));
        vm.expectRevert(abi.encodeWithSelector(Vault.FeeMoreThan150.selector, 151));
        testVault.createAssets(beginEpoch, endEpoch, 151);
        vm.stopPrank();
    }

    function testFeeCannotBeZero() public {
        vm.startPrank(admin);
        testVault = new Vault(tokenFRAX, "Frax stable", "FRAX", admin, oracleFRAX, VAULT_STRIKE_PRICE, address(controller));
        vm.expectRevert(Vault.FeeCannotBe0.selector);
        testVault.createAssets(beginEpoch, endEpoch, 0);
        vm.stopPrank();
    }

    function testVaultMarketEpochDoesNotExist() public {
        vm.startPrank(admin);
        testVault = new Vault(tokenFRAX, "Frax stable", "FRAX", admin, oracleFRAX, VAULT_STRIKE_PRICE, address(controller));
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_99*");
        vm.expectRevert(Vault.MarketEpochDoesNotExist.selector);
        testVault.deposit(endEpoch, 100, alice);
        vm.stopPrank();
    }

    function testEpochEndMustBeAfterBegin() public {
        vm.startPrank(admin);
        testVault = new Vault(tokenFRAX, "Frax stable", "FRAX", admin, oracleFRAX, VAULT_STRIKE_PRICE, address(controller));
        vm.expectRevert(Vault.EpochEndMustBeAfterBegin.selector);
        testVault.createAssets(endEpoch, beginEpoch, FEE);
        vm.stopPrank();    
    }

    function testOwnerDidNotAuthorize() public {
        vm.deal(alice, 10 ether);
        
        vm.startPrank(admin);
        fakeOracle = new FakeOracle(oracleFRAX, STRIKE_PRICE_FAKE_ORACLE);
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, address(fakeOracle), "y2kFRAX_99*");
        vm.stopPrank();

        hedge = vaultFactory.getVaults(1)[0];
        vHedge = Vault(hedge);

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
        testVault = new Vault(tokenFRAX, "Frax stable", "FRAX", admin, oracleFRAX, VAULT_STRIKE_PRICE, address(controller));
        vm.stopPrank();
        
        vm.startPrank(alice);
        vm.expectRevert(abi.encodeWithSelector(Vault.AddressNotFactory.selector, address(alice)));
        testVault.changeTreasury(admin);
        vm.stopPrank(); 
    }

    

    function testVaultAddressNotController() public {
        vm.startPrank(admin);
        testVault = new Vault(tokenFRAX, "Frax stable", "FRAX", admin, oracleFRAX, VAULT_STRIKE_PRICE, address(controller));
        vm.stopPrank();

        vm.startPrank(alice);
        vm.expectRevert(abi.encodeWithSelector(Vault.AddressNotController.selector, address(alice)));
        testVault.endEpoch(endEpoch);
        vm.stopPrank();       
    }

    function testVaultEpochNotFinished() public {
        vm.deal(alice, 10 ether);
        
        vm.startPrank(admin);
        fakeOracle = new FakeOracle(oracleFRAX, STRIKE_PRICE_FAKE_ORACLE);
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, address(fakeOracle), "y2kFRAX_99*");
        vm.stopPrank();

        hedge = vaultFactory.getVaults(1)[0];
        vHedge = Vault(hedge);

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
        fakeOracle = new FakeOracle(oracleFRAX, STRIKE_PRICE_FAKE_ORACLE);
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, address(fakeOracle), "y2kFRAX_99*");
        vm.stopPrank();

        hedge = vaultFactory.getVaults(1)[0];
        vHedge = Vault(hedge);

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
        testVault = new Vault(tokenFRAX, "Frax stable", "FRAX", admin, oracleFRAX, VAULT_STRIKE_PRICE, address(controller));
        testVault.createAssets(beginEpoch, endEpoch, FEE);
        testVault.createAssets(beginEpoch, endEpoch, FEE);
        vm.stopPrank();
    }

     function testFailVaultAddressZero() public {
        //cant use vm.expectRevert because of Forge limitations
        //test is throwing AddressZero as it should
        vm.startPrank(admin);
        new Vault(tokenFRAX, "Frax stable", "FRAX", admin, oracleFRAX, VAULT_STRIKE_PRICE, address(controller));
        vm.stopPrank();

        vm.startPrank(admin);
        vm.warp(endEpoch);
        //vm.expectRevert(Vault.AddressZero.selector);
        vaultFactory.changeTreasury(address(0), vaultFactory.marketIndex());
        vm.stopPrank();

        vm.startPrank(admin);
        //vm.expectRevert(Vault.AddressZero.selector);
        vaultFactory.changeController(vaultFactory.marketIndex(), address(0));
        vm.stopPrank();
     }

    function testFailZeroValue() public {
        vm.deal(alice, 20 ether);
        
        vm.startPrank(admin);
        fakeOracle = new FakeOracle(oracleFRAX, STRIKE_PRICE_FAKE_ORACLE);
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, address(fakeOracle), "y2kFRAX_99*");
        vm.stopPrank();

        hedge = vaultFactory.getVaults(1)[0];
        vHedge = Vault(hedge);

        vm.startPrank(alice);
        ERC20(WETH).approve(hedge, 10 ether);
        //vm.expectRevert(bytes("ZeroValue"));
        vHedge.depositETH{value: 0 ether}(endEpoch, alice);
        
        vm.warp(endEpoch + 1 days);
        //vm.expectRevert(bytes("ZeroValue"));
        vHedge.deposit(endEpoch, 0 ether, alice);
        vm.stopPrank();  
    }

}