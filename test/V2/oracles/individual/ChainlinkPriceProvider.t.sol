// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Helper} from "../../Helper.sol";
import {VaultFactoryV2} from "../../../../src/v2/VaultFactoryV2.sol";
import {
    ChainlinkPriceProvider
} from "../../../../src/v2/oracles/individual/ChainlinkPriceProvider.sol";
import {TimeLock} from "../../../../src/v2/TimeLock.sol";
import {
    MockOracleAnswerOne,
    MockOracleGracePeriod,
    MockOracleAnswerZero,
    MockOracleRoundOutdated,
    MockOracleTimeOut
} from "../mocks/MockOracles.sol";
import {IChainlink} from "../PriceInterfaces.sol";

contract ChainlinkPriceProviderTest is Helper {
    uint256 public arbForkId;
    uint256 public arbGoerliForkId;
    VaultFactoryV2 public factory;
    ChainlinkPriceProvider public chainlinkPriceProvider;
    ChainlinkPriceProvider public chainlinkPriceProviderV2;
    uint256 public marketId = 2;

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

        // NOTE: Keeping the vol tests in for now
        vm.selectFork(arbGoerliForkId);
        chainlinkPriceProviderV2 = new ChainlinkPriceProvider(
            ARBITRUM_SEQUENCER_GOERLI,
            address(factory),
            ETH_VOL_CHAINLINK,
            TIME_OUT
        );

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

    function testChainlinkCreationV2() public {
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
    function testLatestRoundDataChainlink() public {
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

    function testLatestPriceChainlink() public {
        int256 price = chainlinkPriceProvider.getLatestPrice();
        assertTrue(price != 0);
    }

    function testConditionOneMetChainlink() public {
        uint256 marketIdOne = 1;
        uint256 strikePrice = 1000000000000001;

        (bool condition, int256 price) = chainlinkPriceProvider.conditionMet(
            strikePrice,
            marketIdOne
        );
        assertTrue(price != 0);
        assertEq(condition, true);
    }

    function testConditionTwoMetChainlink() public {
        uint256 strikePrice = 2 ether;
        (bool condition, int256 price) = chainlinkPriceProvider.conditionMet(
            strikePrice,
            marketId
        );
        assertTrue(price != 0);
        assertEq(condition, true);
    }

    function testConditionModuloChainlink() public {
        uint256 marketIdOne = 1;

        uint256 newStrike = 213455566777700000002; // Last bit is a 0
        (bool condition, int256 price) = chainlinkPriceProvider.conditionMet(
            uint256(newStrike),
            marketIdOne
        );
        assertEq(condition, true);

        newStrike = 102223334448556960000002226; // Last bit is a 0
        (condition, price) = chainlinkPriceProvider.conditionMet(
            uint256(newStrike),
            marketIdOne
        );
        assertEq(condition, true);

        newStrike = 2134438; // Last bit is a 0
        (condition, price) = chainlinkPriceProvider.conditionMet(
            uint256(newStrike),
            marketIdOne
        );
        assertEq(condition, false);

        newStrike = 601882234; // Last bit is a 0
        (condition, price) = chainlinkPriceProvider.conditionMet(
            uint256(newStrike),
            marketIdOne
        );
        assertEq(condition, false);

        newStrike = 376599999919; // Last bit is a 1
        (condition, price) = chainlinkPriceProvider.conditionMet(
            uint256(newStrike),
            marketIdOne
        );
        assertEq(condition, true);

        newStrike = 788561; // Last bit is a 1
        (condition, price) = chainlinkPriceProvider.conditionMet(
            uint256(newStrike),
            marketIdOne
        );
        assertEq(condition, true);

        newStrike = 7888885647778390201112345655; // Last bit is a 1
        (condition, price) = chainlinkPriceProvider.conditionMet(
            uint256(newStrike),
            marketIdOne
        );
        assertEq(condition, false);

        newStrike = 8889949596059547392010293; // Last bit is a 1
        (condition, price) = chainlinkPriceProvider.conditionMet(
            uint256(newStrike),
            marketIdOne
        );
        assertEq(condition, false);
    }

    ////////////////////////////////////////////////
    //              REVERT CASES                  //
    ////////////////////////////////////////////////
    function testRevertConstructorInputsChainlink() public {
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

    function testRevertSequencerDownChainlink() public {
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

    function testRevertGracePeriodNotOverChainlink() public {
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

    function testRevertOraclePriceZeroChainlink() public {
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

    function testRevertRoundIdOutdatedChainlink() public {
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

    function testRevertPriceTimedOutChainlink() public {
        address mockAddress = address(
            new MockOracleTimeOut(block.timestamp, TIME_OUT)
        );
        chainlinkPriceProvider = new ChainlinkPriceProvider(
            ARBITRUM_SEQUENCER,
            address(factory),
            mockAddress,
            TIME_OUT
        );

        vm.expectRevert(ChainlinkPriceProvider.PriceTimedOut.selector);
        chainlinkPriceProvider.getLatestPrice();
    }
}
