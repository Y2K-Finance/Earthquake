// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Helper} from "../../Helper.sol";
import {VaultFactoryV2} from "../../../../src/v2/VaultFactoryV2.sol";
import {
    UmaV2AssertionProvider
} from "../../../../src/v2/oracles/individual/UmaV2AssertionProvider.sol";
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

// Specification for YER_NO_QUERY on Uma: https://github.com/UMAprotocol/UMIPs/blob/master/UMIPs/umip-107.md
// Uma address all networks: https://docs.uma.xyz/resources/network-addresses
// Uma addresses on Arbitrum: https://github.com/UMAprotocol/protocol/blob/master/packages/core/networks/42161.json

contract UmaV2AssertionProviderTest is Helper {
    uint256 public arbForkId;
    VaultFactoryV2 public factory;
    UmaV2AssertionProvider public umaV2AssertionProvider;
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
        ancillaryData = "q: Curve USDC pool on Arbitrum One was hacked or compromised leading to locked funds or >25% loss in TVL value after the timestamp of: ";
        requiredBond = 1e6;

        umaV2AssertionProvider = new UmaV2AssertionProvider(
            address(factory),
            TIME_OUT,
            umaDescription,
            UMAV2_FINDER,
            umaCurrency,
            ancillaryData,
            requiredBond
        );
        uint256 condition = 2;
        umaV2AssertionProvider.setConditionType(marketId, condition);
    }

    ////////////////////////////////////////////////
    //                STATE                       //
    ////////////////////////////////////////////////
    function testUmaV2AssertionProvider() public {
        assertEq(umaV2AssertionProvider.ORACLE_LIVENESS_TIME(), 3600 * 2);
        assertEq(umaV2AssertionProvider.PRICE_IDENTIFIER(), "YES_OR_NO_QUERY");
        assertEq(umaV2AssertionProvider.timeOut(), TIME_OUT);
        assertEq(
            address(umaV2AssertionProvider.vaultFactory()),
            address(factory)
        );
        assertEq(address(umaV2AssertionProvider.oo()), umaV2);
        assertEq(address(umaV2AssertionProvider.finder()), UMAV2_FINDER);
        assertEq(address(umaV2AssertionProvider.currency()), umaCurrency);
        assertEq(umaV2AssertionProvider.description(), umaDescription);
        assertEq(umaV2AssertionProvider.ancillaryData(), ancillaryData);
        assertEq(umaV2AssertionProvider.requiredBond(), requiredBond);
        assertEq(umaV2AssertionProvider.coverageStart(), block.timestamp);
    }

    ////////////////////////////////////////////////
    //                ADMIN                       //
    ////////////////////////////////////////////////
    function testSetConditionTypeUmaV2Assert() public {
        uint256 _marketId = 911;
        uint256 _condition = 1;

        vm.expectEmit(true, true, true, true);
        emit MarketConditionSet(_marketId, _condition);
        umaV2AssertionProvider.setConditionType(_marketId, _condition);

        assertEq(umaV2AssertionProvider.marketIdToConditionType(_marketId), 1);
    }

    function testUpdateCoverageStartUmaV2Assert() public {
        uint256 newCoverageStart = block.timestamp + 1 days;
        vm.expectEmit(true, true, true, true);
        emit CoverageStartUpdated(newCoverageStart);
        umaV2AssertionProvider.updateCoverageStart(newCoverageStart);

        assertEq(umaV2AssertionProvider.coverageStart(), newCoverageStart);
    }

    function testUpdateRequiredBondUmaV2Assert() public {
        uint256 newBond = 1000;
        vm.expectEmit(true, true, true, true);
        emit BondUpdated(newBond);
        umaV2AssertionProvider.updateRequiredBond(newBond);

        assertEq(umaV2AssertionProvider.requiredBond(), newBond);
    }

    ////////////////////////////////////////////////
    //                  PUBLIC CALLBACK           //
    ////////////////////////////////////////////////
    function testPriceSettledUmaV2Assert() public {
        bytes32 emptyBytes32;
        bytes memory emptyBytes;
        int256 price = 1;

        // Deploying new UmaV2AssertionProvider with mock contract
        MockUmaV2 mockUmaV2 = new MockUmaV2();
        MockUmaFinder umaMockFinder = new MockUmaFinder(address(mockUmaV2));
        umaV2AssertionProvider = new UmaV2AssertionProvider(
            address(factory),
            TIME_OUT,
            umaDescription,
            address(umaMockFinder),
            umaCurrency,
            ancillaryData,
            requiredBond
        );

        // Configuring the pending answer
        uint256 previousTimestamp = block.timestamp;
        umaV2AssertionProvider.requestLatestAssertion();
        vm.warp(block.timestamp + 1 days);

        // Configuring the answer via the callback
        vm.prank(address(mockUmaV2));
        umaV2AssertionProvider.priceSettled(
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
        ) = umaV2AssertionProvider.answer();

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
    function testrequestLatestAssertionUmaV2Assert() public {
        umaV2AssertionProvider.requestLatestAssertion();
        (, , uint256 startedAt, , ) = umaV2AssertionProvider.pendingAnswer();
        assertEq(startedAt, block.timestamp);
    }

    function testCheckAssertionUmaV2Assert() public {
        // Config the data with mock oracle
        _configureSettledPrice(true);

        bool condition = umaV2AssertionProvider.checkAssertion();
        assertEq(condition, true);
    }

    function testConditionOneMetUmaV2AssertProvider() public {
        // Config the data with mock oracle
        _configureSettledPrice(true);

        uint256 conditionType = 1;
        uint256 marketIdOne = 1;
        umaV2AssertionProvider.setConditionType(marketIdOne, conditionType);
        (bool condition, ) = umaV2AssertionProvider.conditionMet(
            0.001 ether,
            marketIdOne
        );

        assertEq(condition, true);
    }

    function testConditionTwoMetUmaV2Assert() public {
        // Config the data with mock oracle
        _configureSettledPrice(false);

        uint256 conditionType = 2;
        umaV2AssertionProvider.setConditionType(marketId, conditionType);
        (bool condition, ) = umaV2AssertionProvider.conditionMet(
            2 ether,
            marketId
        );

        assertEq(condition, false);
    }

    ////////////////////////////////////////////////
    //              REVERT CASES                  //
    ////////////////////////////////////////////////
    function testRevertConstructorInputsUmaV2Assert() public {
        vm.expectRevert(UmaV2AssertionProvider.ZeroAddress.selector);
        new UmaV2AssertionProvider(
            address(0),
            TIME_OUT,
            umaDescription,
            UMAV2_FINDER,
            umaCurrency,
            ancillaryData,
            requiredBond
        );

        vm.expectRevert(UmaV2AssertionProvider.InvalidInput.selector);
        new UmaV2AssertionProvider(
            address(factory),
            0,
            umaDescription,
            UMAV2_FINDER,
            umaCurrency,
            ancillaryData,
            requiredBond
        );

        vm.expectRevert(UmaV2AssertionProvider.InvalidInput.selector);
        new UmaV2AssertionProvider(
            address(factory),
            TIME_OUT,
            "",
            UMAV2_FINDER,
            umaCurrency,
            ancillaryData,
            requiredBond
        );

        vm.expectRevert(UmaV2AssertionProvider.ZeroAddress.selector);
        new UmaV2AssertionProvider(
            address(factory),
            TIME_OUT,
            umaDescription,
            address(0),
            umaCurrency,
            ancillaryData,
            requiredBond
        );

        vm.expectRevert(UmaV2AssertionProvider.ZeroAddress.selector);
        new UmaV2AssertionProvider(
            address(factory),
            TIME_OUT,
            umaDescription,
            UMAV2_FINDER,
            address(0),
            ancillaryData,
            requiredBond
        );

        vm.expectRevert(UmaV2AssertionProvider.InvalidInput.selector);
        new UmaV2AssertionProvider(
            address(factory),
            TIME_OUT,
            umaDescription,
            UMAV2_FINDER,
            umaCurrency,
            "",
            requiredBond
        );

        vm.expectRevert(UmaV2AssertionProvider.InvalidInput.selector);
        new UmaV2AssertionProvider(
            address(factory),
            TIME_OUT,
            umaDescription,
            UMAV2_FINDER,
            umaCurrency,
            ancillaryData,
            0
        );
    }

    function testRevertConditionTypeSetUmaV2Assert() public {
        vm.expectRevert(UmaV2AssertionProvider.ConditionTypeSet.selector);
        umaV2AssertionProvider.setConditionType(2, 0);
    }

    function testRevertInvalidInputConditionUmaV2Assert() public {
        vm.expectRevert(UmaV2AssertionProvider.InvalidInput.selector);
        umaV2AssertionProvider.setConditionType(0, 0);
    }

    function testRevertInvalidInputCoverageStartUmaV2Assert() public {
        vm.expectRevert(UmaV2AssertionProvider.InvalidInput.selector);
        umaV2AssertionProvider.updateCoverageStart(0);
    }

    function testRevertInvalidInputUpdateRequiredBondUmaV2Assert() public {
        vm.expectRevert(UmaV2AssertionProvider.InvalidInput.selector);
        umaV2AssertionProvider.updateRequiredBond(0);
    }

    function testRevertInvalidCallerPriceSettledUmaV2Assert() public {
        vm.expectRevert(UmaV2AssertionProvider.InvalidCaller.selector);
        umaV2AssertionProvider.priceSettled(
            bytes32(0),
            block.timestamp,
            bytes(""),
            0
        );
    }

    function testRevertRequestInProgRequestLatestAssertionUmaV2Assert() public {
        umaV2AssertionProvider.requestLatestAssertion();
        vm.expectRevert(UmaV2AssertionProvider.RequestInProgress.selector);
        umaV2AssertionProvider.requestLatestAssertion();
    }

    function testRevertOraclePriceZeroCheckAssertionUmaV2Assert() public {
        vm.expectRevert(UmaV2AssertionProvider.OraclePriceZero.selector);
        umaV2AssertionProvider.checkAssertion();
    }

    function testRevertPriceTimedOutCheckAssertionUmaV2Assert() public {
        // Config the data with mock oracle
        _configureSettledPrice(true);

        vm.warp(block.timestamp + 2 days);
        vm.expectRevert(UmaV2AssertionProvider.PriceTimedOut.selector);
        umaV2AssertionProvider.checkAssertion();
    }

    function testRevertConditionTypeNotSetUmaV2Assert() public {
        _configureSettledPrice(true);

        vm.expectRevert(UmaV2AssertionProvider.ConditionTypeNotSet.selector);
        umaV2AssertionProvider.conditionMet(0.001 ether, 1);
    }

    ////////////////////////////////////////////////
    //                    HELPER                  //
    ////////////////////////////////////////////////
    function _configureSettledPrice(bool condition) internal {
        // Config the data using the mock oracle
        bytes32 emptyBytes32;
        bytes memory emptyBytes;
        int256 price = condition ? int256(1) : int256(0);

        // Deploying new UmaV2AssertionProvider with mock contract
        MockUmaV2 mockUmaV2 = new MockUmaV2();
        MockUmaFinder umaMockFinder = new MockUmaFinder(address(mockUmaV2));
        umaV2AssertionProvider = new UmaV2AssertionProvider(
            address(factory),
            TIME_OUT,
            umaDescription,
            address(umaMockFinder),
            umaCurrency,
            ancillaryData,
            requiredBond
        );

        // Configuring the pending answer
        umaV2AssertionProvider.requestLatestAssertion();
        vm.warp(block.timestamp + 1 days);

        // Configuring the answer via the callback
        vm.prank(address(mockUmaV2));
        umaV2AssertionProvider.priceSettled(
            emptyBytes32,
            block.timestamp,
            emptyBytes,
            price
        );
    }
}
