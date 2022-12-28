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

    function testAllMarketsCreation() public {
        vm.startPrank(admin);

        // Create FRAX market
        //index 1
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_99*");
        //index 2
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_BBB, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_97*");
        //index 3
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_CCC, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_95*");

        // Create MIM market
        //index 4
        vaultFactory.createNewMarket(FEE, tokenMIM, DEPEG_AAA, beginEpoch, endEpoch, oracleMIM, "y2kMIM_99*");
        //index 5
        vaultFactory.createNewMarket(FEE, tokenMIM, DEPEG_BBB, beginEpoch, endEpoch, oracleMIM, "y2kMIM_97*");
        //index 6
        vaultFactory.createNewMarket(FEE, tokenMIM, DEPEG_CCC, beginEpoch, endEpoch, oracleMIM, "y2kMIM_95*");

        // Create FEI market
        //index 7
        vaultFactory.createNewMarket(FEE, tokenFEI, DEPEG_AAA, beginEpoch, endEpoch, oracleFEI, "y2kFEI_99*");
        //index 8
        vaultFactory.createNewMarket(FEE, tokenFEI, DEPEG_BBB, beginEpoch, endEpoch, oracleFEI, "y2kFEI_97*");
        //index 9
        vaultFactory.createNewMarket(FEE, tokenFEI, DEPEG_CCC, beginEpoch, endEpoch, oracleFEI, "y2kFEI_95*");

        // Create USDC market
        //index 10
        vaultFactory.createNewMarket(FEE, tokenUSDC, DEPEG_AAA, beginEpoch, endEpoch, oracleUSDC, "y2kUSDC_99*");
        //index 11
        vaultFactory.createNewMarket(FEE, tokenUSDC, DEPEG_BBB, beginEpoch, endEpoch, oracleUSDC, "y2kUSDC_97*");
        //index 12
        vaultFactory.createNewMarket(FEE, tokenUSDC, DEPEG_CCC, beginEpoch, endEpoch, oracleUSDC, "y2kUSDC_95*");

        // Create DAI market
        //index 13
        vaultFactory.createNewMarket(FEE, tokenDAI, DEPEG_AAA, beginEpoch, endEpoch, oracleDAI, "y2kDAI_99*");
        //index 14
        vaultFactory.createNewMarket(FEE, tokenDAI, DEPEG_BBB, beginEpoch, endEpoch, oracleDAI, "y2kDAI_97*");
        //index 15
        vaultFactory.createNewMarket(FEE, tokenDAI, DEPEG_CCC, beginEpoch, endEpoch, oracleDAI, "y2kDAI_95*");
        
        vm.stopPrank();
    }

    function testAllMarketsDeployMore() public {

        testAllMarketsCreation();

        vm.startPrank(admin);

        // Deploy more FRAX market
        vaultFactory.deployMoreAssets(SINGLE_MARKET_INDEX, beginEpoch + END_DAYS, endEpoch + END_DAYS, FEE);
        vaultFactory.deployMoreAssets(2, beginEpoch + END_DAYS, endEpoch + END_DAYS, FEE);
        vaultFactory.deployMoreAssets(3, beginEpoch + END_DAYS, endEpoch + END_DAYS, FEE);

        // Deploy more MIM market
        vaultFactory.deployMoreAssets(4, beginEpoch + END_DAYS, endEpoch + END_DAYS, FEE);
        vaultFactory.deployMoreAssets(5, beginEpoch + END_DAYS, endEpoch + END_DAYS, FEE);
        vaultFactory.deployMoreAssets(6, beginEpoch + END_DAYS, endEpoch + END_DAYS, FEE);

        // Deploy more FEI market
        vaultFactory.deployMoreAssets(7, beginEpoch + END_DAYS, endEpoch + END_DAYS, FEE);
        vaultFactory.deployMoreAssets(8, beginEpoch + END_DAYS, endEpoch + END_DAYS, FEE);
        vaultFactory.deployMoreAssets(9, beginEpoch + END_DAYS, endEpoch + END_DAYS, FEE);

        // Deploy more USDC market
        vaultFactory.deployMoreAssets(10, beginEpoch + END_DAYS, endEpoch + END_DAYS, FEE);
        vaultFactory.deployMoreAssets(11, beginEpoch + END_DAYS, endEpoch + END_DAYS, FEE);
        vaultFactory.deployMoreAssets(12, beginEpoch + END_DAYS, endEpoch + END_DAYS, FEE);

        // Deploy more DAI market
        vaultFactory.deployMoreAssets(13, beginEpoch + END_DAYS, endEpoch + END_DAYS, FEE);
        vaultFactory.deployMoreAssets(14, beginEpoch + END_DAYS, endEpoch + END_DAYS, FEE);
        vaultFactory.deployMoreAssets(ALL_MARKETS_INDEX, beginEpoch + END_DAYS, endEpoch + END_DAYS, FEE);

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

    /*///////////////////////////////////////////////////////////////
                           FUZZ cases
    //////////////////////////////////////////////////////////////*/
    
    function testFuzzVaultFactoryMarketCreation(uint256 index) public {
        vm.assume(index >= SINGLE_MARKET_INDEX && index <= ALL_MARKETS_INDEX);
        vm.startPrank(admin);
        FakeOracle fakeOracle = new FakeOracle(oracleFRAX, 90995265);
        for (uint256 i = 1; i <= index; i++){
            vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, address(fakeOracle), "y2kFRAX_99*");
        }
        assertEq(vaultFactory.marketIndex(), index);
        vm.stopPrank();
    }
}