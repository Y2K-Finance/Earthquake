// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Test.sol";
import {Vault} from "../../src/legacy_v1/Vault.sol";
import {VaultFactory, TimeLock} from "../../src/legacy_v1/VaultFactory.sol";
import {Controller} from "../../src/legacy_v1/Controller.sol";
import {VaultHelper} from "./VaultHelper.sol";
import {FakeOracle} from "../oracles/FakeOracle.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";

/// @author nexusflip
/// @author MiguelBits

contract VaultTest is VaultHelper {
    
    /*///////////////////////////////////////////////////////////////
                           REVERT cases
    //////////////////////////////////////////////////////////////*/

    function testFeeMoreThan() public {
        vm.startPrank(ADMIN);
        testVault = new Vault(TOKEN_FRAX, "Frax stable", "FRAX", ADMIN, ORACLE_FRAX, VAULT_STRIKE_PRICE, address(controller));
        vm.expectRevert(abi.encodeWithSelector(Vault.FeeMoreThan150.selector, 151));
        testVault.createAssets(beginEpoch, endEpoch, 151);
        vm.stopPrank();
    }

    function testFeeCannotBeZero() public {
        vm.startPrank(ADMIN);
        testVault = new Vault(TOKEN_FRAX, "Frax stable", "FRAX", ADMIN, ORACLE_FRAX, VAULT_STRIKE_PRICE, address(controller));
        vm.expectRevert(Vault.FeeCannotBe0.selector);
        testVault.createAssets(beginEpoch, endEpoch, 0);
        vm.stopPrank();
    }

    function testVaultMarketEpochDoesNotExist() public {
        vm.startPrank(ADMIN);
        testVault = new Vault(TOKEN_FRAX, "Frax stable", "FRAX", ADMIN, ORACLE_FRAX, VAULT_STRIKE_PRICE, address(controller));
        vaultFactory.createNewMarket(FEE, TOKEN_FRAX, DEPEG_AAA, beginEpoch, endEpoch, ORACLE_FRAX, "y2kFRAX_99*");
        vm.expectRevert(Vault.MarketEpochDoesNotExist.selector);
        testVault.deposit(endEpoch, 100, ALICE);
        vm.stopPrank();
    }

    function testEpochEndMustBeAfterBegin() public {
        vm.startPrank(ADMIN);
        testVault = new Vault(TOKEN_FRAX, "Frax stable", "FRAX", ADMIN, ORACLE_FRAX, VAULT_STRIKE_PRICE, address(controller));
        vm.expectRevert(Vault.EpochEndMustBeAfterBegin.selector);
        testVault.createAssets(endEpoch, beginEpoch, FEE);
        vm.stopPrank();    
    }

    function testOwnerDidNotAuthorize() public {
        vm.deal(ALICE, 10 ether);
        
        vm.startPrank(ADMIN);
        fakeOracle = new FakeOracle(ORACLE_FRAX, STRIKE_PRICE_FAKE_ORACLE);
        vaultFactory.createNewMarket(FEE, TOKEN_FRAX, DEPEG_AAA, beginEpoch, endEpoch, address(fakeOracle), "y2kFRAX_99*");
        vm.stopPrank();

        hedge = vaultFactory.getVaults(1)[0];
        vHedge = Vault(hedge);

        vm.startPrank(ALICE);
        ERC20(WETH).approve(hedge, 10 ether);
        vHedge.depositETH{value: 10 ether}(endEpoch, ALICE);

        assertTrue(vHedge.balanceOf(ALICE,endEpoch) == (10 ether));
        vm.stopPrank();

        vm.startPrank(BOB);
        vm.warp(endEpoch + 1 days);
        controller.triggerEndEpoch(vaultFactory.marketIndex(), endEpoch);
        vm.expectRevert(abi.encodeWithSelector(Vault.OwnerDidNotAuthorize.selector, address(BOB), address(ALICE)));
        vHedge.withdraw(endEpoch, 10 ether, BOB, ALICE);
        vm.stopPrank();
    }

    function testAddressNotFactory() public {
        vm.startPrank(ADMIN);
        testVault = new Vault(TOKEN_FRAX, "Frax stable", "FRAX", ADMIN, ORACLE_FRAX, VAULT_STRIKE_PRICE, address(controller));
        vm.stopPrank();
        
        vm.startPrank(ALICE);
        vm.expectRevert(abi.encodeWithSelector(Vault.AddressNotFactory.selector, address(ALICE)));
        testVault.changeTreasury(ADMIN);
        vm.stopPrank(); 
    }

    

    function testVaultAddressNotController() public {
        vm.startPrank(ADMIN);
        testVault = new Vault(TOKEN_FRAX, "Frax stable", "FRAX", ADMIN, ORACLE_FRAX, VAULT_STRIKE_PRICE, address(controller));
        vm.stopPrank();

        vm.startPrank(ALICE);
        vm.expectRevert(abi.encodeWithSelector(Vault.AddressNotController.selector, address(ALICE)));
        testVault.endEpoch(endEpoch);
        vm.stopPrank();       
    }

    function testVaultEpochNotFinished() public {
        vm.deal(ALICE, 10 ether);
        
        vm.startPrank(ADMIN);
        fakeOracle = new FakeOracle(ORACLE_FRAX, STRIKE_PRICE_FAKE_ORACLE);
        vaultFactory.createNewMarket(FEE, TOKEN_FRAX, DEPEG_AAA, beginEpoch, endEpoch, address(fakeOracle), "y2kFRAX_99*");
        vm.stopPrank();

        hedge = vaultFactory.getVaults(1)[0];
        vHedge = Vault(hedge);

        vm.startPrank(ALICE);
        ERC20(WETH).approve(hedge, 10 ether);
        vHedge.depositETH{value: 10 ether}(endEpoch, ALICE);

        assertTrue(vHedge.balanceOf(ALICE,endEpoch) == (10 ether));
        vm.stopPrank();

        vm.startPrank(BOB);
        vm.expectRevert(Vault.EpochNotFinished.selector);
        vHedge.withdraw(endEpoch, 10 ether, BOB, ALICE);
        vm.stopPrank();
    }

    function testVaultEpochAlreadyStarted() public {
        vm.deal(ALICE, 20 ether);
        
        vm.startPrank(ADMIN);
        fakeOracle = new FakeOracle(ORACLE_FRAX, STRIKE_PRICE_FAKE_ORACLE);
        vaultFactory.createNewMarket(FEE, TOKEN_FRAX, DEPEG_AAA, beginEpoch, endEpoch, address(fakeOracle), "y2kFRAX_99*");
        vm.stopPrank();

        hedge = vaultFactory.getVaults(1)[0];
        vHedge = Vault(hedge);

        vm.startPrank(ALICE);
        ERC20(WETH).approve(hedge, 10 ether);
        vHedge.depositETH{value: 10 ether}(endEpoch, ALICE);
        vm.warp(beginEpoch + 1 days);
        vm.expectRevert(Vault.EpochAlreadyStarted.selector);
        vHedge.deposit(endEpoch, 10 ether, ALICE);

        assertTrue(vHedge.balanceOf(ALICE,endEpoch) == (10 ether));
        vm.stopPrank();     
    }

    function testFailMarketEpochExists() public {
        vm.startPrank(ADMIN);
        testVault = new Vault(TOKEN_FRAX, "Frax stable", "FRAX", ADMIN, ORACLE_FRAX, VAULT_STRIKE_PRICE, address(controller));
        testVault.createAssets(beginEpoch, endEpoch, FEE);
        testVault.createAssets(beginEpoch, endEpoch, FEE);
        vm.stopPrank();
    }

     function testFailVaultAddressZero() public {
        //cant use vm.expectRevert because of Forge limitations
        //test is throwing AddressZero as it should
        vm.startPrank(ADMIN);
        new Vault(TOKEN_FRAX, "Frax stable", "FRAX", ADMIN, ORACLE_FRAX, VAULT_STRIKE_PRICE, address(controller));
        vm.stopPrank();

        vm.startPrank(ADMIN);
        vm.warp(endEpoch);
        //vm.expectRevert(Vault.AddressZero.selector);
        vaultFactory.changeTreasury(address(0), vaultFactory.marketIndex());
        vm.stopPrank();

        vm.startPrank(ADMIN);
        //vm.expectRevert(Vault.AddressZero.selector);
        vaultFactory.changeController(vaultFactory.marketIndex(), address(0));
        vm.stopPrank();
     }

    function testFailZeroValue() public {
        vm.deal(ALICE, 20 ether);
        
        vm.startPrank(ADMIN);
        fakeOracle = new FakeOracle(ORACLE_FRAX, STRIKE_PRICE_FAKE_ORACLE);
        vaultFactory.createNewMarket(FEE, TOKEN_FRAX, DEPEG_AAA, beginEpoch, endEpoch, address(fakeOracle), "y2kFRAX_99*");
        vm.stopPrank();

        hedge = vaultFactory.getVaults(1)[0];
        vHedge = Vault(hedge);

        vm.startPrank(ALICE);
        ERC20(WETH).approve(hedge, 10 ether);
        //vm.expectRevert(bytes("ZeroValue"));
        vHedge.depositETH{value: 0 ether}(endEpoch, ALICE);
        
        vm.warp(endEpoch + 1 days);
        //vm.expectRevert(bytes("ZeroValue"));
        vHedge.deposit(endEpoch, 0 ether, ALICE);
        vm.stopPrank();  
    }

}