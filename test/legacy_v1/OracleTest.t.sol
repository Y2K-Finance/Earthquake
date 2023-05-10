// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Test.sol";
import {Vault} from "../../src/legacy_v1/Vault.sol";
import {VaultFactory, TimeLock} from "../../src/legacy_v1/VaultFactory.sol";
import {Controller} from "../../src/legacy_v1/Controller.sol";
import {OracleHelper} from "./OracleHelper.sol";
import {FakeOracle} from "../oracles/FakeOracle.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";
import {PegOracle} from "../../src/oracles/PegOracle.sol";
import {FakeFakeOracle} from "../oracles/FakeFakeOracle.sol";
import "@chainlink/interfaces/AggregatorV3Interface.sol";

/// @author nexusflip
/// @author MiguelBits

contract OracleTest is OracleHelper {
    
   /*//////////////////////////////////////////////////////////////
                           ASSERT cases
    //////////////////////////////////////////////////////////////*/

    function testCreatePegOracle() public {
        pegOracle = new PegOracle(ORACLE_STETH, ORACLE_ETH);
        assertEq(address(pegOracle.oracle1()), ORACLE_STETH);
        assertEq(address(pegOracle.oracle2()), ORACLE_ETH);
    }

    function testLatestRoundData() public {
        vm.startPrank(ADMIN);
        pegOracle = new PegOracle(ORACLE_STETH, ORACLE_ETH);
        pegOracle.latestRoundData();
        vm.stopPrank();

    }

    function testOracle1Price() public {
        vm.startPrank(ADMIN);
        pegOracle = new PegOracle(ORACLE_STETH, ORACLE_ETH);
        pegOracle.getOracle1_Price();
        vm.stopPrank();

    }

    function testOracleDecimals() public {
        vm.startPrank(ADMIN);
        pegOracle = new PegOracle(ORACLE_STETH, ORACLE_ETH);
        //emit log_named_uint("PegOracle decimals", pegOracle.decimals());
        assertTrue(pegOracle.decimals() == DECIMALS);
        testOracle1 = AggregatorV3Interface(ORACLE_STETH);
        testOracle2 = AggregatorV3Interface(ORACLE_ETH);
        assertTrue(testOracle1.decimals() == testOracle2.decimals());
        vm.stopPrank();

        //testing for 7 decimal pair
        vm.startPrank(ADMIN);
        sevenDec = new FakeFakeOracle(ORACLE_MIM, 10000000, 7);
        vaultFactory.createNewMarket(FEE, TOKEN_MIM, DEPEG_CCC, beginEpoch, endEpoch, address(sevenDec), "y2kMIM_99*");
        testPriceOne = controller.getLatestPrice(TOKEN_MIM);
        emit log_named_int("testPrice for 7 decimals ", testPriceOne);
        emit log_named_int("strikePrice              ", DEPEG_CCC);
        assertTrue(testPriceOne > 900000000000000000 && testPriceOne <= 1000000000000000000, "oracle rounding error from 7 decimals"); 
        vm.stopPrank();

        //testing for 8 decimal pair
        vm.startPrank(ADMIN);
        eightDec = new FakeOracle(ORACLE_MIM, 100000000);
        vaultFactory.createNewMarket(FEE, TOKEN_MIM, DEPEG_CCC, beginEpoch, endEpoch, address(eightDec), "y2kMIM_99*");
        testPriceOne = controller.getLatestPrice(TOKEN_MIM);
        emit log_named_int("testPrice for 8 decimals ", testPriceOne);
        emit log_named_int("strikePrice              ", DEPEG_CCC);
        assertTrue(testPriceOne > 900000000000000000 && testPriceOne <= 1000000000000000000, "oracle rounding error from 8 decimals"); 
        vm.stopPrank();

        //testing for 18 decimal pair DEPEG
        vm.startPrank(ADMIN);
        vaultFactory.createNewMarket(FEE, TOKEN_FRAX, DEPEG_CCC, beginEpoch, endEpoch, ORACLE_FRAX, "y2kFRAX_99*");
        testPriceTwo = controller.getLatestPrice(TOKEN_FRAX);
        emit log_named_int("testPrice for 18 decimals", testPriceTwo);
        emit log_named_int("strike price             ", DEPEG_CCC);
        //asserting between 17 and 19 decimals since most stables will not be exactly pegged to the dollar
        assertTrue(testPriceTwo >= 100000000000000000 && testPriceTwo < 10000000000000000000, "oracle rounding error from 18 decimals DEPEG");    
        vm.stopPrank();

        //testing for 18 decimal pair PEG
        vm.startPrank(ADMIN);
        eighteenDec = new FakeOracle(ORACLE_MIM, 1000000000000000000);
        vaultFactory.createNewMarket(FEE, TOKEN_MIM, DEPEG_CCC, beginEpoch, endEpoch, address(eighteenDec), "y2kMIM_99*");
        testPriceOne = controller.getLatestPrice(TOKEN_MIM);
        emit log_named_int("testPrice for 18 decimals", testPriceOne);
        emit log_named_int("strikePrice              ", DEPEG_CCC);
        assertTrue(testPriceOne > 900000000000000000 && testPriceOne <= 1000000000000000000, "oracle rounding error from 18 decimals PEG"); 
        vm.stopPrank();

        //testing for +18 decimal pairs, 20 decimals
        vm.startPrank(ADMIN);
        plusDecimals = new FakeFakeOracle(ORACLE_USDC, 100000000000000000000, 20);
        vaultFactory.createNewMarket(FEE, TOKEN_USDC, DEPEG_CCC, beginEpoch, endEpoch, address(plusDecimals), "y2kDAI_99*");
        testPriceThree = controller.getLatestPrice(TOKEN_USDC);
        emit log_named_int("testPrice for +18 decimal", testPriceThree);
        emit log_named_int("strike price             ", DEPEG_CCC);
        assertTrue(testPriceThree >= 100000000000000000 && testPriceThree < 10000000000000000000, "oracle rounding error from 20 decimals");
        vm.stopPrank();
    }

    function testOraclesCreation() public {
        pegOracle = new PegOracle(ORACLE_STETH, ORACLE_ETH);
        pegOracle2 = new PegOracle(ORACLE_FRAX, ORACLE_FEI);

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
        emit log_named_int("oracle?price?", price);

        vm.startPrank(ADMIN);
        vaultFactory.createNewMarket(FEE, TOKEN_STETH, DEPEG_AAA, beginEpoch, endEpoch, address(pegOracle), "y2kSTETH_99*");
        vm.stopPrank();

        nowPrice = controller.getLatestPrice(TOKEN_STETH);

        emit log_named_int("Controller Price: ", nowPrice);
        emit log_named_int("Token      Price: ", DEPEG_AAA);
        console2.log("Decimals: ", pegOracle.decimals());
    }


    /*//////////////////////////////////////////////////////////////
                           REVERT cases
    //////////////////////////////////////////////////////////////*/

    function testPegOracleSameOracle() public {
        vm.startPrank(ADMIN);
        vm.expectRevert(bytes("Cannot be same Oracle"));
        new PegOracle(ORACLE_STETH, ORACLE_STETH);
        vm.stopPrank();
    }

    function testPegOracleZeroAddress() public {
        vm.startPrank(ADMIN);
        vm.expectRevert(bytes("oracle1 cannot be the zero address"));
        new PegOracle(address(0), ORACLE_STETH);
        vm.expectRevert(bytes("oracle2 cannot be the zero address"));
        new PegOracle(ORACLE_STETH, address(0));
        vm.stopPrank();
    }

    function testPegOracleDifDecimals() public {
        vm.startPrank(ADMIN);
        vm.expectRevert(bytes("Decimals must be the same"));
        new PegOracle(ORACLE_BTC_ETH, ORACLE_USDC);
        vm.stopPrank();
    }

}