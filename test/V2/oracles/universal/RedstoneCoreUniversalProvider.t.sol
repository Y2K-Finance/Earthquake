// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Helper} from "../../Helper.sol";
import {
    RedstoneCoreUniversalProvider
} from "../../../../src/v2/oracles/universal/RedstoneCoreUniversalProvider.sol";
import "forge-std/Script.sol";

contract MockRedstoneCoreUniversalProvider is RedstoneCoreUniversalProvider {
    constructor(uint256 _timeOut) RedstoneCoreUniversalProvider(_timeOut) {}

    function getUniqueSignersThreshold()
        public
        view
        virtual
        override
        returns (uint8)
    {
        return 1;
    }

    function getAuthorisedSignerIndex(
        address signerAddress
    ) public view virtual override returns (uint8) {
        // authorize everyone
        return 0;
    }

    function validateTimestamp(
        uint256 receivedTimestampMilliseconds
    ) public view override {
        // allow any timestamp
    }
}

// cd ./lib/redstone-oracles-monorepo/packages/protocol && yarn && yarn build
// delete ./lib/redstone-oracles-monorepo/node_modules/@chainlink
// forge test --match-path test/V2/oracles/universal/RedstoneCoreUniversalProviderTest.t.sol -vvvv --ffi
contract RedstoneCoreUniversalProviderTest is Helper {
    uint256 public arbForkId;
    MockRedstoneCoreUniversalProvider public redstoneCoreProvider;
    uint256 public btcMarketId = 2;
    uint256 public ethMarketId = 3;
    uint256 public marketIdMock = 999;
    uint256[] public marketIds;

    bytes32 public btcFeed = "BTC";
    bytes32 public ethFeed = "ETH";

    ////////////////////////////////////////////////
    //                HELPERS                     //
    ////////////////////////////////////////////////

    function setUp() public {
        arbForkId = vm.createFork(ARBITRUM_RPC_URL);
        vm.selectFork(arbForkId);

        redstoneCoreProvider = new MockRedstoneCoreUniversalProvider(TIME_OUT);

        uint256 condition = 2;
        redstoneCoreProvider.setConditionType(btcMarketId, condition);
        redstoneCoreProvider.setConditionType(ethMarketId, condition);
        redstoneCoreProvider.setPriceFeed(btcMarketId, btcFeed, 8);
        redstoneCoreProvider.setPriceFeed(ethMarketId, ethFeed, 8);

        marketIds.push(btcMarketId);
        marketIds.push(ethMarketId);
    }

    function getRedstonePayload(
        // dataFeedId:value:decimals
        string memory priceFeed
    ) public returns (bytes memory) {
        string[] memory args = new string[](3);
        args[0] = "node";
        args[1] = "getRedstonePayload.js";
        args[2] = priceFeed;

        return vm.ffi(args);
    }

    function updatePrice(
        string memory payload,
        uint256[] memory _marketIds
    ) public {
        bytes memory redstonePayload = getRedstonePayload(payload);

        bytes memory encodedFunction = abi.encodeWithSignature(
            "updatePrices(uint256[])",
            _marketIds
        );
        bytes memory encodedFunctionWithRedstonePayload = abi.encodePacked(
            encodedFunction,
            redstonePayload
        );

        // Securely getting oracle value
        (bool success, ) = address(redstoneCoreProvider).call(
            encodedFunctionWithRedstonePayload
        );
        assertEq(success, true);

        // settle the timestamp due to the difference between vm and js node
        vm.warp(block.timestamp + 3600);
    }

    ////////////////////////////////////////////////
    //                STATE                       //
    ////////////////////////////////////////////////

    function testRedStoneUniCreation() public {
        assertEq(redstoneCoreProvider.timeOut(), TIME_OUT);

        // First market
        assertEq(redstoneCoreProvider.decimals(btcMarketId), 8);
    }

    ////////////////////////////////////////////////
    //                FUNCTIONS                  //
    ////////////////////////////////////////////////
    function testLatestRoundDataRedUni() public {
        updatePrice("BTC:270:8,ETH:16:8", marketIds);
        (
            uint80 roundId,
            int256 price,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = redstoneCoreProvider.latestRoundData(btcMarketId);
        assertTrue(price != 0);
        assertTrue(roundId == 0);
        assertTrue(startedAt == 0);
        assertTrue(updatedAt != 0);
        assertTrue(answeredInRound == 0);
    }

    function testLatestPriceRedUni() public {
        updatePrice("BTC:270:8,ETH:16:8", marketIds);

        (, int256 btcRoundPrice, , , ) = redstoneCoreProvider.latestRoundData(
            btcMarketId
        );
        assertEq(btcRoundPrice, 270 * 10 ** 8);

        int256 btcPrice = redstoneCoreProvider.getLatestPrice(btcMarketId);
        assertEq(btcPrice, 270 * 10 ** 18);

        (, int256 ethRoundPrice, , , ) = redstoneCoreProvider.latestRoundData(
            ethMarketId
        );
        assertEq(ethRoundPrice, 16 * 10 ** 8);

        int256 ethPrice = redstoneCoreProvider.getLatestPrice(ethMarketId);
        assertEq(ethPrice, 16 * 10 ** 18);
    }

    function testConditionOneMetRedUni() public {
        uint256 conditionType = 1;
        uint256 marketIdOne = 1;
        redstoneCoreProvider.setConditionType(marketIdOne, conditionType);
        redstoneCoreProvider.setPriceFeed(marketIdOne, bytes32("ETH"), 8);

        uint256[] memory _marketIds = new uint256[](1);
        _marketIds[0] = marketIdOne;
        updatePrice("BTC:270:8,ETH:16:8", _marketIds);

        (bool condition, int256 price) = redstoneCoreProvider.conditionMet(
            0.01 ether,
            marketIdOne
        );
        assertTrue(price != 0);
        assertEq(condition, true);
    }

    function testConditionTwoMetRedUni() public {
        updatePrice("BTC:270:8,ETH:16:8", marketIds);
        (bool condition, int256 price) = redstoneCoreProvider.conditionMet(
            20 ether,
            ethMarketId
        );
        assertTrue(price != 0);
        assertEq(condition, true);
    }

    ////////////////////////////////////////////////
    //              REVERT CASES                  //
    ////////////////////////////////////////////////

    function testRevertConstructorInputsRedUni() public {
        vm.expectRevert(RedstoneCoreUniversalProvider.InvalidInput.selector);
        new MockRedstoneCoreUniversalProvider(0);
    }

    function testRevertConditionTypeSetRedUni() public {
        vm.expectRevert(
            RedstoneCoreUniversalProvider.ConditionTypeSet.selector
        );
        redstoneCoreProvider.setConditionType(2, 0);
    }

    function testRevertInvalidInputConditionRedUni() public {
        vm.expectRevert(RedstoneCoreUniversalProvider.InvalidInput.selector);
        redstoneCoreProvider.setConditionType(0, 0);

        vm.expectRevert(RedstoneCoreUniversalProvider.InvalidInput.selector);
        redstoneCoreProvider.setConditionType(0, 3);
    }

    function testRevertInvalidInputFeedRedUni() public {
        vm.expectRevert(RedstoneCoreUniversalProvider.InvalidInput.selector);
        redstoneCoreProvider.setPriceFeed(0, bytes32(0), 8);
    }

    function testRevertOraclePriceZeroRedUni() public {
        redstoneCoreProvider.setConditionType(marketIdMock, 1);
        redstoneCoreProvider.setPriceFeed(marketIdMock, ethFeed, 8);

        vm.expectRevert(RedstoneCoreUniversalProvider.OraclePriceZero.selector);
        redstoneCoreProvider.getLatestPrice(marketIdMock);
    }

    function testRevertTimeOutRedUni() public {
        redstoneCoreProvider.setConditionType(marketIdMock, 1);
        redstoneCoreProvider.setPriceFeed(marketIdMock, ethFeed, 8);

        uint256[] memory _marketIds = new uint256[](1);
        _marketIds[0] = marketIdMock;
        updatePrice("ETH:16:8", _marketIds);

        vm.warp(block.timestamp + 86401);

        vm.expectRevert(RedstoneCoreUniversalProvider.PriceTimedOut.selector);
        redstoneCoreProvider.getLatestPrice(marketIdMock);
    }
}
