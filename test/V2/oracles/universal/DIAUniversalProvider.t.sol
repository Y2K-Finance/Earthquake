// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Helper} from "../../Helper.sol";
import {VaultFactoryV2} from "../../../../src/v2/VaultFactoryV2.sol";
import {TimeLock} from "../../../../src/v2/TimeLock.sol";
import {
    DIAUniversalProvider
} from "../../../../src/v2/oracles/universal/DIAUniversalProvider.sol";
import {
    MockOracleAnswerOne,
    MockOracleGracePeriod,
    MockOracleAnswerZero,
    MockOracleRoundOutdated,
    MockOracleTimeOut
} from "../MockOracles.sol";

contract DIAUniversalProviderTest is Helper {
    DIAUniversalProvider public diaPriceProvider;
    uint256 public arbForkId;
    string public pairName = "BTC/USD";
    string public secondPairName = "ETH/USD";
    uint256 public strikePrice = 50_000e8;
    uint256 public secondStrikePrice = 2500e8;
    uint256 public marketId = 2;
    uint256 public secondMarketId = 102;

    ////////////////////////////////////////////////
    //                HELPERS                     //
    ////////////////////////////////////////////////
    function setUp() public {
        arbForkId = vm.createFork(ARBITRUM_RPC_URL);
        vm.selectFork(arbForkId);

        diaPriceProvider = new DIAUniversalProvider(DIA_ORACLE_V2);
        uint256 condition = 2;
        diaPriceProvider.setConditionType(marketId, condition);
        diaPriceProvider.setPriceFeed(marketId, pairName, DIA_DECIMALS);

        diaPriceProvider.setConditionType(secondMarketId, condition);
        diaPriceProvider.setPriceFeed(
            secondMarketId,
            secondPairName,
            DIA_DECIMALS
        );
    }

    ////////////////////////////////////////////////
    //                STATE                       //
    ////////////////////////////////////////////////
    function testDIAUniCreation() public {
        assertEq(address(diaPriceProvider.diaPriceFeed()), DIA_ORACLE_V2);

        // First market
        assertEq(diaPriceProvider.decimals(marketId), DIA_DECIMALS);
        assertEq(
            abi.encode(diaPriceProvider.description(marketId)),
            abi.encode(pairName)
        );
        assertEq(diaPriceProvider.marketIdToConditionType(marketId), 2);

        // Second market
        assertEq(diaPriceProvider.decimals(secondMarketId), DIA_DECIMALS);
        assertEq(
            abi.encode(diaPriceProvider.description(secondMarketId)),
            abi.encode(secondPairName)
        );
        assertEq(diaPriceProvider.marketIdToConditionType(secondMarketId), 2);
    }

    ////////////////////////////////////////////////
    //                FUNCTIONS                  //
    ////////////////////////////////////////////////
    function testLatestRoundDataDIAUni() public {
        // First market
        (
            uint80 roundId,
            int256 price,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = diaPriceProvider.latestRoundData(marketId);
        assertTrue(price != 0);
        assertEq(roundId, 1);
        assertEq(startedAt, 1);
        assertTrue(updatedAt != 0);
        assertEq(answeredInRound, 1);

        // Second market
        (
            uint80 secondRoundId,
            int256 secondPrice,
            uint256 secondStartedAt,
            uint256 secondUpdatedAt,
            uint80 secondAnsweredInRound
        ) = diaPriceProvider.latestRoundData(secondMarketId);
        assertTrue(secondPrice != 0);
        assertEq(secondRoundId, 1);
        assertEq(secondStartedAt, 1);
        assertTrue(secondUpdatedAt != 0);
        assertEq(secondAnsweredInRound, 1);
    }

    function testLatestPriceDIAUni() public {
        // First market
        int256 price = diaPriceProvider.getLatestPrice(marketId);
        assertTrue(price != 0);

        // Second market
        int256 secondPrice = diaPriceProvider.getLatestPrice(secondMarketId);
        assertTrue(secondPrice != 0);
    }

    function testConditionOneMetDIAUni() public {
        uint256 conditionType = 1;

        // First market
        uint256 marketIdOne = 1;
        diaPriceProvider.setConditionType(marketIdOne, conditionType);
        diaPriceProvider.setPriceFeed(marketIdOne, pairName, DIA_DECIMALS);
        (bool condition, int256 price) = diaPriceProvider.conditionMet(
            10e6,
            marketIdOne
        );
        assertTrue(price != 0);
        assertEq(condition, true);

        // Second market
        uint256 secondMarketIdOne = 101;
        diaPriceProvider.setConditionType(secondMarketIdOne, conditionType);
        diaPriceProvider.setPriceFeed(
            secondMarketIdOne,
            secondPairName,
            DIA_DECIMALS
        );
        (bool secondCondition, int256 secondPrice) = diaPriceProvider
            .conditionMet(10e6, secondMarketIdOne);
        assertTrue(secondPrice != 0);
        assertEq(secondCondition, true);
    }

    function testConditionTwoMetDIAUni() public {
        // First market
        (bool condition, int256 price) = diaPriceProvider.conditionMet(
            strikePrice,
            marketId
        );
        assertTrue(price != 0);
        assertEq(condition, true);

        // Second market
        (bool secondCondition, int256 secondPrice) = diaPriceProvider
            .conditionMet(secondStrikePrice, secondMarketId);
        assertTrue(secondPrice != 0);
        assertEq(secondCondition, true);
    }

    ////////////////////////////////////////////////
    //              REVERT CASES                  //
    ////////////////////////////////////////////////
    function testRevertConstructorInputsDIAUni() public {
        vm.expectRevert(DIAUniversalProvider.ZeroAddress.selector);
        new DIAUniversalProvider(address(0));
    }

    function testRevertConditionTypeSetDIAUni() public {
        vm.expectRevert(DIAUniversalProvider.ConditionTypeSet.selector);
        diaPriceProvider.setConditionType(2, 0);
    }

    function testRevertInvalidInputConditionDIAUni() public {
        vm.expectRevert(DIAUniversalProvider.InvalidInput.selector);
        diaPriceProvider.setConditionType(0, 0);

        vm.expectRevert(DIAUniversalProvider.InvalidInput.selector);
        diaPriceProvider.setConditionType(0, 3);
    }

    function testRevertInvalidInputStringFeedDIAUni() public {
        vm.expectRevert(DIAUniversalProvider.InvalidInput.selector);
        diaPriceProvider.setPriceFeed(0, "", 1);
    }

    function testRevertFeedAlreadySetFeedDIAUni() public {
        vm.expectRevert(DIAUniversalProvider.FeedAlreadySet.selector);
        diaPriceProvider.setPriceFeed(marketId, pairName, DIA_DECIMALS);
    }

    function testRevertDescriptionNotSetLatestPriceDIAUni() public {
        vm.expectRevert(DIAUniversalProvider.DescriptionNotSet.selector);
        diaPriceProvider.getLatestPrice(999);
    }

    function testRevertOraclePriceZeroUni() public {
        uint256 mockId = 999;
        string memory mockPairName = "MOCK/USD";
        uint256 condition = 2;

        diaPriceProvider.setConditionType(mockId, condition);
        diaPriceProvider.setPriceFeed(mockId, mockPairName, DIA_DECIMALS);

        vm.expectRevert(DIAUniversalProvider.OraclePriceZero.selector);
        diaPriceProvider.getLatestPrice(mockId);
    }
}
