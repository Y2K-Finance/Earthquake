// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Helper} from "../../Helper.sol";
import {VaultFactoryV2} from "../../../../src/v2/VaultFactoryV2.sol";
import {TimeLock} from "../../../../src/v2/TimeLock.sol";
import {
    DIAPriceProvider
} from "../../../../src/v2/oracles/individual/DIAPriceProvider.sol";
import {
    MockOracleAnswerOne,
    MockOracleGracePeriod,
    MockOracleAnswerZero,
    MockOracleRoundOutdated,
    MockOracleTimeOut
} from "../MockOracles.sol";

contract DIAPriceProviderTest is Helper {
    DIAPriceProvider public diaPriceProvider;
    uint256 public arbForkId;
    string public pairName = "BTC/USD";
    uint256 public marketId = 2;

    ////////////////////////////////////////////////
    //                HELPERS                     //
    ////////////////////////////////////////////////
    function setUp() public {
        arbForkId = vm.createFork(ARBITRUM_RPC_URL);
        vm.selectFork(arbForkId);

        diaPriceProvider = new DIAPriceProvider(DIA_ORACLE_V2, DIA_DECIMALS);
        uint256 condition = 2;
    }

    ////////////////////////////////////////////////
    //                STATE                       //
    ////////////////////////////////////////////////
    function testDIACreation() public {
        assertEq(address(diaPriceProvider.diaPriceFeed()), DIA_ORACLE_V2);
        assertEq(diaPriceProvider.decimals(), DIA_DECIMALS);
        assertEq(
            abi.encode(diaPriceProvider.description()),
            abi.encode(pairName)
        );
    }

    ////////////////////////////////////////////////
    //                FUNCTIONS                  //
    ////////////////////////////////////////////////
    function testLatestRoundDataDIA() public {
        (
            uint80 roundId,
            int256 price,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = diaPriceProvider.latestRoundData();
        assertTrue(price != 0);
        assertEq(roundId, 1);
        assertEq(startedAt, 1);
        assertTrue(updatedAt != 0);
        assertEq(answeredInRound, 1);
    }

    function testLatestPrice() public {
        int256 price = diaPriceProvider.getLatestPrice();
        assertTrue(price != 0);
    }

    function testConditionOneMetDIA() public {
        uint256 marketIdOne = 1;
        uint256 strike = 10_000_000_0001; // 10e8 with extra byte as 1

        (bool condition, int256 price) = diaPriceProvider.conditionMet(
            strike,
            marketIdOne
        );
        assertTrue(price != 0);
        assertEq(condition, true);
    }

    function testConditionTwoMetDIA() public {
        uint256 strikePrice = 50_000e8; // 50k with extra byte as 1
        (bool condition, int256 price) = diaPriceProvider.conditionMet(
            strikePrice,
            marketId
        );
        assertTrue(price != 0);
        assertEq(condition, true);
    }

    ////////////////////////////////////////////////
    //              REVERT CASES                  //
    ////////////////////////////////////////////////
    function testRevertConstructorInputs() public {
        vm.expectRevert(DIAPriceProvider.ZeroAddress.selector);
        new DIAPriceProvider(address(0), DIA_DECIMALS);
    }
}
