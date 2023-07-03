// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Helper} from "../Helper.sol";
import {VaultFactoryV2} from "../../../src/v2/VaultFactoryV2.sol";
import {
    ChainlinkPriceProvider
} from "../../../src/v2/oracles/ChainlinkPriceProvider.sol";
import {
    ChainlinkPriceProviderV2
} from "../../../src/v2/oracles/ChainlinkPriceProviderV2.sol";
import {TimeLock} from "../../../src/v2/TimeLock.sol";
import {
    MockOracleAnswerOne,
    MockOracleGracePeriod,
    MockOracleAnswerZero,
    MockOracleRoundOutdated,
    MockOracleTimeOut
} from "./MockOracles.sol";
import {IChainlink} from "./PriceInterfaces.sol";

contract ChainlinkPriceProviderTest is Helper {
    uint256 public arbForkId;
    uint256 public arbGoerliForkId;
    VaultFactoryV2 public factory;
    ChainlinkPriceProvider public chainlinkPriceProvider;
    ChainlinkPriceProvider public chainlinkPriceProviderV2;
    uint256 public marketId = 1;

    ////////////////////////////////////////////////
    //                HELPERS                     //
    ////////////////////////////////////////////////
    function setUp() public {
        arbForkId = vm.createFork(ARBITRUM_RPC_URL);
        arbGoerliForkId = vm.createFork(ARBITRUM_GOERLI_RPC_URL);
        vm.selectFork(arbForkId);

        address timelock = address(new TimeLock(ADMIN));
        factory = new VaultFactoryV2(WETH, TREASURY, address(timelock));
        chainlinkPriceProvider = new ChainlinkPriceProvider(
            ARBITRUM_SEQUENCER,
            address(factory),
            USDC_CHAINLINK,
            TIME_OUT
        );
        uint256 condition = 2;
        chainlinkPriceProvider.setConditionType(marketId, condition);

        vm.selectFork(arbGoerliForkId);
        chainlinkPriceProviderV2 = new ChainlinkPriceProvider(
            ARBITRUM_SEQUENCER_GOERLI,
            address(factory),
            ETH_VOL_CHAINLINK,
            TIME_OUT
        );
        condition = 1;
        chainlinkPriceProviderV2.setConditionType(marketId, condition);

        vm.selectFork(arbForkId);
    }

    ////////////////////////////////////////////////
    //                STATE                       //
    ////////////////////////////////////////////////

    function testChainlinkCreationV1() public {
        assertEq(chainlinkPriceProvider.timeOut(), TIME_OUT);
        assertEq(
            address(chainlinkPriceProvider.vaultFactory()),
            address(factory)
        );
        assertEq(
            address(chainlinkPriceProvider.sequencerUptimeFeed()),
            ARBITRUM_SEQUENCER
        );
        assertEq(address(chainlinkPriceProvider.priceFeed()), USDC_CHAINLINK);
        assertEq(
            chainlinkPriceProvider.decimals(),
            IChainlink(USDC_CHAINLINK).decimals()
        );
        assertEq(
            chainlinkPriceProvider.description(),
            IChainlink(USDC_CHAINLINK).description()
        );
    }

    function testChainlinkCreation() public {
        vm.selectFork(arbGoerliForkId);
        assertEq(chainlinkPriceProviderV2.timeOut(), TIME_OUT);
        assertEq(
            address(chainlinkPriceProviderV2.vaultFactory()),
            address(factory)
        );
        assertEq(
            address(chainlinkPriceProviderV2.sequencerUptimeFeed()),
            ARBITRUM_SEQUENCER_GOERLI
        );
        assertEq(
            address(chainlinkPriceProviderV2.priceFeed()),
            ETH_VOL_CHAINLINK
        );
        assertEq(
            chainlinkPriceProviderV2.decimals(),
            IChainlink(ETH_VOL_CHAINLINK).decimals()
        );
        assertEq(
            chainlinkPriceProviderV2.description(),
            IChainlink(ETH_VOL_CHAINLINK).description()
        );
    }

    ////////////////////////////////////////////////
    //                FUNCTIONS                  //
    ////////////////////////////////////////////////
    function testLatestRoundDataV1() public {
        (
            uint80 roundId,
            int256 price,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = chainlinkPriceProvider.latestRoundData();
        assertTrue(price != 0);
        assertTrue(roundId != 0);
        assertTrue(startedAt != 0);
        assertTrue(updatedAt != 0);
        assertTrue(answeredInRound != 0);
    }

    function testLatestPriceV1() public {
        int256 price = chainlinkPriceProvider.getLatestPrice();
        assertTrue(price != 0);
    }

    function testConditionMetV1() public {
        (bool condition, int256 price) = chainlinkPriceProvider.conditionMet(
            2 ether,
            marketId
        );
        assertTrue(price != 0);
        assertEq(condition, true);
    }

    function testLatestRoundDataV2() public {
        vm.selectFork(arbGoerliForkId);
        (
            uint80 roundId,
            int256 price,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = chainlinkPriceProviderV2.latestRoundData();
        assertTrue(price != 0);
        assertTrue(roundId != 0);
        assertTrue(startedAt != 0);
        assertTrue(updatedAt != 0);
        assertTrue(answeredInRound != 0);
    }

    function testLatestPriceV2() public {
        vm.selectFork(arbGoerliForkId);
        int256 price = chainlinkPriceProviderV2.getLatestPrice();
        assertTrue(price != 0);
    }

    function testConditionMetV2() public {
        vm.selectFork(arbGoerliForkId);
        uint256 strike = uint256(chainlinkPriceProviderV2.getLatestPrice() - 1);

        (bool condition, int256 price) = chainlinkPriceProviderV2.conditionMet(
            strike,
            marketId
        );
        assertTrue(price != 0);
        assertEq(condition, true);
    }

    ////////////////////////////////////////////////
    //              REVERT CASES                  //
    ////////////////////////////////////////////////

    function testRevertConstructorInputsV1() public {
        vm.expectRevert(ChainlinkPriceProvider.ZeroAddress.selector);
        new ChainlinkPriceProvider(
            address(0),
            address(factory),
            USDC_CHAINLINK,
            TIME_OUT
        );

        vm.expectRevert(ChainlinkPriceProvider.ZeroAddress.selector);
        new ChainlinkPriceProvider(
            ARBITRUM_SEQUENCER,
            address(0),
            USDC_CHAINLINK,
            TIME_OUT
        );

        vm.expectRevert(ChainlinkPriceProvider.ZeroAddress.selector);
        new ChainlinkPriceProvider(
            ARBITRUM_SEQUENCER,
            address(factory),
            address(0),
            TIME_OUT
        );

        vm.expectRevert(ChainlinkPriceProvider.InvalidInput.selector);
        new ChainlinkPriceProvider(
            ARBITRUM_SEQUENCER,
            address(factory),
            USDC_CHAINLINK,
            0
        );
    }

    function testRevertSequencerDownV1() public {
        address mockAddress = address(new MockOracleAnswerOne());
        chainlinkPriceProvider = new ChainlinkPriceProvider(
            mockAddress,
            address(factory),
            USDC_CHAINLINK,
            TIME_OUT
        );
        vm.expectRevert(ChainlinkPriceProvider.SequencerDown.selector);
        chainlinkPriceProvider.getLatestPrice();
    }

    function testRevertGracePeriodNotOverV1() public {
        address mockAddress = address(new MockOracleGracePeriod());
        chainlinkPriceProvider = new ChainlinkPriceProvider(
            mockAddress,
            address(factory),
            USDC_CHAINLINK,
            TIME_OUT
        );
        vm.expectRevert(ChainlinkPriceProvider.GracePeriodNotOver.selector);
        chainlinkPriceProvider.getLatestPrice();
    }

    function testRevertOraclePriceZeroV1() public {
        address mockAddress = address(new MockOracleAnswerZero());
        chainlinkPriceProvider = new ChainlinkPriceProvider(
            ARBITRUM_SEQUENCER,
            address(factory),
            mockAddress,
            TIME_OUT
        );
        vm.expectRevert(ChainlinkPriceProvider.OraclePriceZero.selector);
        chainlinkPriceProvider.getLatestPrice();
    }

    function testRevertRoundIdOutdatedV1() public {
        address mockAddress = address(new MockOracleRoundOutdated());
        chainlinkPriceProvider = new ChainlinkPriceProvider(
            ARBITRUM_SEQUENCER,
            address(factory),
            mockAddress,
            TIME_OUT
        );
        vm.expectRevert(ChainlinkPriceProvider.RoundIdOutdated.selector);
        chainlinkPriceProvider.getLatestPrice();
    }

    function testRevertOracleTimeOutV1() public {
        address mockAddress = address(
            new MockOracleTimeOut(block.timestamp, TIME_OUT)
        );
        chainlinkPriceProvider = new ChainlinkPriceProvider(
            ARBITRUM_SEQUENCER,
            address(factory),
            mockAddress,
            TIME_OUT
        );
    }
}
