// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Test.sol";
import {Vault} from "../src/Vault.sol";
import {VaultFactory, TimeLock} from "../src/VaultFactory.sol";
import {Controller} from "../src/Controller.sol";
import {OracleHelper} from "./OracleHelper.sol";
import {FakeOracle} from "./oracles/FakeOracle.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";
import {PegOracle} from "../src/oracles/PegOracle.sol";
import {FakeFakeOracle} from "../test/oracles/FakeFakeOracle.sol";
import "@chainlink/interfaces/AggregatorV3Interface.sol";

/// @author nexusflip
/// @author MiguelBits

contract OracleTest is OracleHelper {
   /*//////////////////////////////////////////////////////////////
                           ASSERT cases
    //////////////////////////////////////////////////////////////*/

    function testCreatePegOracle() public {
        PegOracle pegOracle = new PegOracle(oracleSTETH, oracleETH);
        assertEq(address(pegOracle.oracle1()), oracleSTETH);
        assertEq(address(pegOracle.oracle2()), oracleETH);
    }

    function testLatestRoundData() public {
        vm.startPrank(admin);
        PegOracle pegOracle = new PegOracle(oracleSTETH, oracleETH);
        pegOracle.latestRoundData();
        vm.stopPrank();

    }

    function testOracle1Price() public {
        vm.startPrank(admin);
        PegOracle pegOracle = new PegOracle(oracleSTETH, oracleETH);
        pegOracle.getOracle1_Price();
        vm.stopPrank();

    }

    function testOracleDecimals() public {
        vm.startPrank(admin);
        PegOracle pegOracle = new PegOracle(oracleSTETH, oracleETH);
        //emit log_named_uint("PegOracle decimals", pegOracle.decimals());
        assertTrue(pegOracle.decimals() == DECIMALS);
        AggregatorV3Interface testOracle1 = AggregatorV3Interface(oracleSTETH);
        AggregatorV3Interface testOracle2 = AggregatorV3Interface(oracleETH);
        assertTrue(testOracle1.decimals() == testOracle2.decimals());
        vm.stopPrank();

        //testing for 7 decimal pair
        vm.startPrank(admin);
        FakeFakeOracle sevenDec = new FakeFakeOracle(oracleMIM, 10000000, 7);
        vaultFactory.createNewMarket(FEE, tokenMIM, DEPEG_CCC, beginEpoch, endEpoch, address(sevenDec), "y2kMIM_99*");
        int256 testPriceOne = controller.getLatestPrice(tokenMIM);
        emit log_named_int("testPrice for 7 decimals ", testPriceOne);
        emit log_named_int("strikePrice              ", DEPEG_CCC);
        assertTrue(testPriceOne > 900000000000000000 && testPriceOne <= 1000000000000000000, "oracle rounding error from 7 decimals"); 
        vm.stopPrank();

        //testing for 8 decimal pair
        vm.startPrank(admin);
        FakeOracle eightDec = new FakeOracle(oracleMIM, 100000000);
        vaultFactory.createNewMarket(FEE, tokenMIM, DEPEG_CCC, beginEpoch, endEpoch, address(eightDec), "y2kMIM_99*");
        testPriceOne = controller.getLatestPrice(tokenMIM);
        emit log_named_int("testPrice for 8 decimals ", testPriceOne);
        emit log_named_int("strikePrice              ", DEPEG_CCC);
        assertTrue(testPriceOne > 900000000000000000 && testPriceOne <= 1000000000000000000, "oracle rounding error from 8 decimals"); 
        vm.stopPrank();

        //testing for 18 decimal pair DEPEG
        vm.startPrank(admin);
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_CCC, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_99*");
        int256 testPriceTwo = controller.getLatestPrice(tokenFRAX);
        emit log_named_int("testPrice for 18 decimals", testPriceTwo);
        emit log_named_int("strike price             ", DEPEG_CCC);
        //asserting between 17 and 19 decimals since most stables will not be exactly pegged to the dollar
        assertTrue(testPriceTwo >= 100000000000000000 && testPriceTwo < 10000000000000000000, "oracle rounding error from 18 decimals DEPEG");    
        vm.stopPrank();
        //testing for 18 decimal pair PEG
        vm.startPrank(admin);
        FakeOracle eighteenDec = new FakeOracle(oracleMIM, 1000000000000000000);
        vaultFactory.createNewMarket(FEE, tokenMIM, DEPEG_CCC, beginEpoch, endEpoch, address(eighteenDec), "y2kMIM_99*");
        testPriceOne = controller.getLatestPrice(tokenMIM);
        emit log_named_int("testPrice for 18 decimals", testPriceOne);
        emit log_named_int("strikePrice              ", DEPEG_CCC);
        assertTrue(testPriceOne > 900000000000000000 && testPriceOne <= 1000000000000000000, "oracle rounding error from 18 decimals PEG"); 
        vm.stopPrank();

        //testing for +18 decimal pairs, 20 decimals
        vm.startPrank(admin);
        FakeFakeOracle plusDecimals = new FakeFakeOracle(oracleUSDC, 100000000000000000000, 20);
        vaultFactory.createNewMarket(FEE, tokenUSDC, DEPEG_CCC, beginEpoch, endEpoch, address(plusDecimals), "y2kDAI_99*");
        int256 testPriceThree = controller.getLatestPrice(tokenUSDC);
        emit log_named_int("testPrice for +18 decimal", testPriceThree);
        emit log_named_int("strike price             ", DEPEG_CCC);
        assertTrue(testPriceThree >= 100000000000000000 && testPriceThree < 10000000000000000000, "oracle rounding error from 20 decimals");
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                           REVERT cases
    //////////////////////////////////////////////////////////////*/

    function testPegOracleSameOracle() public {
        vm.startPrank(admin);
        vm.expectRevert(bytes("Cannot be same Oracle"));
        new PegOracle(oracleSTETH, oracleSTETH);
        vm.stopPrank();
    }

    function testPegOracleZeroAddress() public {
        vm.startPrank(admin);
        vm.expectRevert(bytes("oracle1 cannot be the zero address"));
        new PegOracle(address(0), oracleSTETH);
        vm.expectRevert(bytes("oracle2 cannot be the zero address"));
        new PegOracle(oracleSTETH, address(0));
        vm.stopPrank();
    }

    function testPegOracleDifDecimals() public {
        vm.startPrank(admin);
        vm.expectRevert(bytes("Decimals must be the same"));
        new PegOracle(btcEthOracle, oracleUSDC);
        vm.stopPrank();
    }

}