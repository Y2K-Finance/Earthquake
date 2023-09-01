// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Helper} from "../../Helper.sol";
import {VaultFactoryV2} from "../../../../src/v2/VaultFactoryV2.sol";
import {
    UmaPriceProvider
} from "../../../../src/v2/oracles/individual/UmaPriceProvider.sol";
import {TimeLock} from "../../../../src/v2/TimeLock.sol";
import {
    MockOracleAnswerZero,
    MockOracleRoundOutdated,
    MockOracleTimeOut
} from "../MockOracles.sol";

contract UmaPriceProviderTest is Helper {
    uint256 public arbForkId;
    VaultFactoryV2 public factory;
    UmaPriceProvider public umaPriceProvider;
    uint256 public marketId = 2;

    ////////////////////////////////////////////////
    //                HELPERS                     //
    ////////////////////////////////////////////////
    uint256 public UMA_DECIMALS = 18;
    address public UMA_OO_V3 = address(0x123);
    string public UMA_DESCRIPTION = "USDC";
    bytes32 public defaultIdentifier = bytes32("abc");
    bytes public assertionDescription;

    function setUp() public {
        arbForkId = vm.createFork(ARBITRUM_RPC_URL);
        vm.selectFork(arbForkId);

        // TODO: Should this be encoded or encode packed?
        assertionDescription = abi.encode("USDC/USD price is less than 0.97");

        address timelock = address(new TimeLock(ADMIN));
        factory = new VaultFactoryV2(WETH, TREASURY, address(timelock));
        umaPriceProvider = new UmaPriceProvider(
            address(factory),
            UMA_DECIMALS,
            UMA_DESCRIPTION,
            TIME_OUT,
            UMA_OO_V3,
            defaultIdentifier,
            WETH_ADDRESS,
            assertionDescription
        );

        uint256 condition = 2;
        umaPriceProvider.setConditionType(marketId, condition);
    }

    ////////////////////////////////////////////////
    //                STATE                       //
    ////////////////////////////////////////////////
    function testUmaCreation() public {
        assertEq(address(umaPriceProvider.vaultFactory()), address(factory));
        assertEq(umaPriceProvider.decimals(), UMA_DECIMALS);
        assertEq(umaPriceProvider.description(), UMA_DESCRIPTION);
        assertEq(umaPriceProvider.timeOut(), TIME_OUT);
        assertEq(address(umaPriceProvider.umaV3()), UMA_OO_V3);
        assertEq(umaPriceProvider.defaultIdentifier(), defaultIdentifier);
        assertEq(umaPriceProvider.currency(), WETH_ADDRESS);
    }

    ////////////////////////////////////////////////
    //                FUNCTIONS                  //
    ////////////////////////////////////////////////
    function testLatestRoundDataUma() public {
        (
            uint80 roundId,
            int256 price,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = umaPriceProvider.latestRoundData();
        assertTrue(price == 0);
        assertTrue(roundId == 0);
        assertTrue(startedAt == 0);
        assertTrue(updatedAt == 0);
        assertTrue(answeredInRound == 0);
    }

    function testLatestPriceUma() public {
        int256 price = umaPriceProvider.getLatestPrice();
        assertTrue(price == 0);
    }

    function testConditionMetUma() public {
        // Configuring the assertionInfo
        // TODO: Need mock umaOOV3 to return an assertionId
        vm.prank(UMA_OO_V3);
        bytes32 assertionId = bytes32("");
        umaPriceProvider.assertionResolvedCallback(assertionId, true);

        (bool condition, int256 price) = umaPriceProvider.conditionMet(
            2 ether,
            marketId
        );
        assertTrue(price != 0);
        assertEq(condition, true);
    }

    function testConditionOneMetUma() public {
        uint256 conditionType = 1;
        uint256 marketIdOne = 1;
        umaPriceProvider.setConditionType(marketIdOne, conditionType);

        // Configuring the assertionInfo
        vm.prank(UMA_OO_V3);
        // TODO: Need mock umaOOV3 to return an assertionId
        bytes32 assertionId = bytes32("");
        umaPriceProvider.assertionResolvedCallback(assertionId, true);

        (bool condition, int256 price) = umaPriceProvider.conditionMet(
            0.01 ether,
            marketIdOne
        );
        assertTrue(price != 0);
        assertEq(condition, true);
    }

    function testConditionTwoMetUma() public {
        // Configuring the assertionInfo
        vm.prank(UMA_OO_V3);
        // TODO: Need mock umaOOV3 to return an assertionId
        bytes32 assertionId = bytes32("");
        umaPriceProvider.assertionResolvedCallback(assertionId, true);
        (bool condition, int256 price) = umaPriceProvider.conditionMet(
            2 ether,
            marketId
        );
        assertTrue(price != 0);
        assertEq(condition, true);
    }

    ////////////////////////////////////////////////
    //              REVERT CASES                  //
    ////////////////////////////////////////////////

    function testRevertConstructorInputsUma() public {
        vm.expectRevert(UmaPriceProvider.ZeroAddress.selector);
        new UmaPriceProvider(
            address(0),
            UMA_DECIMALS,
            UMA_DESCRIPTION,
            TIME_OUT,
            UMA_OO_V3,
            defaultIdentifier,
            WETH_ADDRESS,
            assertionDescription
        );

        vm.expectRevert(UmaPriceProvider.InvalidInput.selector);
        new UmaPriceProvider(
            address(factory),
            0,
            UMA_DESCRIPTION,
            TIME_OUT,
            UMA_OO_V3,
            defaultIdentifier,
            WETH_ADDRESS,
            assertionDescription
        );

        vm.expectRevert(UmaPriceProvider.InvalidInput.selector);
        new UmaPriceProvider(
            address(factory),
            UMA_DECIMALS,
            string(""),
            TIME_OUT,
            UMA_OO_V3,
            defaultIdentifier,
            WETH_ADDRESS,
            assertionDescription
        );

        vm.expectRevert(UmaPriceProvider.InvalidInput.selector);
        new UmaPriceProvider(
            address(factory),
            UMA_DECIMALS,
            UMA_DESCRIPTION,
            0,
            UMA_OO_V3,
            defaultIdentifier,
            WETH_ADDRESS,
            assertionDescription
        );

        vm.expectRevert(UmaPriceProvider.ZeroAddress.selector);
        new UmaPriceProvider(
            address(factory),
            UMA_DECIMALS,
            UMA_DESCRIPTION,
            TIME_OUT,
            address(0),
            defaultIdentifier,
            WETH_ADDRESS,
            assertionDescription
        );

        vm.expectRevert(UmaPriceProvider.InvalidInput.selector);
        new UmaPriceProvider(
            address(factory),
            UMA_DECIMALS,
            UMA_DESCRIPTION,
            TIME_OUT,
            UMA_OO_V3,
            bytes32(""),
            WETH_ADDRESS,
            assertionDescription
        );

        vm.expectRevert(UmaPriceProvider.ZeroAddress.selector);
        new UmaPriceProvider(
            address(factory),
            UMA_DECIMALS,
            UMA_DESCRIPTION,
            TIME_OUT,
            UMA_OO_V3,
            defaultIdentifier,
            address(0),
            assertionDescription
        );

        vm.expectRevert(UmaPriceProvider.InvalidInput.selector);
        new UmaPriceProvider(
            address(factory),
            UMA_DECIMALS,
            UMA_DESCRIPTION,
            TIME_OUT,
            UMA_OO_V3,
            defaultIdentifier,
            WETH_ADDRESS,
            bytes("")
        );
    }

    function testRevertConditionTypeSetUma() public {
        vm.expectRevert(UmaPriceProvider.ConditionTypeSet.selector);
        umaPriceProvider.setConditionType(2, 0);
    }

    function testRevertInvalidInputConditionUma() public {
        vm.expectRevert(UmaPriceProvider.InvalidInput.selector);
        umaPriceProvider.setConditionType(0, 0);

        vm.expectRevert(UmaPriceProvider.InvalidInput.selector);
        umaPriceProvider.setConditionType(0, 3);
    }

    function testRevertInvalidCallerCallback() public {
        vm.expectRevert(UmaPriceProvider.InvalidCaller.selector);
        umaPriceProvider.assertionResolvedCallback(bytes32(""), true);
    }

    function testRevertInvalidCallbackCallback() public {
        vm.expectRevert(UmaPriceProvider.InvalidCallback.selector);

        bytes32 assertionId = bytes32("12");
        vm.prank(UMA_OO_V3);
        umaPriceProvider.assertionResolvedCallback(assertionId, true);
    }

    function testRevertAssertionActive() public {
        uint256 marketId = 1;
        // TODO: Need to create an active assertion

        vm.expectRevert(UmaPriceProvider.AssertionActive.selector);
        umaPriceProvider.fetchAssertion(_marketId);
    }

    function testRevertTimeOutUma() public {
        address mockOracle = address(
            new MockOracleTimeOut(block.timestamp, TIME_OUT)
        );
        umaPriceProvider = new UmaPriceProvider(
            address(factory),
            UMA_DECIMALS,
            UMA_DESCRIPTION,
            TIME_OUT,
            UMA_OO_V3,
            defaultIdentifier,
            WETH_ADDRESS,
            assertionDescription
        );
        vm.expectRevert(UmaPriceProvider.PriceTimedOut.selector);
        umaPriceProvider.checkAssertion(123);
    }
}
