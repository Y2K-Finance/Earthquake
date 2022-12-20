// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Test.sol";
import {Vault} from "../src/Vault.sol";
import {VaultFactory} from "../src/VaultFactory.sol";
import {Controller} from "../src/Controller.sol";
import {VaultFactoryHelper} from "./VaultFactoryHelper.sol";
import {FakeOracle} from "./oracles/FakeOracle.sol";

/// @author nexusflip
/// @author MiguelBits

contract VaultFactoryTest is VaultFactoryHelper {
    /*///////////////////////////////////////////////////////////////
                           ASSERT cases
    //////////////////////////////////////////////////////////////*/
    
    function testCreateVaultFactory() public {
        vm.startPrank(admin);
        testFactory = new VaultFactory(address(controller), address(tokenFRAX), admin);
        assertEq(address(controller), testFactory.treasury());
        assertEq(address(tokenFRAX), testFactory.WETH());
        assertEq(address(admin), testFactory.owner());
        vm.stopPrank();
    }

    function testTimelocks() public {
        vm.startPrank(admin);
        
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_99*");
        
        timestamper = block.timestamp + timelocker.MIN_DELAY() + 1;
        index = 1;
        newValue = address(1);
        tokenValue = tokenUSDC;
        factory = address(vaultFactory);
        address[] memory vaults = vaultFactory.getVaults(1);

        // test queue treasury
        timelocker.queue(factory,"changeTreasury",index,0,newValue,address(0), timestamper);
        // test change controller
        timelocker.queue(factory,"changeController",index,0,newValue,address(0), timestamper);
        // test change oracle
        timelocker.queue(factory,"changeOracle",0,0,newValue,tokenValue, timestamper);


        vm.warp(timestamper + 1);

        // test execute treasury
        timelocker.execute(factory,"changeTreasury",index,0,newValue,address(0), timestamper);
        assertTrue(Vault(vaults[0]).treasury() == newValue);
        assertTrue(Vault(vaults[1]).treasury() == newValue);

        // test execute controller
        timelocker.execute(factory,"changeController",index,0,newValue,address(0), timestamper);
        assertTrue(Vault(vaults[0]).controller() == newValue);
        assertTrue(Vault(vaults[1]).controller() == newValue);

        // test execute oracle
        timelocker.execute(factory,"changeOracle",0,0,newValue,tokenValue, timestamper);
        assertTrue(vaultFactory.tokenToOracle(tokenValue) == newValue);

        vm.stopPrank();
    }

    /*///////////////////////////////////////////////////////////////
                           REVERT cases
    //////////////////////////////////////////////////////////////*/

    function testMarketDoesNotExist() public {
        //create fake oracle for price feed
        vm.startPrank(admin);
        fakeOracle = new FakeOracle(oracleFRAX, STRIKE_PRICE_FAKE_ORACLE);
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
        vm.expectRevert(VaultFactory.AddressZero.selector);
        testFactory.setController(address(0));
        vm.stopPrank();
        
        //expect null treasury address
        vm.startPrank(admin);
        vm.expectRevert(VaultFactory.AddressZero.selector);
        testFactory = new VaultFactory(address(0), address(tokenFRAX), admin);
        vm.stopPrank();

        //expect null WETH address
        vm.startPrank(admin);
        vm.expectRevert(VaultFactory.AddressZero.selector);
        testFactory = new VaultFactory(address(controller), address(0), admin);
        vm.stopPrank();
    }

    function testFailAddressNotAdmin() public {
        vm.prank(admin);
        vm.startPrank(alice);
        //vm.expectRevert(abi.encodeWithSelector(VaultFactory.AddressNotAdmin.selector, address(alice)));
        testFactory.setController(address(controller));
        vm.stopPrank();         
    }

    function testAddressFactoryNotInController() public {
        vm.startPrank(admin);
        testFactory.setController(address(controller));
        vm.expectRevert(VaultFactory.AddressFactoryNotInController.selector);
        testFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_99*");
        vm.stopPrank();
    }

    function testControllerNotSet() public {
        vm.startPrank(admin);
        vm.expectRevert(VaultFactory.ControllerNotSet.selector);
        testFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_99*");
        vm.stopPrank();
    }
}