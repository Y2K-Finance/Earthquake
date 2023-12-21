// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Helper} from "../../Helper.sol";
import {VaultFactoryV2} from "../../../../src/v2/VaultFactoryV2.sol";
import {
    UmaV3AssertionProvider
} from "../../../../src/v2/oracles/individual/UmaV3AssertionProvider.sol";
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

contract UmaV3AssertionProviderTest is Helper {
    uint256 public arbForkId;
    VaultFactoryV2 public factory;
    UmaV3AssertionProvider public umaPriceProvider;
    uint256 public marketId = 2;
    ERC20 public wethAsset;

    ////////////////////////////////////////////////
    //                HELPERS                     //
    ////////////////////////////////////////////////
    uint256 public constant UMA_DECIMALS = 18;
    address public constant UMA_OO_V3 =
        0xa6147867264374F324524E30C02C331cF28aa879;
    string public constant UMA_DESCRIPTION = "USDC";
    uint256 public constant REQUIRED_BOND = 1e6;

    function setUp() public {
        arbForkId = vm.createFork(ARBITRUM_RPC_URL);
        vm.selectFork(arbForkId);
        wethAsset = ERC20(WETH_ADDRESS);

        address timelock = address(new TimeLock(ADMIN));
        factory = new VaultFactoryV2(WETH, TREASURY, address(timelock));
        umaPriceProvider = new UmaV3AssertionProvider(
            UMA_DESCRIPTION,
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
    function testUmaCreationDynamic() public {
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
        assertEq(umaPriceProvider.description(), UMA_DESCRIPTION);
        (uint256 assertionData, uint256 updatedAt) = umaPriceProvider
            .assertionData();
        assertEq(assertionData, 0);
        assertEq(updatedAt, block.timestamp);
        assertEq(umaPriceProvider.whitelistRelayer(address(this)), true);
    }

    function testUpdateRequiredBond() public {
        uint256 newBond = 1e6;

        vm.expectEmit(true, true, false, false);
        emit BondUpdated(newBond);
        umaPriceProvider.updateRequiredBond(newBond);
        assertEq(umaPriceProvider.requiredBond(), newBond);
    }

    function testSetAssertionDescription() public {
        string memory newDescription = " USDC/USD exchange rate is above";

        vm.expectEmit(true, true, false, false);
        emit DescriptionSet(marketId, newDescription);
        umaPriceProvider.setAssertionDescription(marketId, newDescription);
        assertEq(
            keccak256(
                abi.encodePacked(
                    umaPriceProvider.marketIdToAssertionDescription(marketId)
                )
            ),
            keccak256(abi.encodePacked(newDescription))
        );
    }

    function testUpdateAssertionDataAndFetch() public {
        MockUma mockUma = new MockUma();

        // Deploying new UmaV3AssertionProvider
        umaPriceProvider = new UmaV3AssertionProvider(
            UMA_DESCRIPTION,
            TIME_OUT,
            address(mockUma),
            WETH_ADDRESS,
            REQUIRED_BOND
        );
        string memory newDescription = " USDC/USD exchange rate is above";
        umaPriceProvider.setAssertionDescription(marketId, newDescription);
        umaPriceProvider.updateRelayer(address(this));

        // Configuring the assertionInfo
        deal(WETH_ADDRESS, address(this), 1e18);
        wethAsset.approve(address(umaPriceProvider), 1e18);

        // Moving forward so the constructor data is invalid
        vm.warp(block.timestamp + 2 days);
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

    function testResetMarketAnswerAfterTimeout() public {
        // Setting truthy state and checking is truth
        uint256 customMarketId = 3;
        MockUma mockUma = _stagingTruthyAssertion();

        vm.warp(block.timestamp + 601);
        _stagingTruthyAssertionCustom(customMarketId, mockUma);

        // Checking both markets state set to true
        assertEq(umaPriceProvider.checkAssertion(marketId), true);
        assertEq(umaPriceProvider.checkAssertion(customMarketId), true);

        // Moving timer and resetting answer as timeOut has passed
        uint256[] memory _markets = new uint256[](2);
        _markets[0] = marketId;
        _markets[1] = customMarketId;
        vm.warp(block.timestamp + umaPriceProvider.timeOut() + 1);
        umaPriceProvider.resetAnswerAfterTimeout(_markets);

        // Checking both markets answer is now zero
        assertEq(umaPriceProvider.checkAssertion(marketId), false);
        assertEq(umaPriceProvider.checkAssertion(customMarketId), false);
    }

    ////////////////////////////////////////////////
    //                FUNCTIONS                  //
    ////////////////////////////////////////////////
    function testConditionMetUmaDynamic() public {
        MockUma mockUma = new MockUma();

        // Deploying new UmaV3AssertionProvider
        umaPriceProvider = new UmaV3AssertionProvider(
            UMA_DESCRIPTION,
            TIME_OUT,
            address(mockUma),
            WETH_ADDRESS,
            REQUIRED_BOND
        );
        string memory newDescription = " USDC/USD exchange rate is above";
        umaPriceProvider.setAssertionDescription(marketId, newDescription);
        umaPriceProvider.updateRelayer(address(this));

        // Configuring the assertionInfo
        deal(WETH_ADDRESS, address(this), 1e18);
        wethAsset.approve(address(umaPriceProvider), 1e18);

        // Moving forward so the constructor data is invalid
        vm.warp(block.timestamp + 2 days);
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

        // Checking condition met is true and price is 0
        (bool condition, int256 price) = umaPriceProvider.conditionMet(
            2 ether,
            marketId
        );
        assertTrue(price == 0);
        assertEq(condition, true);
    }

    function testCheckAssertionTrue() public {
        _stagingTruthyAssertion();
        bool condition = umaPriceProvider.checkAssertion(marketId);
        assertEq(condition, true);
    }

    function testCheckAssertionFalse() public {
        vm.warp(block.timestamp + 2 days);
        bool condition = umaPriceProvider.checkAssertion(marketId);
        assertEq(condition, false);
    }

    function testFetchAssertionContractHasBalance() public {
        MockUma mockUma = new MockUma();

        // Deploying new UmaV3AssertionProvider
        umaPriceProvider = new UmaV3AssertionProvider(
            UMA_DESCRIPTION,
            TIME_OUT,
            address(mockUma),
            WETH_ADDRESS,
            REQUIRED_BOND
        );
        string memory newDescription = " USDC/USD exchange rate is above";
        umaPriceProvider.setAssertionDescription(marketId, newDescription);
        umaPriceProvider.updateRelayer(address(this));

        // Configuring the assertionInfo
        deal(WETH_ADDRESS, address(umaPriceProvider), 1e18);
        uint256 umaProviderBal = wethAsset.balanceOf(address(umaPriceProvider));
        uint256 senderBal = wethAsset.balanceOf(address(this));
        assertEq(umaProviderBal, 1e18);
        assertEq(senderBal, 0);

        // Moving forward so the constructor data is invalid
        vm.warp(block.timestamp + 2 days);
        umaPriceProvider.fetchAssertion(marketId);

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
        vm.expectRevert(UmaV3AssertionProvider.InvalidInput.selector);
        new UmaV3AssertionProvider(
            string(""),
            TIME_OUT,
            UMA_OO_V3,
            WETH_ADDRESS,
            REQUIRED_BOND
        );

        vm.expectRevert(UmaV3AssertionProvider.InvalidInput.selector);
        new UmaV3AssertionProvider(
            UMA_DESCRIPTION,
            0,
            UMA_OO_V3,
            WETH_ADDRESS,
            REQUIRED_BOND
        );

        vm.expectRevert(UmaV3AssertionProvider.ZeroAddress.selector);
        new UmaV3AssertionProvider(
            UMA_DESCRIPTION,
            TIME_OUT,
            address(0),
            WETH_ADDRESS,
            REQUIRED_BOND
        );

        vm.expectRevert(UmaV3AssertionProvider.ZeroAddress.selector);
        new UmaV3AssertionProvider(
            UMA_DESCRIPTION,
            TIME_OUT,
            UMA_OO_V3,
            address(0),
            REQUIRED_BOND
        );

        vm.expectRevert(UmaV3AssertionProvider.InvalidInput.selector);
        new UmaV3AssertionProvider(
            UMA_DESCRIPTION,
            TIME_OUT,
            UMA_OO_V3,
            WETH_ADDRESS,
            0
        );
    }

    function testRevertInvalidInputRequiredBond() public {
        vm.expectRevert(UmaV3AssertionProvider.InvalidInput.selector);
        umaPriceProvider.updateRequiredBond(0);
    }

    function testRevertZeroAddressUpdateRelayer() public {
        vm.expectRevert(UmaV3AssertionProvider.ZeroAddress.selector);
        umaPriceProvider.updateRelayer(address(0));
    }

    function testRevertSetAssertionDescription() public {
        string memory newDescription = " USDC/USD exchange rate is above";
        umaPriceProvider.setAssertionDescription(marketId, newDescription);

        vm.expectRevert(UmaV3AssertionProvider.DescriptionAlreadySet.selector);
        umaPriceProvider.setAssertionDescription(marketId, string(""));
    }

    function testRevertInvalidCallerCallback() public {
        vm.expectRevert(UmaV3AssertionProvider.InvalidCaller.selector);
        umaPriceProvider.assertionResolvedCallback(bytes32(""), true);
    }

    function testRevertAssertionInactive() public {
        vm.prank(UMA_OO_V3);

        vm.expectRevert(UmaV3AssertionProvider.AssertionInactive.selector);
        umaPriceProvider.assertionResolvedCallback(
            bytes32(abi.encode(0x12)),
            true
        );
    }

    function testRevertCheckAssertionActive() public {
        MockUma mockUma = new MockUma();

        // Deploying new UmaV3AssertionProvider
        umaPriceProvider = new UmaV3AssertionProvider(
            UMA_DESCRIPTION,
            TIME_OUT,
            address(mockUma),
            WETH_ADDRESS,
            REQUIRED_BOND
        );
        umaPriceProvider.updateRelayer(address(this));

        // Configuring the assertionInfo
        deal(WETH_ADDRESS, address(this), 1e18);
        wethAsset.approve(address(umaPriceProvider), 1e18);
        umaPriceProvider.fetchAssertion(marketId);

        vm.expectRevert(UmaV3AssertionProvider.AssertionActive.selector);
        umaPriceProvider.fetchAssertion(marketId);
    }

    function testRevertFetchAssertionActive() public {
        MockUma mockUma = new MockUma();

        // Deploying new UmaV3AssertionProvider
        umaPriceProvider = new UmaV3AssertionProvider(
            UMA_DESCRIPTION,
            TIME_OUT,
            address(mockUma),
            WETH_ADDRESS,
            REQUIRED_BOND
        );
        umaPriceProvider.updateRelayer(address(this));

        // Configuring the assertionInfo
        deal(WETH_ADDRESS, address(this), 1e18);
        wethAsset.approve(address(umaPriceProvider), 1e18);
        umaPriceProvider.fetchAssertion(marketId);

        vm.expectRevert(UmaV3AssertionProvider.AssertionActive.selector);
        umaPriceProvider.checkAssertion(marketId);
    }

    function testRevertFetchAssertionInvalidCaller() public {
        vm.startPrank(address(0x123));
        vm.expectRevert(UmaV3AssertionProvider.InvalidCaller.selector);
        umaPriceProvider.fetchAssertion(marketId);
        vm.stopPrank();
    }

    function testRevertCooldownPending() public {
        _stagingTruthyAssertion();

        vm.expectRevert(UmaV3AssertionProvider.CooldownPending.selector);
        umaPriceProvider.fetchAssertion(marketId);
    }

    function testRevertPriceTimeOutUma() public {
        _stagingTruthyAssertion();

        vm.warp(block.timestamp + umaPriceProvider.timeOut() + 1);
        vm.expectRevert(UmaV3AssertionProvider.PriceTimedOut.selector);
        umaPriceProvider.checkAssertion(marketId);
    }

    ////////////////////////////////////////////////
    //                  STAGING                  //
    ////////////////////////////////////////////////
    function _stagingTruthyAssertion() internal returns (MockUma mockUma) {
        mockUma = new MockUma();

        // Deploying new UmaV3AssertionProvider
        umaPriceProvider = new UmaV3AssertionProvider(
            UMA_DESCRIPTION,
            TIME_OUT,
            address(mockUma),
            WETH_ADDRESS,
            REQUIRED_BOND
        );
        string memory newDescription = " USDC/USD exchange rate is above";
        umaPriceProvider.setAssertionDescription(marketId, newDescription);
        umaPriceProvider.updateRelayer(address(this));

        // Configuring the assertionInfo
        deal(WETH_ADDRESS, address(this), 1e18);
        wethAsset.approve(address(umaPriceProvider), 1e18);

        // Moving forward so the constructor data is invalid
        vm.warp(block.timestamp + 2 days);
        bytes32 _assertionId = umaPriceProvider.fetchAssertion(marketId);
        mockUma.assertionResolvedCallback(
            address(umaPriceProvider),
            _assertionId,
            true
        );
    }

    function _stagingTruthyAssertionCustom(
        uint256 _marketId,
        MockUma mockUma
    ) internal {
        string memory newDescription = " USDC/USD exchange rate is above";
        umaPriceProvider.setAssertionDescription(_marketId, newDescription);

        // Configuring the assertionInfo
        deal(WETH_ADDRESS, address(this), 1e18);
        wethAsset.approve(address(umaPriceProvider), 1e18);

        // Moving forward so the constructor data is invalid
        bytes32 _assertionId = umaPriceProvider.fetchAssertion(_marketId);
        mockUma.assertionResolvedCallback(
            address(umaPriceProvider),
            _assertionId,
            true
        );
    }
}
