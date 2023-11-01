// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Helper} from "../../Helper.sol";
import {VaultFactoryV2} from "../../../../src/v2/VaultFactoryV2.sol";
import {
    RedstonePriceProvider
} from "../../../../src/v2/oracles/individual/RedstonePriceProvider.sol";
import {TimeLock} from "../../../../src/v2/TimeLock.sol";
import {
    MockOracleAnswerZero,
    MockOracleRoundOutdated,
    MockOracleTimeOut
} from "../MockOracles.sol";
import {IPriceFeedAdapter} from "../PriceInterfaces.sol";

contract RedstonePriceProviderTest is Helper {
    uint256 public arbForkId;
    VaultFactoryV2 public factory;
    RedstonePriceProvider public redstoneProvider;
    uint256 public marketId = 2;

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

    function testConditionMetPrice() public {
        uint256 strike = 10001;
        (bool condition, int256 price) = redstoneProvider.conditionMet(
            strike,
            marketId
        );
        assertTrue(price != 0);
        assertEq(condition, true);
    }

    function testConditionOneMetRedstone() public {
        uint256 strike = 10000000000000001; // 0.01 ether with 1 for first byte || 100011100001101111001001101111110000010000000000000001
        uint256 marketIdOne = 1;
        (bool condition, int256 price) = redstoneProvider.conditionMet(
            strike,
            marketIdOne
        );
        assertTrue(price != 0);
        assertEq(condition, true);
    }

    function testConditionTwoMetRedstone() public {
        uint256 strike = 2 ether; // 2000000000000000000 || 1101111000001011011010110011101001110110010000000000000000000
        (bool condition, int256 price) = redstoneProvider.conditionMet(
            strike,
            marketId
        );
        assertTrue(price != 0);
        assertEq(condition, true);
    }

    function testStringToBytes() public {
        bytes32 result = redstoneProvider.stringToBytes32("VST");
        assertEq(result, bytes32("VST"));
    }

    function testConditionModuloRedstone() public {
        uint256 marketIdOne = 1;

        uint256 newStrike = 102938475758493948579595857473838937212; // Last bit is a 0
        (bool condition, int256 price) = redstoneProvider.conditionMet(
            uint256(newStrike),
            marketIdOne
        );
        assertTrue(price != 0);
        assertEq(condition, true);

        newStrike = 456768694934837282929101938900000; // Last bit is a 0
        (condition, price) = redstoneProvider.conditionMet(
            uint256(newStrike),
            marketIdOne
        );
        assertEq(condition, true);

        newStrike = 57890228; // Last bit is a 0
        (condition, price) = redstoneProvider.conditionMet(
            uint256(newStrike),
            marketIdOne
        );
        assertEq(condition, false);

        newStrike = 98293028824; // Last bit is a 0
        (condition, price) = redstoneProvider.conditionMet(
            uint256(newStrike),
            marketIdOne
        );
        assertEq(condition, false);

        newStrike = 76423729; // Last bit is a 1
        (condition, price) = redstoneProvider.conditionMet(
            uint256(newStrike),
            marketIdOne
        );
        assertEq(condition, true);

        newStrike = 238492107; // Last bit is a 1
        (condition, price) = redstoneProvider.conditionMet(
            uint256(newStrike),
            marketIdOne
        );
        assertEq(condition, true);

        newStrike = 69838393845895948594939299227374844939833; // Last bit is a 1
        (condition, price) = redstoneProvider.conditionMet(
            uint256(newStrike),
            marketIdOne
        );
        assertEq(condition, false);

        newStrike = 3334959458499438438922923847584939393839909; // Last bit is a 1
        (condition, price) = redstoneProvider.conditionMet(
            uint256(newStrike),
            marketIdOne
        );
        assertEq(condition, false);
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
