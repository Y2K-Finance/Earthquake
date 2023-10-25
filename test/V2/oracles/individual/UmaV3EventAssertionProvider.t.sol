// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Helper} from "../../Helper.sol";
import {VaultFactoryV2} from "../../../../src/v2/VaultFactoryV2.sol";
import {
    UmaV3EventAssertionProvider
} from "../../../../src/v2/oracles/individual/UmaV3EventAssertionProvider.sol";
import {TimeLock} from "../../../../src/v2/TimeLock.sol";
import {
    MockOracleAnswerZero,
    MockOracleRoundOutdated,
    MockOracleTimeOut
} from "../mocks/MockOracles.sol";
import {MockUma} from "../mocks/MockUma.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";

contract UmaV3EventAssertionProviderTest is Helper {
    uint256 public arbForkId;
    VaultFactoryV2 public factory;
    UmaV3EventAssertionProvider public umaPriceProvider;
    uint256 public marketId = 2;
    ERC20 public wethAsset;

    ////////////////////////////////////////////////
    //                HELPERS                     //
    ////////////////////////////////////////////////
    uint256 public UMA_DECIMALS = 18;
    address public UMA_OO_V3 = address(0x123);
    string public UMA_DESCRIPTION = "USDC";
    uint256 public REQUIRED_BOND = 1e6;
    bytes32 public defaultIdentifier = bytes32("abc");
    bytes public assertionDescription;

    function setUp() public {
        arbForkId = vm.createFork(ARBITRUM_RPC_URL);
        vm.selectFork(arbForkId);
        wethAsset = ERC20(WETH_ADDRESS);

        // TODO: Should this be encoded or encode packed?
        assertionDescription = abi.encode("Curve was hacked");

        address timelock = address(new TimeLock(ADMIN));
        factory = new VaultFactoryV2(WETH, TREASURY, address(timelock));
        umaPriceProvider = new UmaV3EventAssertionProvider(
            UMA_DECIMALS,
            UMA_DESCRIPTION,
            TIME_OUT,
            UMA_OO_V3,
            defaultIdentifier,
            WETH_ADDRESS,
            assertionDescription,
            REQUIRED_BOND
        );

        uint256 condition = 2;
        umaPriceProvider.setConditionType(marketId, condition);
        umaPriceProvider.updateRelayer(address(this));
    }

    ////////////////////////////////////////////////
    //                STATE                       //
    ////////////////////////////////////////////////
    function testUmaCreation() public {
        assertEq(umaPriceProvider.ASSERTION_LIVENESS(), 7200);
        assertEq(umaPriceProvider.currency(), WETH_ADDRESS);
        assertEq(umaPriceProvider.defaultIdentifier(), defaultIdentifier);
        assertEq(address(umaPriceProvider.umaV3()), UMA_OO_V3);
        assertEq(umaPriceProvider.requiredBond(), REQUIRED_BOND);

        assertEq(umaPriceProvider.timeOut(), TIME_OUT);
        assertEq(umaPriceProvider.decimals(), UMA_DECIMALS);
        assertEq(umaPriceProvider.description(), UMA_DESCRIPTION);
        assertEq(umaPriceProvider.assertionDescription(), assertionDescription);

        assertEq(umaPriceProvider.marketIdToConditionType(marketId), 2);
        assertEq(umaPriceProvider.whitelistRelayer(address(this)), true);
    }

    function testUpdateCoverageTime() public {
        umaPriceProvider.updateCoverageStart(block.timestamp * 2);
        assertEq(umaPriceProvider.coverageStart(), block.timestamp * 2);
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

    ////////////////////////////////////////////////
    //                FUNCTIONS                  //
    ////////////////////////////////////////////////
    function testConditionOneMetUma() public {
        MockUma mockUma = new MockUma();

        // Deploying new UmaV3EventAssertionProvider
        umaPriceProvider = new UmaV3EventAssertionProvider(
            UMA_DECIMALS,
            UMA_DESCRIPTION,
            TIME_OUT,
            address(mockUma),
            defaultIdentifier,
            WETH_ADDRESS,
            assertionDescription,
            REQUIRED_BOND
        );
        umaPriceProvider.setConditionType(marketId, 1);
        umaPriceProvider.updateRelayer(address(this));

        // Configuring the assertionInfo
        deal(WETH_ADDRESS, address(this), 1e18);
        wethAsset.approve(address(umaPriceProvider), 1e18);

        vm.expectEmit(true, false, false, true);
        emit MarketAsserted(marketId, bytes32(abi.encode(0x12)));
        bytes32 _assertionId = umaPriceProvider.fetchAssertion(marketId);

        // Checking assertion links to marketId
        uint256 _marketId = umaPriceProvider.assertionIdToMarket(_assertionId);
        assertEq(_marketId, marketId);
        assertEq(wethAsset.balanceOf(address(mockUma)), 1e6);

        // Checking marketId info is correct
        (
            bool activeAssertion,
            uint128 updatedAt,
            uint8 answer,
            bytes32 assertionIdReturned
        ) = umaPriceProvider.marketIdToAnswer(_marketId);
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
        ) = umaPriceProvider.marketIdToAnswer(_marketId);
        assertEq(activeAssertion, false);
        assertEq(updatedAt, uint128(block.timestamp));
        assertEq(answer, 1);

        (bool condition, int256 price) = umaPriceProvider.conditionMet(
            2 ether,
            marketId
        );
        assertTrue(price == 0);
        assertEq(condition, true);
    }

    function testConditionTwoMetUma() public {
        MockUma mockUma = new MockUma();

        // Deploying new UmaV3EventAssertionProvider
        umaPriceProvider = new UmaV3EventAssertionProvider(
            UMA_DECIMALS,
            UMA_DESCRIPTION,
            TIME_OUT,
            address(mockUma),
            defaultIdentifier,
            WETH_ADDRESS,
            assertionDescription,
            REQUIRED_BOND
        );
        umaPriceProvider.setConditionType(marketId, 2);
        umaPriceProvider.updateRelayer(address(this));

        // Configuring the assertionInfo
        deal(WETH_ADDRESS, address(this), 1e18);
        wethAsset.approve(address(umaPriceProvider), 1e18);
        bytes32 _assertionId = umaPriceProvider.fetchAssertion(marketId);
        mockUma.assertionResolvedCallback(
            address(umaPriceProvider),
            _assertionId,
            true
        );

        (bool condition, int256 price) = umaPriceProvider.conditionMet(
            2 ether,
            marketId
        );
        assertTrue(price == 0);
        assertEq(condition, true);
    }

    function testCheckAssertionTrue() public {
        MockUma mockUma = new MockUma();

        // Deploying new UmaV3EventAssertionProvider
        umaPriceProvider = new UmaV3EventAssertionProvider(
            UMA_DECIMALS,
            UMA_DESCRIPTION,
            TIME_OUT,
            address(mockUma),
            defaultIdentifier,
            WETH_ADDRESS,
            assertionDescription,
            REQUIRED_BOND
        );
        umaPriceProvider.setConditionType(marketId, 2);
        umaPriceProvider.updateRelayer(address(this));

        // Configuring the assertionInfo
        deal(WETH_ADDRESS, address(this), 1e18);
        wethAsset.approve(address(umaPriceProvider), 1e18);
        bytes32 _assertionId = umaPriceProvider.fetchAssertion(marketId);
        mockUma.assertionResolvedCallback(
            address(umaPriceProvider),
            _assertionId,
            true
        );

        bool condition = umaPriceProvider.checkAssertion(marketId);
        assertEq(condition, true);
    }

    function testCheckAssertionFalse() public {
        MockUma mockUma = new MockUma();

        // Deploying new UmaV3EventAssertionProvider
        umaPriceProvider = new UmaV3EventAssertionProvider(
            UMA_DECIMALS,
            UMA_DESCRIPTION,
            TIME_OUT,
            address(mockUma),
            defaultIdentifier,
            WETH_ADDRESS,
            assertionDescription,
            REQUIRED_BOND
        );
        umaPriceProvider.setConditionType(marketId, 2);
        umaPriceProvider.updateRelayer(address(this));

        // Configuring the assertionInfo
        deal(WETH_ADDRESS, address(this), 1e18);
        wethAsset.approve(address(umaPriceProvider), 1e18);
        bytes32 _assertionId = umaPriceProvider.fetchAssertion(marketId);
        mockUma.assertionResolvedCallback(
            address(umaPriceProvider),
            _assertionId,
            false
        );

        bool condition = umaPriceProvider.checkAssertion(marketId);
        assertEq(condition, false);
    }

    ////////////////////////////////////////////////
    //              REVERT CASES                  //
    ////////////////////////////////////////////////
    function testRevertConstructorInputsUma() public {
        vm.expectRevert(UmaV3EventAssertionProvider.InvalidInput.selector);
        new UmaV3EventAssertionProvider(
            0,
            UMA_DESCRIPTION,
            TIME_OUT,
            UMA_OO_V3,
            defaultIdentifier,
            WETH_ADDRESS,
            assertionDescription,
            REQUIRED_BOND
        );

        vm.expectRevert(UmaV3EventAssertionProvider.InvalidInput.selector);
        new UmaV3EventAssertionProvider(
            UMA_DECIMALS,
            string(""),
            TIME_OUT,
            UMA_OO_V3,
            defaultIdentifier,
            WETH_ADDRESS,
            assertionDescription,
            REQUIRED_BOND
        );

        vm.expectRevert(UmaV3EventAssertionProvider.InvalidInput.selector);
        new UmaV3EventAssertionProvider(
            UMA_DECIMALS,
            UMA_DESCRIPTION,
            0,
            UMA_OO_V3,
            defaultIdentifier,
            WETH_ADDRESS,
            assertionDescription,
            REQUIRED_BOND
        );

        vm.expectRevert(UmaV3EventAssertionProvider.ZeroAddress.selector);
        new UmaV3EventAssertionProvider(
            UMA_DECIMALS,
            UMA_DESCRIPTION,
            TIME_OUT,
            address(0),
            defaultIdentifier,
            WETH_ADDRESS,
            assertionDescription,
            REQUIRED_BOND
        );

        vm.expectRevert(UmaV3EventAssertionProvider.InvalidInput.selector);
        new UmaV3EventAssertionProvider(
            UMA_DECIMALS,
            UMA_DESCRIPTION,
            TIME_OUT,
            UMA_OO_V3,
            bytes32(""),
            WETH_ADDRESS,
            assertionDescription,
            REQUIRED_BOND
        );

        vm.expectRevert(UmaV3EventAssertionProvider.ZeroAddress.selector);
        new UmaV3EventAssertionProvider(
            UMA_DECIMALS,
            UMA_DESCRIPTION,
            TIME_OUT,
            UMA_OO_V3,
            defaultIdentifier,
            address(0),
            assertionDescription,
            REQUIRED_BOND
        );

        vm.expectRevert(UmaV3EventAssertionProvider.InvalidInput.selector);
        new UmaV3EventAssertionProvider(
            UMA_DECIMALS,
            UMA_DESCRIPTION,
            TIME_OUT,
            UMA_OO_V3,
            defaultIdentifier,
            WETH_ADDRESS,
            bytes(""),
            REQUIRED_BOND
        );

        vm.expectRevert(UmaV3EventAssertionProvider.InvalidInput.selector);
        new UmaV3EventAssertionProvider(
            UMA_DECIMALS,
            UMA_DESCRIPTION,
            TIME_OUT,
            UMA_OO_V3,
            defaultIdentifier,
            WETH_ADDRESS,
            assertionDescription,
            0
        );
    }

    function testRevertConditionTypeSetUma() public {
        vm.expectRevert(UmaV3EventAssertionProvider.ConditionTypeSet.selector);
        umaPriceProvider.setConditionType(2, 0);
    }

    function testRevertInvalidInputConditionUma() public {
        vm.expectRevert(UmaV3EventAssertionProvider.InvalidInput.selector);
        umaPriceProvider.setConditionType(0, 0);

        vm.expectRevert(UmaV3EventAssertionProvider.InvalidInput.selector);
        umaPriceProvider.setConditionType(0, 3);
    }

    function testRevertInvalidInputUpdateCoverageStart() public {
        vm.expectRevert(UmaV3EventAssertionProvider.InvalidInput.selector);
        umaPriceProvider.updateCoverageStart(0);
    }

    function testRevertInvalidInputRequiredBond() public {
        vm.expectRevert(UmaV3EventAssertionProvider.InvalidInput.selector);
        umaPriceProvider.updateRequiredBond(0);
    }

    function testRevertZeroAddressUpdateRelayer() public {
        vm.expectRevert(UmaV3EventAssertionProvider.ZeroAddress.selector);
        umaPriceProvider.updateRelayer(address(0));
    }

    function testRevertInvalidCallerCallback() public {
        vm.expectRevert(UmaV3EventAssertionProvider.InvalidCaller.selector);
        umaPriceProvider.assertionResolvedCallback(bytes32(""), true);
    }

    function testRevertAssertionInactive() public {
        vm.prank(UMA_OO_V3);

        vm.expectRevert(UmaV3EventAssertionProvider.AssertionInactive.selector);
        umaPriceProvider.assertionResolvedCallback(
            bytes32(abi.encode(0x12)),
            true
        );
    }

    function testRevertFetchAssertionZeroInvalidCaller() public {
        vm.startPrank(address(0x123));
        vm.expectRevert(UmaV3EventAssertionProvider.InvalidCaller.selector);
        umaPriceProvider.fetchAssertion(marketId);
        vm.stopPrank();
    }

    function testRevertAssertionActive() public {
        MockUma mockUma = new MockUma();

        // Deploying new UmaV3EventAssertionProvider
        umaPriceProvider = new UmaV3EventAssertionProvider(
            UMA_DECIMALS,
            UMA_DESCRIPTION,
            TIME_OUT,
            address(mockUma),
            defaultIdentifier,
            WETH_ADDRESS,
            assertionDescription,
            REQUIRED_BOND
        );
        umaPriceProvider.setConditionType(marketId, 1);
        umaPriceProvider.updateRelayer(address(this));

        // Configuring the assertionInfo
        deal(WETH_ADDRESS, address(this), 1e18);
        wethAsset.approve(address(umaPriceProvider), 1e18);
        umaPriceProvider.fetchAssertion(marketId);

        vm.expectRevert(UmaV3EventAssertionProvider.AssertionActive.selector);
        umaPriceProvider.fetchAssertion(marketId);
    }

    function testRevertTimeOutUma() public {
        umaPriceProvider = new UmaV3EventAssertionProvider(
            UMA_DECIMALS,
            UMA_DESCRIPTION,
            TIME_OUT,
            UMA_OO_V3,
            defaultIdentifier,
            WETH_ADDRESS,
            assertionDescription,
            REQUIRED_BOND
        );
        vm.expectRevert(UmaV3EventAssertionProvider.PriceTimedOut.selector);
        umaPriceProvider.checkAssertion(123);
    }
}
