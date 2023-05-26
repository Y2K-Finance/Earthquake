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
    RedstonePriceProvider
} from "../../src/v2/Controllers/RedstonePriceProvider.sol";
import {
    MockOracleAnswerZero,
    MockOracleAnswerOne,
    MockOracleGracePeriod,
    MockOracleRoundOutdated,
    MockOracleConditionNotMet,
    MockOracleConditionMet,
    MockOracleTimeOut
} from "./MockOracles.sol";
import {
    IConditionProvider
} from "../../src/v2/Controllers/IConditionProvider.sol";
import {FixedPointMathLib} from "@solmate/utils/FixedPointMathLib.sol";
import {IPriceFeedAdapter} from "../../src/v2/Interfaces/IPriceFeedAdapter.sol";

interface IRedstonePrice {
    function getValueForDataFeed(bytes32) external view returns (uint256);
}

contract Helper is Test {
    uint256 public constant TIME_OUT = 3600;
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
    address public constant PRICE_FEED_GOERLI =
        0x449F0bC26B7Ad7b48DA2674Fb4030F0e9323b466;
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

    event MarketStored(uint256 marketId, uint256 condition);
    event MarketStored(address token, uint256 marketId, uint256 condition);
    event PriceFeedStored(address priceFeed, uint256 marketId);
    event EpochResolved(
        uint256 indexed epochId,
        uint256 indexed marketId,
        ControllerGenericV2.VaultTVL tvl,
        bool strikeMet,
        uint256 time,
        int256 depegPrice
    );
    event NullEpoch(
        uint256 indexed epochId,
        uint256 indexed marketId,
        ControllerGenericV2.VaultTVL tvl,
        uint256 time
    );
}

abstract contract Config is Helper {
    using FixedPointMathLib for uint256;

    VaultFactoryV2 public factory;

    RedstonePriceProvider public redstoneProviderGoerli;
    RedstonePriceProvider public redstoneProviderArbitrum;
    ChainlinkPriceProvider public chainlinkPriceProvider;
    ControllerGenericV2 public controller;
    TimeLock public timelock;

    address public premium;
    address public collateral;
    address public oracle;
    address public depegPremium;
    address public depegCollateral;
    address public depegPremiumChainlink;
    address public depegCollateralChainlink;

    uint256 public marketId;
    uint256 public strike;
    uint256 public epochId;
    uint256 public depegMarketId;
    uint256 public depegStrike;
    uint256 public depegEpochId;
    uint256 public depegMarketIdChainlink;
    uint256 public depegStrikeChainlink;
    uint256 public depegEpochIdChainlink;

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
    uint40 public beginChainlink;
    uint40 public endChainlink;

    uint16 public fee;

    string public ARBITRUM_RPC_URL = vm.envString("ARBITRUM_RPC_URL");
    string public ARBITRUM_GOERLI_RPC_URL =
        vm.envString("ARBITRUM_GOERLI_RPC_URL");

    function setUp() public {
        arbForkId = vm.createFork(ARBITRUM_RPC_URL);
        arbGoerliForkId = vm.createFork(ARBITRUM_GOERLI_RPC_URL);
        _setupFork(arbForkId);
    }

    function _setupFork(uint256 forkId) public {
        vm.selectFork(forkId);

        UNDERLYING = address(new MintableToken("Vesta Token", "VST"));
        timelock = new TimeLock(ADMIN);
        factory = new VaultFactoryV2(WETH, TREASURY, address(timelock));

        // create price providers
        address priceFeed = forkId == 0 ? USDC_CHAINLINK : PRICE_FEED_GOERLI;
        redstoneProviderArbitrum = new RedstonePriceProvider(
            address(factory),
            priceFeed,
            "USDC"
        );

        redstoneProviderGoerli = new RedstonePriceProvider(
            address(factory),
            PRICE_FEED_ADAPTER_GOERLI,
            "VST"
        );

        chainlinkPriceProvider = new ChainlinkPriceProvider(
            ARBITRUM_SEQUENCER,
            address(factory),
            USDC_CHAINLINK
        );

        controller = new ControllerGenericV2(address(factory), TREASURY);
        factory.whitelistController(address(controller));

        //create end epoch market
        oracle = forkId == 0
            ? address(redstoneProviderArbitrum)
            : address(redstoneProviderGoerli);
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
        depegStrike = 2 ether;
        int256 strikeInput;
        if (forkId == 1) {
            (, strikeInput, , , ) = IPriceFeedAdapter(priceFeed)
                .latestRoundData();
            depegStrike = uint256(strikeInput) + 1;
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

        depegStrikeChainlink = 3 ether;
        (
            depegPremiumChainlink,
            depegCollateralChainlink,
            depegMarketIdChainlink
        ) = factory.createNewMarket(
            VaultFactoryV2.MarketConfigurationCalldata(
                depegToken,
                depegStrikeChainlink,
                address(chainlinkPriceProvider),
                UNDERLYING,
                name,
                symbol,
                address(controller)
            )
        );

        //create epoch for end epoch
        begin = uint40(block.timestamp - 5 days);
        end = uint40(block.timestamp - 3 days);
        fee = 50; // 0.5%

        (epochId, ) = factory.createEpoch(marketId, begin, end, fee);

        //create epoch for depeg
        (depegEpochId, ) = factory.createEpoch(depegMarketId, begin, end, fee);

        // sets begin based on updatedAt if on ArbFork to ensure
        beginChainlink = begin;
        endChainlink = end;
        if (forkId == 0) {
            (, , , uint256 updatedAt, ) = IPriceFeedAdapter(USDC_CHAINLINK)
                .latestRoundData();
            // depeg test runs at begin + 1 hours to avoid TIME_OUT reverts from oracle
            beginChainlink = uint40(updatedAt);
            endChainlink = uint40(updatedAt + 3 days);
        }
        (depegEpochIdChainlink, ) = factory.createEpoch(
            depegMarketIdChainlink,
            beginChainlink,
            endChainlink,
            fee
        );
        MintableToken(UNDERLYING).mint(USER);
    }

    function testStateVars_ControllerAndFactory() public {
        assertEq(vm.activeFork(), arbForkId);
        assertEq(factory.WETH(), WETH);
        assertEq(factory.treasury(), TREASURY);
        assertEq(factory.timelocker(), address(timelock));
        assertEq(factory.controllers(address(controller)), true);

        (
            address tokenMarket,
            uint256 strikeMarket,
            address underlyingAssetMarket
        ) = factory.marketIdInfo(marketId);
        assertEq(factory.marketIdToVaults(marketId, 0), premium); // Fetches premium vault for Market
        assertEq(factory.marketIdToVaults(marketId, 1), collateral); // Fetches collateral vault for Market
        assertEq(factory.marketIdToEpochs(marketId, 0), epochId);
        assertEq(factory.marketIdToEpochs(depegMarketId, 0), depegEpochId);
        assertEq(tokenMarket, TOKEN);
        assertEq(strikeMarket, strike);
        assertEq(underlyingAssetMarket, UNDERLYING);
        assertEq(factory.epochFee(epochId), fee);
        assertEq(factory.marketToOracle(marketId), oracle);
        assertEq(factory.controllers(address(controller)), true);

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
        assertEq(factory.epochFee(depegEpochId), fee);
        assertEq(factory.marketToOracle(depegMarketId), oracle);
        assertEq(controller.admin(), address(this));
        assertEq(controller.treasury(), TREASURY);
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
        assertEq(premiumMarketVault.isWETH(), false);
        assertEq(
            premiumMarketVault.counterPartyVault(),
            address(collateralMarketVault)
        );
        assertEq(premiumMarketVault.factory(), address(factory));
        assertEq(premiumMarketVault.controller(), address(controller));
        assertEq(premiumMarketVault.epochs(0), epochId);
        assertEq(premiumMarketVault.epochExists(epochId), true);
        assertEq(epochBegin, begin);
        assertEq(epochEnd, end);
        assertEq(epochCreation, block.timestamp);

        (epochBegin, epochEnd, epochCreation) = collateralMarketVault
            .epochConfig(epochId);
        assertEq(collateralMarketVault.token(), TOKEN);
        assertEq(collateralMarketVault.strike(), strike);
        assertEq(collateralMarketVault.isWETH(), false);
        assertEq(
            collateralMarketVault.counterPartyVault(),
            address(premiumMarketVault)
        );
        assertEq(collateralMarketVault.factory(), address(factory));
        assertEq(collateralMarketVault.controller(), address(controller));
        assertEq(collateralMarketVault.epochs(0), epochId);
        assertEq(collateralMarketVault.epochExists(epochId), true);
        assertEq(epochBegin, begin);
        assertEq(epochEnd, end);
        assertEq(epochCreation, block.timestamp);

        (epochBegin, epochEnd, epochCreation) = premiumDepegMarketVault
            .epochConfig(depegEpochId);
        assertEq(premiumDepegMarketVault.token(), USDC_TOKEN);
        assertEq(premiumDepegMarketVault.strike(), depegStrike);
        assertEq(premiumDepegMarketVault.isWETH(), false);
        assertEq(
            premiumDepegMarketVault.counterPartyVault(),
            address(collateralDepegMarketVault)
        );
        assertEq(premiumDepegMarketVault.factory(), address(factory));
        assertEq(premiumDepegMarketVault.controller(), address(controller));
        assertEq(premiumDepegMarketVault.epochs(0), depegEpochId);
        assertEq(premiumDepegMarketVault.epochExists(depegEpochId), true);
        assertEq(epochBegin, begin);
        assertEq(epochEnd, end);
        assertEq(epochCreation, block.timestamp);

        (epochBegin, epochEnd, epochCreation) = collateralDepegMarketVault
            .epochConfig(depegEpochId);
        assertEq(collateralDepegMarketVault.token(), USDC_TOKEN);
        assertEq(collateralDepegMarketVault.strike(), depegStrike);
        assertEq(collateralDepegMarketVault.isWETH(), false);
        assertEq(
            collateralDepegMarketVault.counterPartyVault(),
            address(premiumDepegMarketVault)
        );
        assertEq(collateralDepegMarketVault.factory(), address(factory));
        assertEq(collateralDepegMarketVault.controller(), address(controller));
        assertEq(collateralDepegMarketVault.epochs(0), depegEpochId);
        assertEq(collateralDepegMarketVault.epochExists(depegEpochId), true);
        assertEq(epochBegin, begin);
        assertEq(epochEnd, end);
        assertEq(epochCreation, block.timestamp);
    }

    function testStateVars_RedStone() public {
        assertEq(redstoneProviderArbitrum.TIME_OUT(), TIME_OUT);
        assertEq(
            address(redstoneProviderArbitrum.vaultFactory()),
            address(factory)
        );
        assertEq(
            address(redstoneProviderArbitrum.priceFeedAdapter()),
            USDC_CHAINLINK
        );
        assertEq(redstoneProviderArbitrum.dataFeedId(), bytes32("USDC"));
        assertEq(redstoneProviderArbitrum.symbol(), "USDC");
    }

    function testStateVars_Chainlink() public {
        assertEq(
            address(chainlinkPriceProvider.vaultFactory()),
            address(factory)
        );
        assertEq(
            address(chainlinkPriceProvider.sequencerUptimeFeed()),
            ARBITRUM_SEQUENCER
        );
        assertEq(address(chainlinkPriceProvider.priceFeed()), USDC_CHAINLINK);
    }

    function testErrors_RedstoneProvider() public {
        vm.expectRevert(RedstonePriceProvider.ZeroAddress.selector);
        new RedstonePriceProvider(address(0), USDC_CHAINLINK, "USDC");

        vm.expectRevert(RedstonePriceProvider.ZeroAddress.selector);
        new RedstonePriceProvider(address(factory), address(0), "USDC");

        vm.expectRevert(RedstonePriceProvider.InvalidInput.selector);
        new RedstonePriceProvider(address(factory), USDC_CHAINLINK, "");

        // create mock oracle to test revert case
        address mockOracle = address(new MockOracleAnswerZero());
        redstoneProviderArbitrum = new RedstonePriceProvider(
            address(factory),
            mockOracle,
            "USDC"
        );
        vm.expectRevert(RedstonePriceProvider.OraclePriceZero.selector);
        redstoneProviderArbitrum.getLatestPrice();

        // create mock oracle to test revert case
        mockOracle = address(new MockOracleRoundOutdated());
        redstoneProviderArbitrum = new RedstonePriceProvider(
            address(factory),
            mockOracle,
            "USDC"
        );
        vm.expectRevert(RedstonePriceProvider.RoundIdOutdated.selector);
        redstoneProviderArbitrum.getLatestPrice();

        // create mock oracle to test revert case
        mockOracle = address(new MockOracleTimeOut(block.timestamp, TIME_OUT));
        redstoneProviderArbitrum = new RedstonePriceProvider(
            address(factory),
            mockOracle,
            "USDC"
        );
        vm.expectRevert(RedstonePriceProvider.PriceTimedOut.selector);
        redstoneProviderArbitrum.getLatestPrice();

        vm.expectRevert(RedstonePriceProvider.InvalidInput.selector);
        redstoneProviderArbitrum.stringToBytes32(
            "Long sentence that's very likely to be more than 32 bytes in total"
        );
    }

    function testErrors_ChainlinkProvider() public {
        vm.expectRevert(ChainlinkPriceProvider.ZeroAddress.selector);
        new ChainlinkPriceProvider(
            address(0),
            address(factory),
            USDC_CHAINLINK
        );

        vm.expectRevert(ChainlinkPriceProvider.ZeroAddress.selector);
        new ChainlinkPriceProvider(
            ARBITRUM_SEQUENCER,
            address(0),
            USDC_CHAINLINK
        );

        vm.expectRevert(ChainlinkPriceProvider.ZeroAddress.selector);
        new ChainlinkPriceProvider(
            ARBITRUM_SEQUENCER,
            address(factory),
            address(0)
        );

        // create mock sequencer to test revert case
        address mockAddress = address(new MockOracleAnswerOne());
        chainlinkPriceProvider = new ChainlinkPriceProvider(
            mockAddress,
            address(factory),
            USDC_CHAINLINK
        );
        vm.expectRevert(ChainlinkPriceProvider.SequencerDown.selector);
        chainlinkPriceProvider.getLatestPrice();

        mockAddress = address(new MockOracleGracePeriod());
        chainlinkPriceProvider = new ChainlinkPriceProvider(
            mockAddress,
            address(factory),
            USDC_CHAINLINK
        );
        vm.expectRevert(ChainlinkPriceProvider.GracePeriodNotOver.selector);
        chainlinkPriceProvider.getLatestPrice();

        mockAddress = address(new MockOracleAnswerZero());
        chainlinkPriceProvider = new ChainlinkPriceProvider(
            ARBITRUM_SEQUENCER,
            address(factory),
            mockAddress
        );
        vm.expectRevert(ChainlinkPriceProvider.OraclePriceZero.selector);
        chainlinkPriceProvider.getLatestPrice();

        mockAddress = address(new MockOracleRoundOutdated());
        chainlinkPriceProvider = new ChainlinkPriceProvider(
            ARBITRUM_SEQUENCER,
            address(factory),
            mockAddress
        );
        vm.expectRevert(ChainlinkPriceProvider.RoundIdOutdated.selector);
        chainlinkPriceProvider.getLatestPrice();

        mockAddress = address(new MockOracleTimeOut(block.timestamp, TIME_OUT));
        chainlinkPriceProvider = new ChainlinkPriceProvider(
            ARBITRUM_SEQUENCER,
            address(factory),
            mockAddress
        );
    }

    function testErrors_GenericLiquidateEpoch() public {
        vm.expectRevert(ControllerGenericV2.ZeroAddress.selector);
        new ControllerGenericV2(address(0), TREASURY);

        vm.expectRevert(ControllerGenericV2.ZeroAddress.selector);
        new ControllerGenericV2(address(factory), address(0));

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

        vm.warp(begin + 1 hours);
        vm.expectRevert(ControllerGenericV2.VaultZeroTVL.selector);
        controller.triggerLiquidation(depegMarketId, depegEpochId);

        vm.startPrank(USER);
        configureDepegState(depegPremium, depegCollateral, depegEpochId, begin);
        vm.stopPrank();

        // NOTE: To make this work - the oracle mocked to return updatedAt less than TIME_OUT and depeg
        address mockOracle = address(
            new MockOracleConditionMet(begin + 1 days)
        );
        _rewriteDepegMarket(int256(depegStrike), mockOracle);
        controller.triggerLiquidation(depegMarketId, depegEpochId);
        vm.expectRevert(ControllerGenericV2.EpochFinishedAlready.selector);
        controller.triggerLiquidation(depegMarketId, depegEpochId);

        // create new market and mock oracle to test revert case
        int256 mockStrike = 1 ether;
        mockOracle = address(new MockOracleConditionNotMet(mockStrike));
        _rewriteDepegMarket(mockStrike, mockOracle);
        vm.expectRevert(ControllerGenericV2.ConditionNotMet.selector);
        controller.triggerLiquidation(depegMarketId, depegEpochId);
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

    function testFork_ArbitrumGoerli() public {
        vm.selectFork(arbGoerliForkId);
        assertEq(vm.activeFork(), arbGoerliForkId);
        assertEq(
            IPriceFeedAdapter(PRICE_FEED_GOERLI).dataFeedId(),
            DATA_FEED_ID
        );
    }

    /*//////////////////////////////////////////////////////////////
                                 INTERNALS/HELPERS
    //////////////////////////////////////////////////////////////*/
    function helperCalculateFeeAdjustedValue(
        uint256 _amount,
        uint16 _fee
    ) internal pure returns (uint256) {
        return _amount - _amount.mulDivUp(_fee, 10000);
    }

    function _rewriteDepegMarket(int256 _strike, address mockOracle) internal {
        (depegPremium, depegCollateral, depegMarketId) = factory
            .createNewMarket(
                VaultFactoryV2.MarketConfigurationCalldata(
                    UNDERLYING,
                    uint256(_strike),
                    mockOracle,
                    UNDERLYING,
                    "USDC Token",
                    "USDC",
                    address(controller)
                )
            );
        (depegEpochId, ) = factory.createEpoch(depegMarketId, begin, end, fee);
        vm.startPrank(USER);
        configureDepegState(depegPremium, depegCollateral, depegEpochId, begin);
        vm.stopPrank();
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

    function configureDepegState(
        address _premiumVault,
        address _collatVault,
        uint256 _epochId,
        uint256 _begin
    ) public {
        vm.warp(_begin - 1 days);
        //deal ether
        vm.deal(USER, DEALT_AMOUNT);

        //approve gov token
        MintableToken(UNDERLYING).approve(
            _premiumVault,
            PREMIUM_DEPOSIT_AMOUNT
        );
        MintableToken(UNDERLYING).approve(_collatVault, COLLAT_DEPOSIT_AMOUNT);

        //deposit in both vaults
        VaultV2(_premiumVault).deposit(_epochId, PREMIUM_DEPOSIT_AMOUNT, USER);
        VaultV2(_collatVault).deposit(_epochId, COLLAT_DEPOSIT_AMOUNT, USER);

        //check deposit balances
        assertEq(
            VaultV2(_premiumVault).balanceOf(USER, _epochId),
            PREMIUM_DEPOSIT_AMOUNT
        );
        assertEq(
            VaultV2(_collatVault).balanceOf(USER, _epochId),
            COLLAT_DEPOSIT_AMOUNT
        );

        //check user underlying balance
        assertEq(USER.balance, DEALT_AMOUNT);

        //warp to epoch _begin
        vm.warp(_begin + 1 hours);
    }
}
