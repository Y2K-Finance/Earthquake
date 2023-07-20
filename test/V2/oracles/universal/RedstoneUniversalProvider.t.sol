// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Helper} from "../../Helper.sol";
import {VaultFactoryV2} from "../../../../src/v2/VaultFactoryV2.sol";
import {
    RedstoneUniversalProvider
} from "../../../../src/v2/oracles/universal/RedstoneUniversalProvider.sol";
import {TimeLock} from "../../../../src/v2/TimeLock.sol";
import {
    MockOracleAnswerZero,
    MockOracleRoundOutdated,
    MockOracleTimeOut
} from "../MockOracles.sol";
import {IPriceFeedAdapter} from "../PriceInterfaces.sol";

contract RedstoneUniversalProviderTest is Helper {
    uint256 public arbForkId;
    VaultFactoryV2 public factory;
    RedstoneUniversalProvider public redstoneProvider;
    uint256 public marketId = 2;
    uint256 public secondMarketId = 102;
    uint256 public marketIdMock = 999;

    ////////////////////////////////////////////////
    //                HELPERS                     //
    ////////////////////////////////////////////////

    function setUp() public {
        arbForkId = vm.createFork(ARBITRUM_RPC_URL);
        vm.selectFork(arbForkId);

        address timelock = address(new TimeLock(ADMIN));
        factory = new VaultFactoryV2(WETH, TREASURY, address(timelock));
        redstoneProvider = new RedstoneUniversalProvider(
            address(factory),
            TIME_OUT
        );

        uint256 condition = 2;
        redstoneProvider.setConditionType(marketId, condition);
        redstoneProvider.setPriceFeed(marketId, VST_PRICE_FEED);
    }

    ////////////////////////////////////////////////
    //                STATE                       //
    ////////////////////////////////////////////////

    function testRedStoneUniCreation() public {
        assertEq(redstoneProvider.timeOut(), TIME_OUT);
        assertEq(address(redstoneProvider.vaultFactory()), address(factory));

        // First market
        assertEq(
            redstoneProvider.decimals(marketId),
            IPriceFeedAdapter(VST_PRICE_FEED).decimals()
        );
        assertEq(
            redstoneProvider.description(marketId),
            string(
                abi.encodePacked(
                    IPriceFeedAdapter(VST_PRICE_FEED).getDataFeedId()
                )
            )
        );
    }

    ////////////////////////////////////////////////
    //                FUNCTIONS                  //
    ////////////////////////////////////////////////
    function testLatestRoundDataRedUni() public {
        (
            uint80 roundId,
            int256 price,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = redstoneProvider.latestRoundData(marketId);
        assertTrue(price != 0);
        assertTrue(roundId == 0);
        assertTrue(startedAt != 0);
        assertTrue(updatedAt != 0);
        assertTrue(answeredInRound == 0);
    }

    function testLatestPriceRedUni() public {
        int256 price = redstoneProvider.getLatestPrice(marketId);
        assertTrue(price != 0);
    }

    function testConditionOneMetRedUni() public {
        uint256 conditionType = 1;
        uint256 marketIdOne = 1;
        redstoneProvider.setConditionType(marketIdOne, conditionType);
        redstoneProvider.setPriceFeed(marketIdOne, VST_PRICE_FEED);
        (bool condition, int256 price) = redstoneProvider.conditionMet(
            0.01 ether,
            marketIdOne
        );
        assertTrue(price != 0);
        assertEq(condition, true);
    }

    function testConditionTwoMetRedUni() public {
        (bool condition, int256 price) = redstoneProvider.conditionMet(
            2 ether,
            marketId
        );
        assertTrue(price != 0);
        assertEq(condition, true);
    }

    ////////////////////////////////////////////////
    //              REVERT CASES                  //
    ////////////////////////////////////////////////

    function testRevertConstructorInputsRedUni() public {
        vm.expectRevert(RedstoneUniversalProvider.ZeroAddress.selector);
        new RedstoneUniversalProvider(address(0), TIME_OUT);

        vm.expectRevert(RedstoneUniversalProvider.InvalidInput.selector);
        new RedstoneUniversalProvider(address(factory), 0);
    }

    function testRevertConditionTypeSetRedUni() public {
        vm.expectRevert(RedstoneUniversalProvider.ConditionTypeSet.selector);
        redstoneProvider.setConditionType(2, 0);
    }

    function testRevertInvalidInputConditionRedUni() public {
        vm.expectRevert(RedstoneUniversalProvider.InvalidInput.selector);
        redstoneProvider.setConditionType(0, 0);

        vm.expectRevert(RedstoneUniversalProvider.InvalidInput.selector);
        redstoneProvider.setConditionType(0, 3);
    }

    function testRevertFeedSetRedUni() public {
        vm.expectRevert(RedstoneUniversalProvider.FeedAlreadySet.selector);
        redstoneProvider.setPriceFeed(marketId, VST_PRICE_FEED);
    }

    function testRevertInvalidInputFeedRedUni() public {
        vm.expectRevert(RedstoneUniversalProvider.InvalidInput.selector);
        redstoneProvider.setPriceFeed(0, address(0));
    }

    function testRevertZeroAddressRoundDataRedUni() public {
        vm.expectRevert(RedstoneUniversalProvider.ZeroAddress.selector);
        redstoneProvider.latestRoundData(0);
    }

    function testRevertOraclePriceZeroRedUni() public {
        address mockOracle = address(new MockOracleAnswerZero());
        redstoneProvider.setConditionType(marketIdMock, 1);
        redstoneProvider.setPriceFeed(marketIdMock, mockOracle);

        vm.expectRevert(RedstoneUniversalProvider.OraclePriceZero.selector);
        redstoneProvider.getLatestPrice(marketIdMock);
    }

    function testRevertRoundOutdatedRedUni() public {
        address mockOracle = address(new MockOracleRoundOutdated());
        redstoneProvider.setConditionType(marketIdMock, 1);
        redstoneProvider.setPriceFeed(marketIdMock, mockOracle);

        vm.expectRevert(RedstoneUniversalProvider.RoundIdOutdated.selector);
        redstoneProvider.getLatestPrice(marketIdMock);
    }

    function testRevertTimeOutRedUni() public {
        address mockOracle = address(
            new MockOracleTimeOut(block.timestamp, TIME_OUT)
        );
        redstoneProvider.setConditionType(marketIdMock, 1);
        redstoneProvider.setPriceFeed(marketIdMock, mockOracle);

        vm.expectRevert(RedstoneUniversalProvider.PriceTimedOut.selector);
        redstoneProvider.getLatestPrice(marketIdMock);
    }
}
