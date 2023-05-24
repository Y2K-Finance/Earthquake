// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "./MintableToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {VaultFactoryV2} from "../../src/v2/VaultFactoryV2.sol";
import {VaultV2} from "../../src/v2/VaultV2.sol";
import {TimeLock} from "../../src/v2/TimeLock.sol";
import {
    ControllerGenericV2
} from "../../src/v2/Controllers/ControllerGenericV2.sol";
import {
    ChainlinkPriceProvider
} from "../../src/v2/Controllers/ChainlinkPriceProvider.sol";
import {
    RedstoneMockPriceProvider,
    RedstonePriceProvider
} from "../../src/v2/Controllers/RedstoneMockPriceProvider.sol";
import {
    IConditionProvider
} from "../../src/v2/Controllers/IConditionProvider.sol";
import {FixedPointMathLib} from "@solmate/utils/FixedPointMathLib.sol";
import {IPriceFeedAdapter} from "../../src/v2/Interfaces/IPriceFeedAdapter.sol";

contract Helper is Test {
    uint256 public constant STRIKE = 1000000000000000000;
    uint256 public constant COLLATERAL_MINUS_FEES = 21989999998398551453;
    uint256 public constant COLLATERAL_MINUS_FEES_DIV10 = 2198999999839855145;
    uint256 public constant NEXT_COLLATERAL_MINUS_FEES = 21827317001456829250;
    uint256 public constant USER1_EMISSIONS_AFTER_WITHDRAW =
        1099999999999999999749;
    uint256 public constant USER2_EMISSIONS_AFTER_WITHDRAW =
        99999999999999999749;
    uint256 public constant USER_AMOUNT_AFTER_WITHDRAW = 13112658495641799945;
    address public constant ADMIN = address(0x1);
    address public constant WETH = address(0x888);
    address public constant TREASURY = address(0x777);
    address public constant NOTADMIN = address(0x99);
    address public constant USER = 0xCCA23C05a9Cf7e78830F3fd55b1e8CfCCbc5E50F;
    address public constant USER2 = address(0x12312);
    address public constant ARBITRUM_SEQUENCER =
        0xFdB631F5EE196F0ed6FAa767959853A9F217697D;
    address public constant USDC_CHAINLINK =
        0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3;
    address public constant USDC_TOKEN =
        0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address public constant PRICE_FEED_ADAPTER = address(0x123);
    address public constant PRICE_FEED_ADAPTER_GOERLI =
        0x449F0bC26B7Ad7b48DA2674Fb4030F0e9323b466;
    bytes32 public constant DATA_FEED_ID =
        0x5653540000000000000000000000000000000000000000000000000000000000;
    address public constant RELAYER = address(0x55);
    address public UNDERLYING = address(0x123);
    address public TOKEN = address(new MintableToken("Token", "TKN"));
    // keeper variables
    address public ops = 0xB3f5503f93d5Ef84b06993a1975B9D21B962892F;
    address public treasuryTask = 0xB2f34fd4C16e656163dADFeEaE4Ae0c1F13b140A;

    uint256 public falseId = 9999999;
}

abstract contract Config is Helper {
    using FixedPointMathLib for uint256;

    VaultFactoryV2 public factory;

    RedstoneMockPriceProvider public redstoneMockProvider;
    ControllerGenericV2 public controller;

    address public premium;
    address public collateral;
    address public oracle;
    address public depegPremium;
    address public depegCollateral;

    uint256 public marketId;
    uint256 public strike;
    uint256 public epochId;
    uint256 public depegMarketId;
    uint256 public depegStrike;
    uint256 public depegEpochId;
    uint256 public premiumShareValue;
    uint256 public collateralShareValue;
    uint256 public arbForkId;
    uint256 public arbGoerliForkId;

    uint256 public constant AMOUNT_AFTER_FEE = 19.95 ether;
    uint256 public constant PREMIUM_DEPOSIT_AMOUNT = 2 ether;
    uint256 public constant COLLAT_DEPOSIT_AMOUNT = 10 ether;
    uint256 public constant DEPOSIT_AMOUNT = 10 ether;
    uint256 public constant DEALT_AMOUNT = 20 ether;

    uint40 public begin;
    uint40 public end;

    uint16 public fee;

    string public ARBITRUM_RPC_URL = vm.envString("ARBITRUM_RPC_URL");
    string public ARBITRUM_GOERLI_RPC_URL =
        vm.envString("ARBITRUM_GOERLI_RPC_URL");

    function setUp() public {
        arbForkId = vm.createFork(ARBITRUM_RPC_URL);
        arbGoerliForkId = vm.createFork(ARBITRUM_GOERLI_RPC_URL);
        _setupFork(1, arbForkId); // 1 = condition below
    }

    function _setupFork(uint256 strikeCondition, uint256 forkId) public {
        vm.selectFork(forkId);

        UNDERLYING = address(new MintableToken("UnderLyingToken", "UTKN"));
        TimeLock timelock = new TimeLock(ADMIN);
        factory = new VaultFactoryV2(WETH, TREASURY, address(timelock));

        address priceFeed = forkId == 0
            ? PRICE_FEED_ADAPTER
            : PRICE_FEED_ADAPTER_GOERLI;
        redstoneMockProvider = new RedstoneMockPriceProvider(
            address(factory),
            priceFeed
        );

        controller = new ControllerGenericV2(address(factory), TREASURY);
        factory.whitelistController(address(controller));

        //create end epoch market
        oracle = address(redstoneMockProvider);
        string memory name = string("USD Coin");
        string memory symbol = string("USDC");

        (premium, collateral, marketId) = factory.createNewMarket(
            VaultFactoryV2.MarketConfigurationCalldata(
                TOKEN,
                strike,
                oracle,
                UNDERLYING,
                name,
                symbol,
                address(controller)
            )
        );

        //create depeg market
        depegStrike = strikeCondition == 1 ? 2 ether : 1;
        int256 strikeInput;
        if (forkId == 1) {
            (, strikeInput, , , ) = IPriceFeedAdapter(priceFeed)
                .latestRoundData();
            if (strikeCondition == 1) {
                depegStrike = uint256(strikeInput) + 1;
            } else if (strikeCondition == 2) {
                depegStrike = uint256(strikeInput) - 1;
            } else {
                depegStrike = uint256(strikeInput);
            }
        }

        address depegToken = forkId == 0 ? USDC_TOKEN : UNDERLYING;
        (depegPremium, depegCollateral, depegMarketId) = factory
            .createNewMarket(
                VaultFactoryV2.MarketConfigurationCalldata(
                    depegToken,
                    depegStrike,
                    oracle,
                    UNDERLYING,
                    name,
                    symbol,
                    address(controller)
                )
            );

        address depegStoredFeed = forkId == 0 ? USDC_CHAINLINK : priceFeed;
        redstoneMockProvider.storePriceFeed(depegMarketId, depegStoredFeed);
        redstoneMockProvider.storeMarket(
            depegToken,
            depegMarketId,
            strikeCondition
        );

        //create epoch for end epoch
        begin = uint40(block.timestamp - 5 days);
        end = uint40(block.timestamp - 3 days);
        fee = 50; // 0.5%

        (epochId, ) = factory.createEpoch(marketId, begin, end, fee);

        //create epoch for depeg
        (depegEpochId, ) = factory.createEpoch(depegMarketId, begin, end, fee);
        MintableToken(UNDERLYING).mint(USER);
    }

    // TODO: If 10 was input then x would be returned ...
    function helperCalculateFeeAdjustedValue(
        uint256 _amount,
        uint16 _fee
    ) internal pure returns (uint256) {
        return _amount - _amount.mulDivUp(_fee, 10000);
    }

    function configureEndEpochState() public {
        vm.warp(begin - 1 days);

        //deal ether
        vm.deal(USER, DEALT_AMOUNT);

        //approve gov token
        MintableToken(UNDERLYING).approve(premium, DEPOSIT_AMOUNT);
        MintableToken(UNDERLYING).approve(collateral, DEPOSIT_AMOUNT);

        //deposit in both vaults
        VaultV2(premium).deposit(epochId, DEPOSIT_AMOUNT, USER);
        VaultV2(collateral).deposit(epochId, DEPOSIT_AMOUNT, USER);

        //check deposit balances
        assertEq(VaultV2(premium).balanceOf(USER, epochId), DEPOSIT_AMOUNT);
        assertEq(VaultV2(collateral).balanceOf(USER, epochId), DEPOSIT_AMOUNT);

        //check user underlying balance
        assertEq(USER.balance, DEALT_AMOUNT);

        //warp to epoch end
        vm.warp(end + 1 days);
    }

    function configureDepegState() public {
        vm.warp(begin - 1 days);
        //deal ether
        vm.deal(USER, DEALT_AMOUNT);

        //approve gov token
        MintableToken(UNDERLYING).approve(depegPremium, PREMIUM_DEPOSIT_AMOUNT);
        MintableToken(UNDERLYING).approve(
            depegCollateral,
            COLLAT_DEPOSIT_AMOUNT
        );

        //deposit in both vaults
        VaultV2(depegPremium).deposit(
            depegEpochId,
            PREMIUM_DEPOSIT_AMOUNT,
            USER
        );
        VaultV2(depegCollateral).deposit(
            depegEpochId,
            COLLAT_DEPOSIT_AMOUNT,
            USER
        );

        //check deposit balances
        assertEq(
            VaultV2(depegPremium).balanceOf(USER, depegEpochId),
            PREMIUM_DEPOSIT_AMOUNT
        );
        assertEq(
            VaultV2(depegCollateral).balanceOf(USER, depegEpochId),
            COLLAT_DEPOSIT_AMOUNT
        );

        //check user underlying balance
        assertEq(USER.balance, DEALT_AMOUNT);

        //warp to epoch begin
        vm.warp(begin + 1 days);
    }

    function testStateVars_ControllerAndFactory() public {
        assertEq(vm.activeFork(), arbForkId);
        assertEq(factory.treasury(), TREASURY);
        assertEq(factory.WETH(), WETH);
        assertEq(factory.controllers(address(controller)), true);
        assertEq(factory.marketToOracle(marketId), oracle);
        assertEq(factory.marketToOracle(depegMarketId), oracle);

        (
            address tokenMarket,
            uint256 strikeMarket,
            address underlyingAssetMarket
        ) = factory.marketIdInfo(marketId);
        assertEq(factory.marketIdToVaults(marketId, 0), premium); // Fetches premium vault for Market
        assertEq(factory.marketIdToVaults(marketId, 1), collateral); // Fetches collateral vault for Market
        assertEq(tokenMarket, TOKEN);
        assertEq(strikeMarket, strike);
        assertEq(underlyingAssetMarket, UNDERLYING);

        (
            address tokenDepegMarket,
            uint256 strikeDepegMarket,
            address underlyingAssetDepegMarket
        ) = factory.marketIdInfo(depegMarketId);
        assertEq(factory.marketIdToVaults(depegMarketId, 0), depegPremium); // Fetches premium vault for DepegMarket
        assertEq(factory.marketIdToVaults(depegMarketId, 1), depegCollateral); // Fetches collateral vault for DepegMarket
        assertEq(tokenDepegMarket, USDC_TOKEN);
        assertEq(strikeDepegMarket, depegStrike);
        assertEq(underlyingAssetDepegMarket, UNDERLYING);

        assertEq(factory.epochFee(epochId), fee);
        assertEq(factory.epochFee(depegEpochId), fee);
        assertEq(factory.marketIdToEpochs(marketId, 0), epochId);
        assertEq(factory.marketIdToEpochs(depegMarketId, 0), depegEpochId);

        assertEq(controller.admin(), address(this));
        assertEq(controller.treasury(), TREASURY);
        // TODO: Checking the vaultFactory() for controller throws: Error (9322): No matching declaration found after argument-dependent lookup
    }

    function testStateVars_Markets() public {
        VaultV2 premiumMarketVault = VaultV2(
            factory.marketIdToVaults(marketId, 0)
        );
        VaultV2 collateralMarketVault = VaultV2(
            factory.marketIdToVaults(marketId, 1)
        );
        VaultV2 premiumDepegMarketVault = VaultV2(
            factory.marketIdToVaults(depegMarketId, 0)
        );
        VaultV2 collateralDepegMarketVault = VaultV2(
            factory.marketIdToVaults(depegMarketId, 1)
        );

        (
            uint40 epochBegin,
            uint40 epochEnd,
            uint40 epochCreation
        ) = premiumMarketVault.epochConfig(epochId);
        assertEq(premiumMarketVault.token(), TOKEN);
        assertEq(premiumMarketVault.strike(), strike);
        assertEq(premiumMarketVault.factory(), address(factory));
        assertEq(premiumMarketVault.controller(), address(controller));
        assertEq(premiumMarketVault.isWETH(), false);
        assertEq(premiumMarketVault.epochExists(epochId), true);
        assertEq(premiumMarketVault.epochs(0), epochId);
        assertEq(
            premiumMarketVault.counterPartyVault(),
            address(collateralMarketVault)
        );
        assertEq(epochBegin, begin);
        assertEq(epochEnd, end);
        assertEq(epochCreation, block.timestamp);

        (epochBegin, epochEnd, epochCreation) = collateralMarketVault
            .epochConfig(epochId);
        assertEq(collateralMarketVault.token(), TOKEN);
        assertEq(collateralMarketVault.strike(), strike);
        assertEq(collateralMarketVault.factory(), address(factory));
        assertEq(collateralMarketVault.controller(), address(controller));
        assertEq(collateralMarketVault.isWETH(), false);
        assertEq(collateralMarketVault.epochExists(epochId), true);
        assertEq(collateralMarketVault.epochs(0), epochId);
        assertEq(
            collateralMarketVault.counterPartyVault(),
            address(premiumMarketVault)
        );
        assertEq(epochBegin, begin);
        assertEq(epochEnd, end);
        assertEq(epochCreation, block.timestamp);

        (epochBegin, epochEnd, epochCreation) = premiumDepegMarketVault
            .epochConfig(depegEpochId);
        assertEq(premiumDepegMarketVault.token(), USDC_TOKEN);
        assertEq(premiumDepegMarketVault.strike(), depegStrike);
        assertEq(premiumDepegMarketVault.factory(), address(factory));
        assertEq(premiumDepegMarketVault.controller(), address(controller));
        assertEq(premiumDepegMarketVault.isWETH(), false);
        assertEq(premiumDepegMarketVault.epochExists(depegEpochId), true);
        assertEq(premiumDepegMarketVault.epochs(0), depegEpochId);
        assertEq(
            premiumDepegMarketVault.counterPartyVault(),
            address(collateralDepegMarketVault)
        );
        assertEq(epochBegin, begin);
        assertEq(epochEnd, end);
        assertEq(epochCreation, block.timestamp);

        (epochBegin, epochEnd, epochCreation) = collateralDepegMarketVault
            .epochConfig(depegEpochId);
        assertEq(collateralDepegMarketVault.token(), USDC_TOKEN);
        assertEq(collateralDepegMarketVault.strike(), depegStrike);
        assertEq(collateralDepegMarketVault.factory(), address(factory));
        assertEq(collateralDepegMarketVault.controller(), address(controller));
        assertEq(collateralDepegMarketVault.isWETH(), false);
        assertEq(collateralDepegMarketVault.epochExists(depegEpochId), true);
        assertEq(collateralDepegMarketVault.epochs(0), depegEpochId);
        assertEq(
            collateralDepegMarketVault.counterPartyVault(),
            address(premiumDepegMarketVault)
        );
        assertEq(epochBegin, begin);
        assertEq(epochEnd, end);
        assertEq(epochCreation, block.timestamp);
    }

    function testStateVars_RedStone() public {
        assertEq(
            address(redstoneMockProvider.vaultFactory()),
            address(factory)
        );
        assertEq(
            address(redstoneMockProvider.priceFeedAdapter()),
            PRICE_FEED_ADAPTER
        );
        assertEq(
            redstoneMockProvider.marketToPriceFeed(depegMarketId),
            USDC_CHAINLINK
        );
        assertEq(
            redstoneMockProvider.marketToSymbol(depegMarketId),
            bytes32("USDC")
        );
        assertEq(redstoneMockProvider.marketToCondition(depegMarketId), 1);
    }

    function testErrors_RedstoneProvider() public {
        vm.expectRevert(RedstonePriceProvider.ZeroAddress.selector);
        new RedstoneMockPriceProvider(address(0), PRICE_FEED_ADAPTER);

        vm.expectRevert(RedstonePriceProvider.ZeroAddress.selector);
        new RedstoneMockPriceProvider(address(factory), address(0));

        vm.expectRevert(RedstonePriceProvider.InvalidInput.selector);
        redstoneMockProvider.storeMarket(USDC_TOKEN, marketId, 0);

        vm.expectRevert(RedstonePriceProvider.ZeroAddress.selector);
        redstoneMockProvider.storeMarket(address(0), marketId, 1);

        vm.expectRevert(RedstonePriceProvider.SymbolAlreadySet.selector);
        redstoneMockProvider.storeMarket(USDC_TOKEN, depegMarketId, 1);

        vm.expectRevert(); // Revert from symbol not being returned
        redstoneMockProvider.storeMarket(address(123), marketId, 1);

        // TODO: Revert when the symbol length is 0

        vm.expectRevert(RedstonePriceProvider.ZeroAddress.selector);
        redstoneMockProvider.getLatestPrice(falseId);

        vm.expectRevert(RedstonePriceProvider.InvalidInput.selector);
        redstoneMockProvider.stringToBytes32(
            "Long sentence that's very likely to be more than 32 bytes in total"
        );

        RedstonePriceProvider priceProvider = new RedstonePriceProvider(
            address(factory),
            PRICE_FEED_ADAPTER
        );
        vm.expectRevert(RedstonePriceProvider.SymbolNotSet.selector);
        priceProvider.getLatestPrice(falseId);
    }

    function testErrors_GenericEndEpoch() public {
        vm.expectRevert(
            abi.encodePacked(
                ControllerGenericV2.MarketDoesNotExist.selector,
                falseId
            )
        );
        controller.triggerEndEpoch(falseId, epochId);

        vm.expectRevert(ControllerGenericV2.EpochNotExist.selector);
        controller.triggerEndEpoch(marketId, falseId);

        vm.warp(begin + 1 hours);
        vm.expectRevert(ControllerGenericV2.EpochNotExpired.selector);
        controller.triggerEndEpoch(marketId, epochId);

        vm.warp(end + 1 hours);
        vm.startPrank(USER);
        configureEndEpochState();
        vm.stopPrank();

        controller.triggerEndEpoch(marketId, epochId);
        vm.expectRevert(ControllerGenericV2.EpochFinishedAlready.selector);
        controller.triggerEndEpoch(marketId, epochId);
    }

    function testErrors_GenericLiquidateEpoch() public {
        vm.expectRevert(
            abi.encodePacked(
                ControllerGenericV2.MarketDoesNotExist.selector,
                falseId
            )
        );
        controller.triggerLiquidation(falseId, epochId);

        vm.expectRevert(ControllerGenericV2.EpochNotExist.selector);
        controller.triggerLiquidation(marketId, falseId);

        vm.warp(begin - 1 hours);
        vm.expectRevert(ControllerGenericV2.EpochNotStarted.selector);
        controller.triggerLiquidation(depegMarketId, depegEpochId);

        vm.warp(end + 1 hours);
        vm.expectRevert(ControllerGenericV2.EpochExpired.selector);
        controller.triggerLiquidation(depegMarketId, depegEpochId);

        // TODO: Check when the condition isn't met that we revert - need to return diff value for price / diff oracle?
        vm.warp(begin + 1 hours);
        // vm.expectRevert(ControllerGenericV2.ConditionNotMet.selector);
        // controller.triggerLiquidation(depegMarketId, depegEpochId);

        vm.expectRevert(ControllerGenericV2.VaultZeroTVL.selector);
        controller.triggerLiquidation(depegMarketId, depegEpochId);

        vm.startPrank(USER);
        configureDepegState();
        vm.stopPrank();

        controller.triggerLiquidation(depegMarketId, depegEpochId);
        vm.expectRevert(ControllerGenericV2.EpochFinishedAlready.selector);
        controller.triggerLiquidation(depegMarketId, depegEpochId);
    }

    function testErrors_GenericNullEpoch() public {
        vm.expectRevert(
            abi.encodePacked(
                ControllerGenericV2.MarketDoesNotExist.selector,
                falseId
            )
        );
        controller.triggerNullEpoch(falseId, epochId);

        vm.expectRevert(ControllerGenericV2.EpochNotExist.selector);
        controller.triggerNullEpoch(marketId, falseId);

        vm.warp(begin - 1 hours);
        vm.expectRevert(ControllerGenericV2.EpochNotStarted.selector);
        controller.triggerNullEpoch(marketId, epochId);

        vm.startPrank(USER);
        configureEndEpochState();
        vm.stopPrank();

        vm.warp(begin + 1 hours);
        vm.expectRevert(ControllerGenericV2.VaultNotZeroTVL.selector);
        controller.triggerNullEpoch(marketId, epochId);

        vm.warp(end + 1 hours);
        controller.triggerEndEpoch(marketId, epochId);
        vm.expectRevert(ControllerGenericV2.EpochFinishedAlready.selector);
        controller.triggerNullEpoch(marketId, epochId);
    }

    function test_ArbitrumGoerliFork() public {
        vm.selectFork(arbGoerliForkId);
        assertEq(vm.activeFork(), arbGoerliForkId);
        assertEq(
            IPriceFeedAdapter(PRICE_FEED_ADAPTER_GOERLI).dataFeedId(),
            DATA_FEED_ID
        );
    }
}
