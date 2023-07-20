// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Helper} from "../../Helper.sol";
import {VaultFactoryV2} from "../../../../src/v2/VaultFactoryV2.sol";
import {
    ChainlinkUniversalProvider
} from "../../../../src/v2/oracles/universal/ChainlinkUniversalProvider.sol";
import {TimeLock} from "../../../../src/v2/TimeLock.sol";
import {
    MockOracleAnswerOne,
    MockOracleGracePeriod,
    MockOracleAnswerZero,
    MockOracleRoundOutdated,
    MockOracleTimeOut
} from "../MockOracles.sol";
import {IChainlinkUniversal} from "../PriceInterfaces.sol";

contract ChainlinkUniversalProviderTest is Helper {
    uint256 public arbForkId;
    VaultFactoryV2 public factory;
    ChainlinkUniversalProvider public chainlinkPriceProvider;
    uint256 public marketId = 2;
    uint256 public marketIdBtc = 102;
    uint256 marketIdMock = 999;

    ////////////////////////////////////////////////
    //                HELPERS                     //
    ////////////////////////////////////////////////
    function setUp() public {
        arbForkId = vm.createFork(ARBITRUM_RPC_URL);
        vm.selectFork(arbForkId);

        address timelock = address(new TimeLock(ADMIN));
        factory = new VaultFactoryV2(WETH, TREASURY, address(timelock));
        chainlinkPriceProvider = new ChainlinkUniversalProvider(
            ARBITRUM_SEQUENCER,
            address(factory),
            TIME_OUT
        );
        uint256 condition = 2;

        // Setting USDC
        chainlinkPriceProvider.setConditionType(marketId, condition);
        chainlinkPriceProvider.setPriceFeed(marketId, USDC_CHAINLINK);

        // Setting BTC
        chainlinkPriceProvider.setConditionType(marketIdBtc, condition);
        chainlinkPriceProvider.setPriceFeed(marketIdBtc, BTC_CHAINLINK);
    }

    ////////////////////////////////////////////////
    //                STATE                       //
    ////////////////////////////////////////////////

    function testChainlinkUniCreation() public {
        assertEq(chainlinkPriceProvider.timeOut(), TIME_OUT);
        assertEq(
            address(chainlinkPriceProvider.vaultFactory()),
            address(factory)
        );
        assertEq(
            address(chainlinkPriceProvider.sequencerUptimeFeed()),
            ARBITRUM_SEQUENCER
        );

        // First market
        assertEq(
            chainlinkPriceProvider.decimals(marketId),
            IChainlinkUniversal(USDC_CHAINLINK).decimals()
        );
        assertEq(
            chainlinkPriceProvider.description(marketId),
            IChainlinkUniversal(USDC_CHAINLINK).description()
        );

        // Second market
        assertEq(
            chainlinkPriceProvider.decimals(marketIdBtc),
            IChainlinkUniversal(BTC_CHAINLINK).decimals()
        );
        assertEq(
            chainlinkPriceProvider.description(marketIdBtc),
            IChainlinkUniversal(BTC_CHAINLINK).description()
        );
    }

    ////////////////////////////////////////////////
    //                FUNCTIONS                  //
    ////////////////////////////////////////////////
    function testLatestRoundDataChainlink() public {
        // First market
        (
            uint80 roundId,
            int256 price,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = chainlinkPriceProvider.latestRoundData(marketId);
        assertTrue(price != 0);
        assertTrue(roundId != 0);
        assertTrue(startedAt != 0);
        assertTrue(updatedAt != 0);
        assertTrue(answeredInRound != 0);

        // Second market
        (
            uint80 roundIdBtc,
            int256 priceBtc,
            uint256 startedAtBtc,
            uint256 updatedAtBtc,
            uint80 answeredInRoundBtc
        ) = chainlinkPriceProvider.latestRoundData(marketIdBtc);
        assertTrue(priceBtc != 0);
        assertTrue(roundIdBtc != 0);
        assertTrue(startedAtBtc != 0);
        assertTrue(updatedAtBtc != 0);
        assertTrue(answeredInRoundBtc != 0);
    }

    function testLatestPriceChainlinkUni() public {
        // First market
        int256 price = chainlinkPriceProvider.getLatestPrice(marketId);
        assertTrue(price != 0);

        // Second market
        int256 priceBtc = chainlinkPriceProvider.getLatestPrice(marketIdBtc);
        assertTrue(priceBtc != 0);
    }

    function testConditionOneMetChainlinkUni() public {
        uint256 conditionType = 1;

        // First market
        uint256 marketIdOne = 1;
        chainlinkPriceProvider.setConditionType(marketIdOne, conditionType);
        chainlinkPriceProvider.setPriceFeed(marketIdOne, USDC_CHAINLINK);
        (bool condition, int256 price) = chainlinkPriceProvider.conditionMet(
            0.001 ether,
            marketIdOne
        );
        assertTrue(price != 0);
        assertEq(condition, true);

        // Second market
        uint256 marketIdOneBtc = 101;
        chainlinkPriceProvider.setConditionType(marketIdOneBtc, conditionType);
        chainlinkPriceProvider.setPriceFeed(marketIdOneBtc, BTC_CHAINLINK);
        (bool conditionBtc, int256 priceBtc) = chainlinkPriceProvider
            .conditionMet(10000e18, marketIdOneBtc);
        assertTrue(priceBtc != 0);
        assertEq(conditionBtc, true);
    }

    function testConditionTwoMetChainlinkUni() public {
        // First market
        (bool condition, int256 price) = chainlinkPriceProvider.conditionMet(
            2 ether,
            marketId
        );
        assertTrue(price != 0);
        assertEq(condition, true);

        // Second market
        (bool conditionBtc, int256 priceBtc) = chainlinkPriceProvider
            .conditionMet(50000e18, marketIdBtc);
        assertTrue(priceBtc != 0);
        assertEq(conditionBtc, true);
    }

    ////////////////////////////////////////////////
    //              REVERT CASES                  //
    ////////////////////////////////////////////////
    function testRevertConstructorInputsChainlink() public {
        vm.expectRevert(ChainlinkUniversalProvider.ZeroAddress.selector);
        new ChainlinkUniversalProvider(address(0), address(factory), TIME_OUT);

        vm.expectRevert(ChainlinkUniversalProvider.ZeroAddress.selector);
        new ChainlinkUniversalProvider(
            ARBITRUM_SEQUENCER,
            address(0),
            TIME_OUT
        );

        vm.expectRevert(ChainlinkUniversalProvider.InvalidInput.selector);
        new ChainlinkUniversalProvider(ARBITRUM_SEQUENCER, address(factory), 0);
    }

    function testRevertConditionTypeSetChainlinkUni() public {
        vm.expectRevert(ChainlinkUniversalProvider.ConditionTypeSet.selector);
        chainlinkPriceProvider.setConditionType(2, 0);
    }

    function testRevertInvalidInputConditionChainlinkUni() public {
        vm.expectRevert(ChainlinkUniversalProvider.InvalidInput.selector);
        chainlinkPriceProvider.setConditionType(0, 0);
    }

    function testRevertZeroAddressSetFeedChainlinkUni() public {
        vm.expectRevert(ChainlinkUniversalProvider.ZeroAddress.selector);
        chainlinkPriceProvider.setPriceFeed(999, address(0));
    }

    function testRevertSequencerDownChainlinkUni() public {
        address mockAddress = address(new MockOracleAnswerOne());

        chainlinkPriceProvider = new ChainlinkUniversalProvider(
            mockAddress,
            address(factory),
            TIME_OUT
        );
        vm.expectRevert(ChainlinkUniversalProvider.SequencerDown.selector);
        chainlinkPriceProvider.getLatestPrice(marketIdMock);
    }

    function testRevertGracePeriodNotOverChainlinkUni() public {
        address mockAddress = address(new MockOracleGracePeriod());
        chainlinkPriceProvider = new ChainlinkUniversalProvider(
            mockAddress,
            address(factory),
            TIME_OUT
        );
        vm.expectRevert(ChainlinkUniversalProvider.GracePeriodNotOver.selector);
        chainlinkPriceProvider.getLatestPrice(marketIdMock);
    }

    function testRevertOracleZeroAddrChainlinkUni() public {
        chainlinkPriceProvider.setConditionType(marketIdMock, 2);

        vm.expectRevert(ChainlinkUniversalProvider.ZeroAddress.selector);
        chainlinkPriceProvider.getLatestPrice(marketIdMock);
    }

    function testRevertOraclePriceZeroChainlinkUni() public {
        address mockAddress = address(new MockOracleAnswerZero());

        chainlinkPriceProvider.setConditionType(marketIdMock, 2);
        chainlinkPriceProvider.setPriceFeed(marketIdMock, mockAddress);

        vm.expectRevert(ChainlinkUniversalProvider.OraclePriceZero.selector);
        chainlinkPriceProvider.getLatestPrice(marketIdMock);
    }

    function testRevertRoundIdOutdatedChainlinkUni() public {
        address mockAddress = address(new MockOracleRoundOutdated());

        chainlinkPriceProvider.setConditionType(marketIdMock, 2);
        chainlinkPriceProvider.setPriceFeed(marketIdMock, mockAddress);

        vm.expectRevert(ChainlinkUniversalProvider.RoundIdOutdated.selector);
        chainlinkPriceProvider.getLatestPrice(marketIdMock);
    }

    function testRevertOracleTimeOutChainlinkUni() public {
        address mockAddress = address(
            new MockOracleTimeOut(block.timestamp, TIME_OUT)
        );

        chainlinkPriceProvider.setConditionType(marketIdMock, 2);
        chainlinkPriceProvider.setPriceFeed(marketIdMock, mockAddress);

        vm.expectRevert(ChainlinkUniversalProvider.PriceTimedOut.selector);
        chainlinkPriceProvider.getLatestPrice(marketIdMock);
    }
}
