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

contract ChainlinkPriceProviderTest is Helper {
    uint256 public arbForkId;
    uint256 public arbGoerliForkId;
    VaultFactoryV2 public factory;
    ChainlinkPriceProvider public chainlinkPriceProvider;
    ChainlinkPriceProviderV2 public chainlinkPriceProviderV2;

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

        vm.selectFork(arbGoerliForkId);
        chainlinkPriceProviderV2 = new ChainlinkPriceProviderV2(
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

    function testChainlinkCreation() public {
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
    }

    ////////////////////////////////////////////////
    //                FUNCTIONS                  //
    ////////////////////////////////////////////////

    function testLatestPriceV1() public {
        int256 price = chainlinkPriceProvider.getLatestPrice();
        assertTrue(price != 0);
    }

    function testConditionMetV1() public {
        (bool condition, int256 price) = chainlinkPriceProvider.conditionMet(
            2 ether
        );
        assertTrue(price != 0);
        assertEq(condition, true);
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
            strike
        );
        assertTrue(price != 0);
        assertEq(condition, true);
    }

    ////////////////////////////////////////////////
    //              REVERT CASES                  //
    ////////////////////////////////////////////////

    function testRevertConstructorInputs() public {
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

    function testRevertSequencerDown() public {
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

    function testRevertGracePeriodNotOver() public {
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

    function testRevertOraclePriceZero() public {
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

    function testRevertRoundIdOutdated() public {
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

    function testRevertOracleTimeOut() public {
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
