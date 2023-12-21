// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Helper} from "../../Helper.sol";
import {VaultFactoryV2} from "../../../../src/v2/VaultFactoryV2.sol";
import {
    UmaV3PriceProvider
} from "../../../../src/v2/oracles/individual/UmaV3PriceProvider.sol";
import {TimeLock} from "../../../../src/v2/TimeLock.sol";
import {
    MockOracleAnswerZero,
    MockOracleRoundOutdated,
    MockOracleTimeOut
} from "../mocks/MockOracles.sol";
import {MockUma} from "../mocks/MockUma.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {
    IOptimisticOracleV3
} from "../../../../src/v2/interfaces/IOptimisticOracleV3.sol";

contract UmaV3PriceProviderTest is Helper {
    uint256 public arbForkId;
    VaultFactoryV2 public factory;
    UmaV3PriceProvider public umaPriceProvider;
    uint256 public marketId = 2;
    ERC20 public wethAsset;

    ////////////////////////////////////////////////
    //                HELPERS                     //
    ////////////////////////////////////////////////
    uint256 public UMA_DECIMALS = 18;
    address public UMA_OO_V3 = 0xa6147867264374F324524E30C02C331cF28aa879;
    string public UMA_DESCRIPTION = "USDC";
    uint256 public REQUIRED_BOND = 1e6;
    bytes32 public defaultIdentifier = bytes32("abc");
    string public ASSERTION_DESCRIPTION = " USDC/USD exchange rate is";

    function setUp() public {
        arbForkId = vm.createFork(ARBITRUM_RPC_URL);
        vm.selectFork(arbForkId);
        wethAsset = ERC20(WETH_ADDRESS);

        address timelock = address(new TimeLock(ADMIN));
        factory = new VaultFactoryV2(WETH, TREASURY, address(timelock));
        umaPriceProvider = new UmaV3PriceProvider(
            UMA_DECIMALS,
            UMA_DESCRIPTION,
            ASSERTION_DESCRIPTION,
            TIME_OUT,
            UMA_OO_V3,
            WETH_ADDRESS,
            REQUIRED_BOND
        );

        umaPriceProvider.updateRelayer(address(this));
    }

    ////////////////////////////////////////////////
    //                STATE                       //
    ////////////////////////////////////////////////
    function testUmaCreation() public {
        assertEq(umaPriceProvider.ASSERTION_LIVENESS(), 7200);
        assertEq(umaPriceProvider.ASSERTION_COOLDOWN(), 600);
        assertEq(umaPriceProvider.currency(), WETH_ADDRESS);
        assertEq(
            umaPriceProvider.defaultIdentifier(),
            IOptimisticOracleV3(UMA_OO_V3).defaultIdentifier()
        );
        assertEq(address(umaPriceProvider.umaV3()), UMA_OO_V3);
        assertEq(umaPriceProvider.requiredBond(), REQUIRED_BOND);

        assertEq(umaPriceProvider.timeOut(), TIME_OUT);
        assertEq(umaPriceProvider.decimals(), UMA_DECIMALS);
        assertEq(umaPriceProvider.description(), UMA_DESCRIPTION);
        assertEq(
            umaPriceProvider.assertionDescription(),
            ASSERTION_DESCRIPTION
        );
        assertEq(umaPriceProvider.whitelistRelayer(address(this)), true);
    }

    function testUpdateRequiredBond() public {
        uint256 newBond = 1e6;

        vm.expectEmit(true, true, false, false);
        emit BondUpdated(newBond);
        umaPriceProvider.updateRequiredBond(newBond);
        assertEq(umaPriceProvider.requiredBond(), newBond);
    }

    function testUpdateRelayer() public {
        address newRelayer = address(0x123);

        vm.expectEmit(true, true, false, false);
        emit RelayerUpdated(newRelayer, true);
        umaPriceProvider.updateRelayer(newRelayer);
        assertEq(umaPriceProvider.whitelistRelayer(newRelayer), true);

        umaPriceProvider.updateRelayer(newRelayer);
        assertEq(umaPriceProvider.whitelistRelayer(newRelayer), false);
    }

    function testWithdrawBond() public {
        uint256 bondAmount = 1e18;
        deal(WETH_ADDRESS, address(umaPriceProvider), bondAmount);
        ERC20 bondAsset = ERC20(WETH_ADDRESS);

        assertEq(bondAsset.balanceOf(address(umaPriceProvider)), bondAmount);
        assertEq(bondAsset.balanceOf(address(this)), 0);

        umaPriceProvider.withdrawBond();
        assertEq(bondAsset.balanceOf(address(umaPriceProvider)), 0);
        assertEq(bondAsset.balanceOf(address(this)), bondAmount);
    }

    ////////////////////////////////////////////////
    //                FUNCTIONS                  //
    ////////////////////////////////////////////////
    function testConditionOneMetUmaV3Assert() public {
        MockUma mockUma = new MockUma();
        uint256 assertionPrice = 1e18;

        // Deploying new UmaV3PriceProvider
        umaPriceProvider = new UmaV3PriceProvider(
            UMA_DECIMALS,
            UMA_DESCRIPTION,
            ASSERTION_DESCRIPTION,
            TIME_OUT,
            address(mockUma),
            WETH_ADDRESS,
            REQUIRED_BOND
        );
        umaPriceProvider.updateRelayer(address(this));

        // Configuring the assertionInfo
        deal(WETH_ADDRESS, address(this), 1e18);
        wethAsset.approve(address(umaPriceProvider), 1e18);

        vm.expectEmit(true, false, false, true);
        emit MarketAsserted(marketId, bytes32(abi.encode(0x12)));
        bytes32 _assertionId = umaPriceProvider.updateAssertionDataAndFetch(
            assertionPrice,
            marketId
        );

        // Checking assertion links to marketId
        assertEq(wethAsset.balanceOf(address(mockUma)), 1e6);

        // Checking marketId info is correct
        (
            bool activeAssertion,
            uint128 updatedAt,
            uint256 answer,
            bytes32 assertionIdReturned
        ) = umaPriceProvider.globalAnswer();
        assertEq(activeAssertion, true);
        assertEq(updatedAt, uint128(0));
        assertEq(answer, 0);
        assertEq(assertionIdReturned, _assertionId);

        vm.expectEmit(true, false, false, true);
        emit AssertionResolved(_assertionId, true);
        mockUma.assertionResolvedCallback(
            address(umaPriceProvider),
            _assertionId,
            true
        );

        // Checking resolved callback info
        (
            activeAssertion,
            updatedAt,
            answer,
            assertionIdReturned
        ) = umaPriceProvider.globalAnswer();
        assertEq(activeAssertion, false);
        assertEq(updatedAt, uint128(block.timestamp));
        assertEq(answer, assertionPrice);

        uint256 strikePrice = 1000000000000001;
        (bool condition, int256 price) = umaPriceProvider.conditionMet(
            strikePrice,
            marketId
        );
        assertEq(price, int256(assertionPrice));
        assertEq(condition, true);
    }

    function testConditionTwoMetUmaV3Assert() public {
        MockUma mockUma = new MockUma();
        uint256 assertionPrice = 1e18;

        // Deploying new UmaV3PriceProvider
        umaPriceProvider = new UmaV3PriceProvider(
            UMA_DECIMALS,
            UMA_DESCRIPTION,
            ASSERTION_DESCRIPTION,
            TIME_OUT,
            address(mockUma),
            WETH_ADDRESS,
            REQUIRED_BOND
        );
        umaPriceProvider.updateRelayer(address(this));

        // Configuring the assertionInfo
        deal(WETH_ADDRESS, address(this), 1e18);
        wethAsset.approve(address(umaPriceProvider), 1e18);
        bytes32 _assertionId = umaPriceProvider.updateAssertionDataAndFetch(
            assertionPrice,
            marketId
        );
        mockUma.assertionResolvedCallback(
            address(umaPriceProvider),
            _assertionId,
            true
        );

        (bool condition, int256 price) = umaPriceProvider.conditionMet(
            2 ether,
            marketId
        );
        assertEq(price, int256(assertionPrice));
        assertEq(condition, true);
    }

    function testCheckAssertionTrue() public {
        MockUma mockUma = new MockUma();
        uint256 assertionPrice = 1e18;

        // Deploying new UmaV3PriceProvider
        umaPriceProvider = new UmaV3PriceProvider(
            UMA_DECIMALS,
            UMA_DESCRIPTION,
            ASSERTION_DESCRIPTION,
            TIME_OUT,
            address(mockUma),
            WETH_ADDRESS,
            REQUIRED_BOND
        );
        umaPriceProvider.updateRelayer(address(this));

        // Configuring the assertionInfo
        deal(WETH_ADDRESS, address(this), 1e18);
        wethAsset.approve(address(umaPriceProvider), 1e18);
        bytes32 _assertionId = umaPriceProvider.updateAssertionDataAndFetch(
            assertionPrice,
            marketId
        );
        mockUma.assertionResolvedCallback(
            address(umaPriceProvider),
            _assertionId,
            true
        );

        int256 price = umaPriceProvider.getLatestPrice();
        assertEq(price, int256(assertionPrice));
    }

    function testCheckAssertionFalse() public {
        MockUma mockUma = new MockUma();
        uint256 assertionPrice = 1e18;

        // Deploying new UmaV3PriceProvider
        umaPriceProvider = new UmaV3PriceProvider(
            UMA_DECIMALS,
            UMA_DESCRIPTION,
            ASSERTION_DESCRIPTION,
            TIME_OUT,
            address(mockUma),
            WETH_ADDRESS,
            REQUIRED_BOND
        );
        umaPriceProvider.updateRelayer(address(this));

        // Configuring the assertionInfo
        deal(WETH_ADDRESS, address(this), 1e18);
        wethAsset.approve(address(umaPriceProvider), 1e18);
        bytes32 _assertionId = umaPriceProvider.updateAssertionDataAndFetch(
            assertionPrice,
            marketId
        );
        mockUma.assertionResolvedCallback(
            address(umaPriceProvider),
            _assertionId,
            false
        );

        int256 price = umaPriceProvider.getLatestPrice();
        assertEq(price, 0);
    }

    function testFetchAssertionWithBalance() public {
        MockUma mockUma = new MockUma();
        uint256 assertionPrice = 1e18;

        // Deploying new UmaV3PriceProvider
        umaPriceProvider = new UmaV3PriceProvider(
            UMA_DECIMALS,
            UMA_DESCRIPTION,
            ASSERTION_DESCRIPTION,
            TIME_OUT,
            address(mockUma),
            WETH_ADDRESS,
            REQUIRED_BOND
        );
        umaPriceProvider.updateRelayer(address(this));

        // Configuring the assertionInfo
        deal(WETH_ADDRESS, address(umaPriceProvider), 1e18);
        uint256 umaProviderBal = wethAsset.balanceOf(address(umaPriceProvider));
        uint256 senderBal = wethAsset.balanceOf(address(this));
        assertEq(umaProviderBal, 1e18);
        assertEq(senderBal, 0);

        // Querying for assertion
        vm.warp(block.timestamp + 2 days);
        umaPriceProvider.updateAssertionDataAndFetch(assertionPrice, marketId);

        // Checking umaPriceProvide balance declined
        assertEq(
            wethAsset.balanceOf(address(umaPriceProvider)),
            umaProviderBal - REQUIRED_BOND
        );
        assertEq(wethAsset.balanceOf(address(this)), 0);
    }

    ////////////////////////////////////////////////
    //              REVERT CASES                  //
    ////////////////////////////////////////////////
    function testRevertConstructorInputsUma() public {
        vm.expectRevert(UmaV3PriceProvider.InvalidInput.selector);
        new UmaV3PriceProvider(
            0,
            UMA_DESCRIPTION,
            ASSERTION_DESCRIPTION,
            TIME_OUT,
            UMA_OO_V3,
            WETH_ADDRESS,
            REQUIRED_BOND
        );

        vm.expectRevert(UmaV3PriceProvider.InvalidInput.selector);
        new UmaV3PriceProvider(
            UMA_DECIMALS,
            string(""),
            ASSERTION_DESCRIPTION,
            TIME_OUT,
            UMA_OO_V3,
            WETH_ADDRESS,
            REQUIRED_BOND
        );

        vm.expectRevert(UmaV3PriceProvider.InvalidInput.selector);
        new UmaV3PriceProvider(
            UMA_DECIMALS,
            UMA_DESCRIPTION,
            ASSERTION_DESCRIPTION,
            0,
            UMA_OO_V3,
            WETH_ADDRESS,
            REQUIRED_BOND
        );

        vm.expectRevert(UmaV3PriceProvider.InvalidInput.selector);
        new UmaV3PriceProvider(
            UMA_DECIMALS,
            UMA_DESCRIPTION,
            string(""),
            TIME_OUT,
            UMA_OO_V3,
            WETH_ADDRESS,
            REQUIRED_BOND
        );

        vm.expectRevert(UmaV3PriceProvider.ZeroAddress.selector);
        new UmaV3PriceProvider(
            UMA_DECIMALS,
            UMA_DESCRIPTION,
            ASSERTION_DESCRIPTION,
            TIME_OUT,
            address(0),
            WETH_ADDRESS,
            REQUIRED_BOND
        );

        vm.expectRevert(UmaV3PriceProvider.ZeroAddress.selector);
        new UmaV3PriceProvider(
            UMA_DECIMALS,
            UMA_DESCRIPTION,
            ASSERTION_DESCRIPTION,
            TIME_OUT,
            UMA_OO_V3,
            address(0),
            REQUIRED_BOND
        );

        vm.expectRevert(UmaV3PriceProvider.InvalidInput.selector);
        new UmaV3PriceProvider(
            UMA_DECIMALS,
            UMA_DESCRIPTION,
            ASSERTION_DESCRIPTION,
            TIME_OUT,
            UMA_OO_V3,
            WETH_ADDRESS,
            0
        );
    }

    function testRevertInvalidInpudRequiredBond() public {
        vm.expectRevert(UmaV3PriceProvider.InvalidInput.selector);
        umaPriceProvider.updateRequiredBond(0);
    }

    function testRevertInvalidInputUpdateRelayer() public {
        vm.expectRevert(UmaV3PriceProvider.ZeroAddress.selector);
        umaPriceProvider.updateRelayer(address(0));
    }

    function testRevertInvalidCallerCallback() public {
        vm.expectRevert(UmaV3PriceProvider.InvalidCaller.selector);
        umaPriceProvider.assertionResolvedCallback(bytes32(""), true);
    }

    function testRevertAssertionInactive() public {
        vm.prank(UMA_OO_V3);

        vm.expectRevert(UmaV3PriceProvider.AssertionInactive.selector);
        umaPriceProvider.assertionResolvedCallback(
            bytes32(abi.encode(0x12)),
            true
        );
    }

    function testRevertInvalidInputAssertionData() public {
        vm.expectRevert(UmaV3PriceProvider.InvalidInput.selector);
        umaPriceProvider.updateAssertionDataAndFetch(0, marketId);
    }

    function testRevertAssertionInvalidCaller() public {
        uint256 assertionPrice = 1e18;

        vm.startPrank(address(0x123));
        vm.expectRevert(UmaV3PriceProvider.InvalidCaller.selector);
        umaPriceProvider.updateAssertionDataAndFetch(assertionPrice, marketId);
        vm.stopPrank();
    }

    function testRevertAssertionActiveUpdateDataAndFetch() public {
        MockUma mockUma = new MockUma();
        uint256 assertionPrice = 1e18;

        // Deploying new UmaV3PriceProvider
        umaPriceProvider = new UmaV3PriceProvider(
            UMA_DECIMALS,
            UMA_DESCRIPTION,
            ASSERTION_DESCRIPTION,
            TIME_OUT,
            address(mockUma),
            WETH_ADDRESS,
            REQUIRED_BOND
        );
        umaPriceProvider.updateRelayer(address(this));

        // Configuring the assertionInfo
        deal(WETH_ADDRESS, address(this), 1e18);
        wethAsset.approve(address(umaPriceProvider), 1e18);
        umaPriceProvider.updateAssertionDataAndFetch(assertionPrice, marketId);

        vm.expectRevert(UmaV3PriceProvider.AssertionActive.selector);
        umaPriceProvider.updateAssertionDataAndFetch(assertionPrice, marketId);
    }

    function testRevertCooldownPendingUpdateDataAndFetch() public {
        MockUma mockUma = new MockUma();
        uint256 assertionPrice = 1e18;

        // Deploying new UmaV3PriceProvider
        umaPriceProvider = new UmaV3PriceProvider(
            UMA_DECIMALS,
            UMA_DESCRIPTION,
            ASSERTION_DESCRIPTION,
            TIME_OUT,
            address(mockUma),
            WETH_ADDRESS,
            REQUIRED_BOND
        );
        umaPriceProvider.updateRelayer(address(this));

        // Configuring the assertionInfo
        deal(WETH_ADDRESS, address(this), 1e18);
        wethAsset.approve(address(umaPriceProvider), 1e18);
        bytes32 _assertionId = umaPriceProvider.updateAssertionDataAndFetch(
            assertionPrice,
            marketId
        );
        mockUma.assertionResolvedCallback(
            address(umaPriceProvider),
            _assertionId,
            true
        );

        vm.expectRevert(UmaV3PriceProvider.CooldownPending.selector);
        umaPriceProvider.updateAssertionDataAndFetch(assertionPrice, marketId);
    }

    function testRevertAssertionActiveUmaV3Price() public {
        MockUma mockUma = new MockUma();
        uint256 assertionPrice = 1e18;

        // Deploying new UmaV3PriceProvider
        umaPriceProvider = new UmaV3PriceProvider(
            UMA_DECIMALS,
            UMA_DESCRIPTION,
            ASSERTION_DESCRIPTION,
            TIME_OUT,
            address(mockUma),
            WETH_ADDRESS,
            REQUIRED_BOND
        );
        umaPriceProvider.updateRelayer(address(this));

        // Configuring the assertionInfo
        deal(WETH_ADDRESS, address(this), 1e18);
        wethAsset.approve(address(umaPriceProvider), 1e18);
        bytes32 _assertionId = umaPriceProvider.updateAssertionDataAndFetch(
            assertionPrice,
            marketId
        );
        mockUma.assertionResolvedCallback(
            address(umaPriceProvider),
            _assertionId,
            true
        );

        // Moving time forward to revert
        vm.warp(block.timestamp + TIME_OUT + 1);
        umaPriceProvider.updateAssertionDataAndFetch(assertionPrice, marketId);

        vm.expectRevert(UmaV3PriceProvider.AssertionActive.selector);
        umaPriceProvider.getLatestPrice();
    }

    function testRevertTimeOutLatestPriceUma() public {
        MockUma mockUma = new MockUma();
        uint256 assertionPrice = 1e18;

        // Deploying new UmaV3PriceProvider
        umaPriceProvider = new UmaV3PriceProvider(
            UMA_DECIMALS,
            UMA_DESCRIPTION,
            ASSERTION_DESCRIPTION,
            TIME_OUT,
            address(mockUma),
            WETH_ADDRESS,
            REQUIRED_BOND
        );
        umaPriceProvider.updateRelayer(address(this));

        // Configuring the assertionInfo
        deal(WETH_ADDRESS, address(this), 1e18);
        wethAsset.approve(address(umaPriceProvider), 1e18);
        bytes32 _assertionId = umaPriceProvider.updateAssertionDataAndFetch(
            assertionPrice,
            marketId
        );
        mockUma.assertionResolvedCallback(
            address(umaPriceProvider),
            _assertionId,
            true
        );

        // Moving time forward to revert
        vm.warp(block.timestamp + TIME_OUT + 1);
        vm.expectRevert(UmaV3PriceProvider.PriceTimedOut.selector);
        umaPriceProvider.getLatestPrice();
    }
}
