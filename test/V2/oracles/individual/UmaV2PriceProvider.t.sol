// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Helper} from "../../Helper.sol";
import {VaultFactoryV2} from "../../../../src/v2/VaultFactoryV2.sol";
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
} from "../MockOracles.sol";

contract UmaV2PriceProviderTest is Helper {
    uint256 public arbForkId;
    uint256 public arbGoerliForkId;
    VaultFactoryV2 public factory;
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
    uint256 public requiredBond;

    function setUp() public {
        arbForkId = vm.createFork(ARBITRUM_RPC_URL);
        vm.selectFork(arbForkId);

        address timelock = address(new TimeLock(ADMIN));
        factory = new VaultFactoryV2(WETH, TREASURY, address(timelock));

        umaDecimals = 8;
        umaDescription = "FUSD/ETH";
        umaCurrency = USDC_TOKEN;
        // TODO: Need to review how the configuration section should be composed
        ancillaryData = "base: FUSD, quote: USDC, baseChain: ArbitrumOne, rounding: 6, configurations: {}";
        requiredBond = 1e6;

        umaV2PriceProvider = new UmaV2PriceProvider(
            address(factory),
            TIME_OUT,
            umaDecimals,
            umaDescription,
            UMAV2_FINDER,
            umaCurrency,
            ancillaryData,
            requiredBond
        );
        uint256 condition = 2;
        umaV2PriceProvider.setConditionType(marketId, condition);
    }

    ////////////////////////////////////////////////
    //                STATE                       //
    ////////////////////////////////////////////////

    function testUmaV2Provider() public {
        assertEq(umaV2PriceProvider.ORACLE_LIVENESS_TIME(), 3600 * 2);
        assertEq(umaV2PriceProvider.PRICE_IDENTIFIER(), "TOKEN_PRICE");
        assertEq(umaV2PriceProvider.timeOut(), TIME_OUT);
        assertEq(address(umaV2PriceProvider.vaultFactory()), address(factory));
        assertEq(address(umaV2PriceProvider.oo()), umaV2);
        assertEq(address(umaV2PriceProvider.finder()), UMAV2_FINDER);
        assertEq(umaV2PriceProvider.decimals(), umaDecimals);
        assertEq(address(umaV2PriceProvider.currency()), umaCurrency);
        assertEq(umaV2PriceProvider.description(), umaDescription);
        assertEq(umaV2PriceProvider.ancillaryData(), ancillaryData);
        assertEq(umaV2PriceProvider.requiredBond(), requiredBond);
    }

    ////////////////////////////////////////////////
    //                ADMIN                       //
    ////////////////////////////////////////////////
    function testSetConditionTypeUmaV2() public {
        uint256 _marketId = 911;
        uint256 _condition = 1;

        vm.expectEmit(true, true, true, true);
        emit MarketConditionSet(_marketId, _condition);
        umaV2PriceProvider.setConditionType(_marketId, _condition);

        assertEq(umaV2PriceProvider.marketIdToConditionType(_marketId), 1);
    }

    function testUpdateRequiredBondUmaV2() public {
        uint256 newBond = 1000;
        vm.expectEmit(true, true, true, true);
        emit BondUpdated(newBond);
        umaV2PriceProvider.updateRequiredBond(newBond);

        assertEq(umaV2PriceProvider.requiredBond(), newBond);
    }

    ////////////////////////////////////////////////
    //                  PUBLIC CALLBACK           //
    ////////////////////////////////////////////////
    function testPriceSettledUmaV2() public {
        bytes32 emptyBytes32;
        bytes memory emptyBytes;
        int256 price = 2e6;

        // Deploying new umaV2PriceProvider with mock contract
        MockUmaV2 mockUmaV2 = new MockUmaV2();
        MockUmaFinder umaMockFinder = new MockUmaFinder(address(mockUmaV2));
        umaV2PriceProvider = new UmaV2PriceProvider(
            address(factory),
            TIME_OUT,
            umaDecimals,
            umaDescription,
            address(umaMockFinder),
            umaCurrency,
            ancillaryData,
            requiredBond
        );

        // Configuring the pending answer
        uint256 previousTimestamp = block.timestamp;
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
        (
            uint80 roundId,
            int256 _price,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = umaV2PriceProvider.answer();

        // Checking the data
        assertEq(roundId, 1);
        assertEq(_price, price);
        assertEq(startedAt, previousTimestamp);
        assertEq(updatedAt, block.timestamp);
        assertEq(answeredInRound, 1);
    }

    ////////////////////////////////////////////////
    //                PUBLIC FUNCTIONS            //
    ////////////////////////////////////////////////
    function testrequestLatestPriceUmaV2PriceProvider() public {
        umaV2PriceProvider.requestLatestPrice();
        (, , uint256 startedAt, , ) = umaV2PriceProvider.pendingAnswer();
        assertEq(startedAt, block.timestamp);
    }

    function testLatestRoundDataUmaV2PriceProvider() public {
        // Config the data using the mock oracle
        _configureSettledPrice();

        (
            uint80 roundId,
            int256 _price,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = umaV2PriceProvider.latestRoundData();
        assertTrue(_price != 0);
        assertTrue(roundId != 0);
        assertTrue(startedAt != 0);
        assertTrue(updatedAt != 0);
        assertTrue(answeredInRound != 0);
    }

    function testLatestPriceUmaV2PriceProvider() public {
        // Config the data using the mock oracle
        _configureSettledPrice();

        int256 price = umaV2PriceProvider.getLatestPrice();
        assertTrue(price != 0);
        uint256 calcDecimals = 10 ** (18 - (umaDecimals));
        int256 expectedPrice = 2e6 * int256(calcDecimals);
        assertEq(price, expectedPrice);
    }

    function testConditionOneMetUmaV2PriceProvider() public {
        // Config the data with mock oracle
        _configureSettledPrice();

        uint256 conditionType = 1;
        uint256 marketIdOne = 1;
        umaV2PriceProvider.setConditionType(marketIdOne, conditionType);
        (bool condition, int256 price) = umaV2PriceProvider.conditionMet(
            0.001 ether,
            marketIdOne
        );
        assertTrue(price != 0);
        assertEq(condition, true);
    }

    function testConditionTwoMetUmaV2PriceProvider() public {
        // Config the data with mock oracle
        _configureSettledPrice();

        uint256 conditionType = 2;
        umaV2PriceProvider.setConditionType(marketId, conditionType);
        (bool condition, int256 price) = umaV2PriceProvider.conditionMet(
            2 ether,
            marketId
        );
        assertTrue(price != 0);
        assertEq(condition, true);
    }

    ////////////////////////////////////////////////
    //              REVERT CASES                  //
    ////////////////////////////////////////////////
    function testRevertConstructorInputsUmaV2PriceProvider() public {
        vm.expectRevert(UmaV2PriceProvider.ZeroAddress.selector);
        new UmaV2PriceProvider(
            address(0),
            TIME_OUT,
            umaDecimals,
            umaDescription,
            UMAV2_FINDER,
            umaCurrency,
            ancillaryData,
            requiredBond
        );

        vm.expectRevert(UmaV2PriceProvider.InvalidInput.selector);
        new UmaV2PriceProvider(
            address(factory),
            0,
            umaDecimals,
            umaDescription,
            UMAV2_FINDER,
            umaCurrency,
            ancillaryData,
            requiredBond
        );

        vm.expectRevert(UmaV2PriceProvider.InvalidInput.selector);
        new UmaV2PriceProvider(
            address(factory),
            TIME_OUT,
            umaDecimals,
            "",
            UMAV2_FINDER,
            umaCurrency,
            ancillaryData,
            requiredBond
        );

        vm.expectRevert(UmaV2PriceProvider.ZeroAddress.selector);
        new UmaV2PriceProvider(
            address(factory),
            TIME_OUT,
            umaDecimals,
            umaDescription,
            address(0),
            umaCurrency,
            ancillaryData,
            requiredBond
        );

        vm.expectRevert(UmaV2PriceProvider.ZeroAddress.selector);
        new UmaV2PriceProvider(
            address(factory),
            TIME_OUT,
            umaDecimals,
            umaDescription,
            UMAV2_FINDER,
            address(0),
            ancillaryData,
            requiredBond
        );

        vm.expectRevert(UmaV2PriceProvider.InvalidInput.selector);
        new UmaV2PriceProvider(
            address(factory),
            TIME_OUT,
            umaDecimals,
            umaDescription,
            UMAV2_FINDER,
            umaCurrency,
            "",
            requiredBond
        );

        vm.expectRevert(UmaV2PriceProvider.InvalidInput.selector);
        new UmaV2PriceProvider(
            address(factory),
            TIME_OUT,
            umaDecimals,
            umaDescription,
            UMAV2_FINDER,
            umaCurrency,
            ancillaryData,
            0
        );
    }

    function testRevertConditionTypeSetUmaV2PriceProvider() public {
        vm.expectRevert(UmaV2PriceProvider.ConditionTypeSet.selector);
        umaV2PriceProvider.setConditionType(2, 0);
    }

    function testRevertInvalidInputConditionUmaV2PriceProvider() public {
        vm.expectRevert(UmaV2PriceProvider.InvalidInput.selector);
        umaV2PriceProvider.setConditionType(0, 0);
    }

    function testRevertInvalidInputUpdateRequiredBond() public {
        vm.expectRevert(UmaV2PriceProvider.InvalidInput.selector);
        umaV2PriceProvider.updateRequiredBond(0);
    }

    function testRevertInvalidCallerPriceSettled() public {
        vm.expectRevert(UmaV2PriceProvider.InvalidCaller.selector);
        umaV2PriceProvider.priceSettled(
            bytes32(0),
            block.timestamp,
            bytes(""),
            0
        );
    }

    function testRevertRequestInProgRequestLatestPrice() public {
        umaV2PriceProvider.requestLatestPrice();
        vm.expectRevert(UmaV2PriceProvider.RequestInProgress.selector);
        umaV2PriceProvider.requestLatestPrice();
    }

    function testRevertOraclePriceZeroUmaV2PriceProvider() public {
        vm.expectRevert(UmaV2PriceProvider.OraclePriceZero.selector);
        umaV2PriceProvider.getLatestPrice();
    }

    function testRevertPricedTimedOutUmaV2PriceProvider() public {
        _configureSettledPrice();
        vm.warp(block.timestamp + 2 days);

        vm.expectRevert(UmaV2PriceProvider.PriceTimedOut.selector);
        umaV2PriceProvider.getLatestPrice();
    }

    function testRevertConditionTypeNotSetUmaV2PriceProvider() public {
        _configureSettledPrice();

        vm.expectRevert(UmaV2PriceProvider.ConditionTypeNotSet.selector);
        umaV2PriceProvider.conditionMet(0.001 ether, 1);
    }

    ////////////////////////////////////////////////
    //                    HELPER                  //
    ////////////////////////////////////////////////
    function _configureSettledPrice() internal {
        // Config the data using the mock oracle
        bytes32 emptyBytes32;
        bytes memory emptyBytes;
        int256 price = 2e6;

        // Deploying new umaV2PriceProvider with mock contract
        MockUmaV2 mockUmaV2 = new MockUmaV2();
        MockUmaFinder umaMockFinder = new MockUmaFinder(address(mockUmaV2));
        umaV2PriceProvider = new UmaV2PriceProvider(
            address(factory),
            TIME_OUT,
            umaDecimals,
            umaDescription,
            address(umaMockFinder),
            umaCurrency,
            ancillaryData,
            requiredBond
        );

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
