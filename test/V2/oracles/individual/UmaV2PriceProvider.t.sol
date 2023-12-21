// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Helper} from "../../Helper.sol";
import {
    UmaV2PriceProvider
} from "../../../../src/v2/oracles/individual/UmaV2PriceProvider.sol";
import {TimeLock} from "../../../../src/v2/TimeLock.sol";
import {
    MockOracleAnswerOne,
    MockOracleGracePeriod,
    MockOracleAnswerZero,
    MockOracleRoundOutdated,
    MockOracleTimeOut,
    MockUmaV2,
    MockUmaFinder
} from "../mocks/MockOracles.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// The configuration information for TOKEN_PRICE query: https://github.com/UMAprotocol/UMIPs/blob/master/UMIPs/umip-121.md
// Price feeds to use in config: https://github.com/UMAprotocol/protocol/tree/master/packages/financial-templates-lib/src/price-feed
// Uma address all networks: https://docs.uma.xyz/resources/network-addresses
// Uma addresses on Arbitrum: https://github.com/UMAprotocol/protocol/blob/master/packages/core/networks/42161.json

contract UmaV2PriceProviderTest is Helper {
    uint256 public arbForkId;
    UmaV2PriceProvider public umaV2PriceProvider;
    uint256 public marketId = 2;

    ////////////////////////////////////////////////
    //                HELPERS                     //
    ////////////////////////////////////////////////
    address public constant UMAV2_FINDER =
        0xB0b9f73B424AD8dc58156C2AE0D7A1115D1EcCd1;
    address public umaV2 = 0x88Ad27C41AD06f01153E7Cd9b10cBEdF4616f4d5;
    uint256 public umaDecimals;
    string public umaDescription;
    address public umaCurrency;
    string public ancillaryData;
    uint256 public reward;

    function setUp() public {
        arbForkId = vm.createFork(ARBITRUM_RPC_URL);
        vm.selectFork(arbForkId);

        umaDecimals = 8;
        umaDescription = "FUSD/USD";
        umaCurrency = USDC_TOKEN;
        ancillaryData = 'base:FUSD,baseAddress:0x630410530785377d49992824a70b43bd5c482c9a,baseChain: 42161,quote:USD,quoteDetails:United States Dollar,rounding:6,fallback:"https://www.coingecko.com/en/coins/uma",configuration:{"type": "medianizer","minTimeBetweenUpdates": 60,"twapLength": 600,"medianizedFeeds":[{"type": "cryptowatch", "exchange": "coinbase-pro", "pair": "umausd" }, { "type": "cryptowatch", "exchange": "binance", "pair": "umausdt" }, { "type": "cryptowatch", "exchange": "okex", "pair": "umausdt" }]}';
        reward = 1e6;

        umaV2PriceProvider = new UmaV2PriceProvider(
            TIME_OUT,
            umaDecimals,
            umaDescription,
            UMAV2_FINDER,
            umaCurrency,
            ancillaryData,
            reward
        );
        deal(USDC_TOKEN, address(this), 1000e6);
        IERC20(USDC_TOKEN).approve(address(umaV2PriceProvider), 1000e6);
    }

    ////////////////////////////////////////////////
    //                STATE                       //
    ////////////////////////////////////////////////

    function testUmaV2Price() public {
        assertEq(umaV2PriceProvider.ORACLE_LIVENESS_TIME(), 3600);
        assertEq(umaV2PriceProvider.PRICE_IDENTIFIER(), "TOKEN_PRICE");
        assertEq(umaV2PriceProvider.timeOut(), TIME_OUT);
        assertEq(address(umaV2PriceProvider.oo()), umaV2);
        assertEq(address(umaV2PriceProvider.finder()), UMAV2_FINDER);
        assertEq(umaV2PriceProvider.decimals(), umaDecimals);
        assertEq(address(umaV2PriceProvider.currency()), umaCurrency);
        assertEq(umaV2PriceProvider.description(), umaDescription);
        assertEq(umaV2PriceProvider.ancillaryData(), ancillaryData);
        assertEq(umaV2PriceProvider.reward(), reward);
    }

    ////////////////////////////////////////////////
    //                ADMIN                       //
    ////////////////////////////////////////////////
    function testUpdateRewardUmaV2Price() public {
        uint256 newReward = 1000;
        vm.expectEmit(true, true, true, true);
        emit RewardUpdated(newReward);
        umaV2PriceProvider.updateReward(newReward);

        assertEq(umaV2PriceProvider.reward(), newReward);
    }

    function testWithdrawBondUmaV2Price() public {
        // Fetching balance before
        IERC20 bondAsset = IERC20(USDC_TOKEN);
        uint256 balance = bondAsset.balanceOf(address(this));

        // Sending funds
        uint256 bondAmount = 1e18;
        deal(USDC_TOKEN, address(umaV2PriceProvider), bondAmount);

        // Checking contract balance updated
        assertEq(bondAsset.balanceOf(address(umaV2PriceProvider)), bondAmount);
        assertEq(bondAsset.balanceOf(address(this)), balance);

        umaV2PriceProvider.withdrawBond();
        assertEq(bondAsset.balanceOf(address(umaV2PriceProvider)), 0);
        assertEq(bondAsset.balanceOf(address(this)), balance + bondAmount);
    }

    ////////////////////////////////////////////////
    //                  PUBLIC CALLBACK           //
    ////////////////////////////////////////////////
    function testPriceSettledUmaV2Price() public {
        bytes32 emptyBytes32;
        bytes memory emptyBytes;
        int256 price = 2e6;

        // Deploying new umaV2PriceProvider with mock contract
        MockUmaV2 mockUmaV2 = new MockUmaV2();
        MockUmaFinder umaMockFinder = new MockUmaFinder(address(mockUmaV2));
        umaV2PriceProvider = new UmaV2PriceProvider(
            TIME_OUT,
            umaDecimals,
            umaDescription,
            address(umaMockFinder),
            umaCurrency,
            ancillaryData,
            reward
        );
        IERC20(USDC_TOKEN).approve(address(umaV2PriceProvider), 1000e6);

        // Configuring the pending answer
        uint256 previousTimestamp = block.timestamp;
        umaV2PriceProvider.requestLatestPrice();
        vm.warp(block.timestamp + 1 days);

        (, , , , bool preActiveAssertion) = umaV2PriceProvider.answer();
        assertEq(preActiveAssertion, true);

        // Configuring the answer via the callback
        vm.prank(address(mockUmaV2));
        umaV2PriceProvider.priceSettled(
            emptyBytes32,
            block.timestamp,
            emptyBytes,
            price
        );
        (
            uint128 roundId,
            uint128 answeredInRound,
            int128 _price,
            uint128 updatedAt,
            bool activeAssertion
        ) = umaV2PriceProvider.answer();

        // Checking the data
        assertEq(roundId, 1);
        assertEq(_price, price);
        assertEq(activeAssertion, false);
        assertEq(updatedAt, block.timestamp);
        assertEq(answeredInRound, 1);
    }

    ////////////////////////////////////////////////
    //                PUBLIC FUNCTIONS            //
    ////////////////////////////////////////////////

    function testrequestLatestPriceUmaV2Price() public {
        uint256 balance = IERC20(USDC_TOKEN).balanceOf(address(this));
        assertEq(balance, 1000e6);

        umaV2PriceProvider.requestLatestPrice();
        (, , , , bool activeAssertion) = umaV2PriceProvider.answer();
        assertEq(activeAssertion, true);

        assertEq(IERC20(USDC_TOKEN).balanceOf(address(this)), balance - reward);
    }

    function testrequestLatestPriceNoTransferUmaV2Price() public {
        deal(USDC_TOKEN, address(umaV2PriceProvider), 1000e6);
        uint256 balance = IERC20(USDC_TOKEN).balanceOf(address(this));
        assertEq(balance, 1000e6);

        umaV2PriceProvider.requestLatestPrice();
        (, , , , bool activeAssertion) = umaV2PriceProvider.answer();
        assertEq(activeAssertion, true);

        assertEq(IERC20(USDC_TOKEN).balanceOf(address(this)), balance);
    }

    function testLatestRoundDataUmaV2Price() public {
        // Config the data using the mock oracle
        _configureSettledPrice();

        (
            uint80 roundId,
            int256 _price,
            bool activeAssertion,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = umaV2PriceProvider.latestRoundData();
        assertTrue(_price != 0);
        assertTrue(roundId != 0);
        assertTrue(activeAssertion == false);
        assertTrue(updatedAt != 0);
        assertTrue(answeredInRound != 0);
    }

    function testLatestPriceUmaV2Price() public {
        // Config the data using the mock oracle
        _configureSettledPrice();

        int256 price = umaV2PriceProvider.getLatestPrice();
        assertTrue(price != 0);
        uint256 calcDecimals = 10 ** (18 - (umaDecimals));
        int256 expectedPrice = 2e6 * int256(calcDecimals);
        assertEq(price, expectedPrice);
    }

    function testConditionOneMetUmaV2Price() public {
        // Config the data with mock oracle
        _configureSettledPrice();

        // Condition type 1
        uint256 marketIdOne = 1;
        uint256 strikeMetPrice = 2000001;
        (bool condition, int256 price) = umaV2PriceProvider.conditionMet(
            strikeMetPrice,
            marketIdOne
        );
        assertTrue(price != 0);
        assertEq(condition, true);
    }

    function testConditionTwoMetUmaV2Price() public {
        // Config the data with mock oracle
        _configureSettledPrice();

        // Condition type 2
        (bool condition, int256 price) = umaV2PriceProvider.conditionMet(
            2 ether,
            marketId
        );
        assertTrue(price != 0);
        assertEq(condition, true);
    }

    function testPriceDeliveredRound2UmaV2() public {
        // Config the data with mock oracle
        address mockUmaV2 = _configureSettledPrice();
        (uint80 roundId, , , , uint80 answeredInRound) = umaV2PriceProvider
            .latestRoundData();
        assertEq(roundId, 1);
        assertEq(answeredInRound, 1);

        // Condition type 2
        (bool condition, int256 price) = umaV2PriceProvider.conditionMet(
            2 ether,
            marketId
        );
        assertTrue(price != 0);
        assertEq(condition, true);

        // Updating the price
        vm.warp(block.timestamp + 601);
        int256 newPrice = 10e6;
        _updatePrice(newPrice, mockUmaV2);
        (roundId, , , , answeredInRound) = umaV2PriceProvider.latestRoundData();
        assertEq(roundId, 2);
        assertEq(answeredInRound, 2);

        (condition, price) = umaV2PriceProvider.conditionMet(2 ether, marketId);
        assertEq(price, newPrice * 10 ** 10);
        assertEq(condition, true);
    }

    ////////////////////////////////////////////////
    //              REVERT CASES                  //
    ////////////////////////////////////////////////
    function testRevertConstructorInputsUmaV2Price() public {
        vm.expectRevert(UmaV2PriceProvider.InvalidInput.selector);
        new UmaV2PriceProvider(
            0,
            umaDecimals,
            umaDescription,
            UMAV2_FINDER,
            umaCurrency,
            ancillaryData,
            reward
        );

        vm.expectRevert(UmaV2PriceProvider.InvalidInput.selector);
        new UmaV2PriceProvider(
            TIME_OUT,
            umaDecimals,
            "",
            UMAV2_FINDER,
            umaCurrency,
            ancillaryData,
            reward
        );

        vm.expectRevert(UmaV2PriceProvider.ZeroAddress.selector);
        new UmaV2PriceProvider(
            TIME_OUT,
            umaDecimals,
            umaDescription,
            address(0),
            umaCurrency,
            ancillaryData,
            reward
        );

        vm.expectRevert(UmaV2PriceProvider.ZeroAddress.selector);
        new UmaV2PriceProvider(
            TIME_OUT,
            umaDecimals,
            umaDescription,
            UMAV2_FINDER,
            address(0),
            ancillaryData,
            reward
        );

        vm.expectRevert(UmaV2PriceProvider.InvalidInput.selector);
        new UmaV2PriceProvider(
            TIME_OUT,
            umaDecimals,
            umaDescription,
            UMAV2_FINDER,
            umaCurrency,
            "",
            reward
        );

        vm.expectRevert(UmaV2PriceProvider.InvalidInput.selector);
        new UmaV2PriceProvider(
            TIME_OUT,
            umaDecimals,
            umaDescription,
            UMAV2_FINDER,
            umaCurrency,
            ancillaryData,
            0
        );
    }

    function testRevertInvalidInputUpdateRewardUmaV2Price() public {
        vm.expectRevert(UmaV2PriceProvider.InvalidInput.selector);
        umaV2PriceProvider.updateReward(0);
    }

    function testRevertInvalidCallerPriceSettledUmaV2Price() public {
        vm.expectRevert(UmaV2PriceProvider.InvalidCaller.selector);
        umaV2PriceProvider.priceSettled(
            bytes32(0),
            block.timestamp,
            bytes(""),
            0
        );
    }

    function testRevertRequestInProgRequestLatestPriceUmaV2Price() public {
        umaV2PriceProvider.requestLatestPrice();
        vm.expectRevert(UmaV2PriceProvider.RequestInProgress.selector);
        umaV2PriceProvider.requestLatestPrice();
    }

    function testRevertCoodownRequestLatestPriceUmaV2Price() public {
        _configureSettledPrice();
        vm.expectRevert(UmaV2PriceProvider.CooldownPeriod.selector);
        umaV2PriceProvider.requestLatestPrice();
    }

    function testRevertOraclePriceZeroUmaV2Price() public {
        vm.expectRevert(UmaV2PriceProvider.OraclePriceZero.selector);
        umaV2PriceProvider.getLatestPrice();
    }

    function testRevertRequestInProgGetLatestUmaV2Price() public {
        _configureSettledPrice();
        vm.warp(block.timestamp + 601);
        umaV2PriceProvider.requestLatestPrice();

        vm.expectRevert(UmaV2PriceProvider.RequestInProgress.selector);
        umaV2PriceProvider.getLatestPrice();
    }

    function testRevertPricedTimedOutUmaV2Price() public {
        _configureSettledPrice();
        vm.warp(block.timestamp + 2 days);

        vm.expectRevert(UmaV2PriceProvider.PriceTimedOut.selector);
        umaV2PriceProvider.getLatestPrice();
    }

    ////////////////////////////////////////////////
    //                    HELPER                  //
    ////////////////////////////////////////////////
    function _configureSettledPrice() internal returns (address) {
        // Config the data using the mock oracle
        bytes32 emptyBytes32;
        bytes memory emptyBytes;
        int256 price = 2e6;

        // Deploying new umaV2PriceProvider with mock contract
        MockUmaV2 mockUmaV2 = new MockUmaV2();
        MockUmaFinder umaMockFinder = new MockUmaFinder(address(mockUmaV2));
        umaV2PriceProvider = new UmaV2PriceProvider(
            TIME_OUT,
            umaDecimals,
            umaDescription,
            address(umaMockFinder),
            umaCurrency,
            ancillaryData,
            reward
        );
        IERC20(USDC_TOKEN).approve(address(umaV2PriceProvider), 1000e6);

        // Configuring the pending answer
        umaV2PriceProvider.requestLatestPrice();
        vm.warp(block.timestamp + 1 days);

        // Configuring the answer via the callback
        vm.prank(address(mockUmaV2));
        umaV2PriceProvider.priceSettled(
            emptyBytes32,
            block.timestamp,
            emptyBytes,
            price
        );

        return address(mockUmaV2);
    }

    function _updatePrice(int256 price, address mockUmaV2) internal {
        // Config the data using the mock oracle
        bytes32 emptyBytes32;
        bytes memory emptyBytes;

        IERC20(USDC_TOKEN).approve(address(umaV2PriceProvider), 1000e6);

        // Configuring the pending answer
        umaV2PriceProvider.requestLatestPrice();
        vm.warp(block.timestamp + 1 days);

        // Configuring the answer via the callback
        vm.prank(address(mockUmaV2));
        umaV2PriceProvider.priceSettled(
            emptyBytes32,
            block.timestamp,
            emptyBytes,
            price
        );
    }
}
