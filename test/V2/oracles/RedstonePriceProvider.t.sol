// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Helper} from "../Helper.sol";
import {VaultFactoryV2} from "../../../src/v2/VaultFactoryV2.sol";
import {
    RedstonePriceProvider
} from "../../../src/v2/oracles/RedstonePriceProvider.sol";
import {TimeLock} from "../../../src/v2/TimeLock.sol";
import {
    MockOracleAnswerZero,
    MockOracleRoundOutdated,
    MockOracleTimeOut
} from "./MockOracles.sol";
import {IPriceFeedAdapter} from "./PriceInterfaces.sol";

contract RedstonePriceProviderTest is Helper {
    uint256 public arbForkId;
    VaultFactoryV2 public factory;
    RedstonePriceProvider public redstoneProvider;
    uint256 public marketId = 1;

    ////////////////////////////////////////////////
    //                HELPERS                     //
    ////////////////////////////////////////////////

    function setUp() public {
        arbForkId = vm.createFork(ARBITRUM_RPC_URL);
        vm.selectFork(arbForkId);

        address timelock = address(new TimeLock(ADMIN));
        factory = new VaultFactoryV2(WETH, TREASURY, address(timelock));
        redstoneProvider = new RedstonePriceProvider(
            address(factory),
            VST_PRICE_FEED,
            "VST",
            TIME_OUT
        );

        uint256 condition = 2;
        redstoneProvider.setConditionType(marketId, condition);
    }

    ////////////////////////////////////////////////
    //                STATE                       //
    ////////////////////////////////////////////////

    function testRedStoneCreation() public {
        assertEq(redstoneProvider.timeOut(), TIME_OUT);
        assertEq(address(redstoneProvider.vaultFactory()), address(factory));
        assertEq(address(redstoneProvider.priceFeedAdapter()), VST_PRICE_FEED);
        assertEq(redstoneProvider.dataFeedId(), bytes32("VST"));
        assertEq(
            redstoneProvider.decimals(),
            IPriceFeedAdapter(VST_PRICE_FEED).decimals()
        );
        assertEq(redstoneProvider.description(), "VST");
    }

    ////////////////////////////////////////////////
    //                FUNCTIONS                  //
    ////////////////////////////////////////////////
    function testLatestRoundDataRedstone() public {
        (
            uint80 roundId,
            int256 price,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = redstoneProvider.latestRoundData();
        assertTrue(price != 0);
        assertTrue(roundId == 0);
        assertTrue(startedAt != 0);
        assertTrue(updatedAt != 0);
        assertTrue(answeredInRound == 0);
    }

    function testLatestPriceRedstone() public {
        int256 price = redstoneProvider.getLatestPrice();
        assertTrue(price != 0);
    }

    function testConditionMet() public {
        (bool condition, int256 price) = redstoneProvider.conditionMet(
            2 ether,
            marketId
        );
        assertTrue(price != 0);
        assertEq(condition, true);
    }

    function testStringToBytes() public {
        bytes32 result = redstoneProvider.stringToBytes32("VST");
        assertEq(result, bytes32("VST"));
    }

    ////////////////////////////////////////////////
    //              REVERT CASES                  //
    ////////////////////////////////////////////////

    function testRevertConstructorInputs() public {
        vm.expectRevert(RedstonePriceProvider.ZeroAddress.selector);
        new RedstonePriceProvider(address(0), USDC_CHAINLINK, "USDC", TIME_OUT);

        vm.expectRevert(RedstonePriceProvider.ZeroAddress.selector);
        new RedstonePriceProvider(
            address(factory),
            address(0),
            "USDC",
            TIME_OUT
        );

        vm.expectRevert(RedstonePriceProvider.InvalidInput.selector);
        new RedstonePriceProvider(
            address(factory),
            USDC_CHAINLINK,
            "",
            TIME_OUT
        );

        vm.expectRevert(RedstonePriceProvider.InvalidInput.selector);
        new RedstonePriceProvider(address(factory), USDC_CHAINLINK, "USDC", 0);
    }

    function testRevertOraclePriceZero() public {
        address mockOracle = address(new MockOracleAnswerZero());
        redstoneProvider = new RedstonePriceProvider(
            address(factory),
            mockOracle,
            "USDC",
            TIME_OUT
        );
        vm.expectRevert(RedstonePriceProvider.OraclePriceZero.selector);
        redstoneProvider.getLatestPrice();
    }

    function testRevertRoundOutdated() public {
        address mockOracle = address(new MockOracleRoundOutdated());
        redstoneProvider = new RedstonePriceProvider(
            address(factory),
            mockOracle,
            "USDC",
            TIME_OUT
        );
        vm.expectRevert(RedstonePriceProvider.RoundIdOutdated.selector);
        redstoneProvider.getLatestPrice();
    }

    function testRevertTimeOut() public {
        address mockOracle = address(
            new MockOracleTimeOut(block.timestamp, TIME_OUT)
        );
        redstoneProvider = new RedstonePriceProvider(
            address(factory),
            mockOracle,
            "USDC",
            TIME_OUT
        );
        vm.expectRevert(RedstonePriceProvider.PriceTimedOut.selector);
        redstoneProvider.getLatestPrice();
    }

    function testRevertInvalidInputString() public {
        vm.expectRevert(RedstonePriceProvider.InvalidInput.selector);
        redstoneProvider.stringToBytes32(
            "Long sentence that's very likely to be more than 32 bytes in total"
        );
    }
}
