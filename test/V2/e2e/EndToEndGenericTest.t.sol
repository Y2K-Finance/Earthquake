// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Helper} from "../Helper.sol";
import {VaultV2} from "../../../src/v2/VaultV2.sol";
import {VaultFactoryV2} from "../../../src/v2/VaultFactoryV2.sol";
import {TimeLock} from "../../../src/v2/TimeLock.sol";
import {MintableToken} from "../MintableToken.sol";
import {
    ControllerGeneric
} from "../../../src/v2/Controllers/ControllerGeneric.sol";
import {
    RedstonePriceProvider
} from "../../../src/v2/oracles/RedstonePriceProvider.sol";
import {
    ChainlinkPriceProvider
} from "../../../src/v2/oracles/ChainlinkPriceProvider.sol";
import {
    ChainlinkPriceProviderV2
} from "../../../src/v2/oracles/ChainlinkPriceProviderV2.sol";
import {GdaiPriceProvider} from "../../../src/v2/oracles/GdaiPriceProvider.sol";
import {DIAPriceProvider} from "../../../src/v2/oracles/DIAPriceProvider.sol";
import {CVIPriceProvider} from "../../../src/v2/oracles/CVIPriceProvider.sol";
import {
    IPriceFeedAdapter
} from "../../../src/v2/interfaces/IPriceFeedAdapter.sol";

contract EndToEndV2GenericTest is Helper {
    VaultFactoryV2 public factory;
    ControllerGeneric public controller;
    VaultV2 public vault;
    IPriceFeedAdapter public oracle;
    RedstonePriceProvider public redstoneProvider;
    ChainlinkPriceProvider public chainlinkProvider;
    ChainlinkPriceProviderV2 public chainlinkProviderV2;
    GdaiPriceProvider public gdaiPriceProvider;
    DIAPriceProvider public diaPriceProvider;
    CVIPriceProvider public cviPriceProvider;

    address public premium;
    address public collateral;
    address public depegPremium;
    address public depegCollateral;

    uint256 public marketId;
    uint256 public strike;
    uint256 public epochId;
    uint256 public depegMarketId;
    uint256 public depegStrike;
    uint256 public depegEpochId;

    uint40 public begin;
    uint40 public end;
    uint16 public fee;
    uint256 public premiumShareValue;
    uint256 public collateralShareValue;

    uint256 public arbForkId;
    uint256 public arbGoerliForkId;
    int256 public gdaiStrikePrice = -8994085036142722;
    uint256 public diaStrikePrice = 50_000e8;

    ////////////////////////////////////////////////
    //                HELPERS                     //
    ////////////////////////////////////////////////

    function setUp() public {
        arbForkId = vm.createFork(ARBITRUM_RPC_URL);
        arbGoerliForkId = vm.createFork(ARBITRUM_GOERLI_RPC_URL);
        vm.selectFork(arbForkId);

        UNDERLYING = address(new MintableToken("Vesta Token", "VST"));

        address timelock = address(new TimeLock(ADMIN));
        factory = new VaultFactoryV2(WETH, TREASURY, timelock);
        controller = new ControllerGeneric(address(factory), TREASURY);
        factory.whitelistController(address(controller));
        redstoneProvider = new RedstonePriceProvider(
            address(factory),
            VST_PRICE_FEED,
            "VST",
            TIME_OUT
        );

        string memory name = string("VST Coin");
        string memory symbol = string("VST");

        (premium, collateral, marketId) = factory.createNewMarket(
            VaultFactoryV2.MarketConfigurationCalldata(
                UNDERLYING,
                strike,
                address(redstoneProvider),
                UNDERLYING,
                name,
                symbol,
                address(controller)
            )
        );

        depegStrike = 0.1 ether * 10 ** 18;
        (depegPremium, depegCollateral, depegMarketId) = factory
            .createNewMarket(
                VaultFactoryV2.MarketConfigurationCalldata(
                    UNDERLYING,
                    depegStrike,
                    address(redstoneProvider),
                    UNDERLYING,
                    name,
                    symbol,
                    address(controller)
                )
            );

        begin = uint40(block.timestamp);
        end = uint40(block.timestamp + 3 days);
        fee = 50; // 0.5%
        (epochId, ) = factory.createEpoch(marketId, begin, end, fee);
        (depegEpochId, ) = factory.createEpoch(depegMarketId, begin, end, fee);

        MintableToken(UNDERLYING).mint(USER);
    }

    function _setupChainlink() internal {
        vm.selectFork(arbForkId);
        UNDERLYING = address(new MintableToken("Vesta Token", "VST"));
        address timelock = address(new TimeLock(ADMIN));
        factory = new VaultFactoryV2(WETH, TREASURY, address(timelock));
        controller = new ControllerGeneric(address(factory), TREASURY);
        factory.whitelistController(address(controller));

        chainlinkProvider = new ChainlinkPriceProvider(
            ARBITRUM_SEQUENCER,
            address(factory),
            USDC_CHAINLINK,
            TIME_OUT
        );

        (, , , uint256 updatedAt, ) = IPriceFeedAdapter(USDC_CHAINLINK)
            .latestRoundData();
        // depeg runs at begin + 1 hours - avoids TIME_OUT reverts from Chainlink
        begin = uint40(updatedAt);
        end = uint40(updatedAt + 3 days);

        depegStrike = 1 ether * 10 ** 6;
        string memory name = string("USD Coin");
        string memory symbol = string("USDC");
        (depegPremium, depegCollateral, depegMarketId) = factory
            .createNewMarket(
                VaultFactoryV2.MarketConfigurationCalldata(
                    UNDERLYING,
                    depegStrike,
                    address(chainlinkProvider),
                    UNDERLYING,
                    name,
                    symbol,
                    address(controller)
                )
            );

        (depegEpochId, ) = factory.createEpoch(depegMarketId, begin, end, fee);
        MintableToken(UNDERLYING).mint(USER);
    }

    function _setupChainlinkGoerli() internal {
        vm.selectFork(arbGoerliForkId);
        UNDERLYING = address(new MintableToken("ETH Volatility", "ETHV"));
        address timelock = address(new TimeLock(ADMIN));
        factory = new VaultFactoryV2(WETH, TREASURY, address(timelock));
        controller = new ControllerGeneric(address(factory), TREASURY);
        factory.whitelistController(address(controller));

        chainlinkProviderV2 = new ChainlinkPriceProviderV2(
            ARBITRUM_SEQUENCER_GOERLI,
            address(factory),
            ETH_VOL_CHAINLINK,
            TIME_OUT
        );

        (, , , uint256 updatedAt, ) = IPriceFeedAdapter(ETH_VOL_CHAINLINK)
            .latestRoundData();
        // depeg runs at begin + 1 hours - avoids TIME_OUT reverts from Chainlink
        begin = uint40(updatedAt);
        end = uint40(updatedAt + 3 days);

        depegStrike = uint256(chainlinkProviderV2.getLatestPrice() - 1);
        string memory name = string("ETH Volatility");
        string memory symbol = string("ETHV");
        (depegPremium, depegCollateral, depegMarketId) = factory
            .createNewMarket(
                VaultFactoryV2.MarketConfigurationCalldata(
                    UNDERLYING,
                    depegStrike,
                    address(chainlinkProviderV2),
                    UNDERLYING,
                    name,
                    symbol,
                    address(controller)
                )
            );

        (depegEpochId, ) = factory.createEpoch(depegMarketId, begin, end, fee);
        MintableToken(UNDERLYING).mint(USER);
    }

    function _setupGdai() internal {
        vm.selectFork(arbForkId);
        UNDERLYING = address(new MintableToken("Gains Network DAI", "gDAI"));
        address timelock = address(new TimeLock(ADMIN));
        factory = new VaultFactoryV2(WETH, TREASURY, address(timelock));
        controller = new ControllerGeneric(address(factory), TREASURY);
        factory.whitelistController(address(controller));

        gdaiPriceProvider = new GdaiPriceProvider(GDAI_VAULT);
        int256 strikePrice = (gdaiPriceProvider.getLatestPrice() + 1);
        gdaiPriceProvider.updateStrikeHash(strikePrice);

        depegStrike = uint256(-strikePrice);

        string memory name = string("Gains Network DAI");
        string memory symbol = string("gDAI");
        (depegPremium, depegCollateral, depegMarketId) = factory
            .createNewMarket(
                VaultFactoryV2.MarketConfigurationCalldata(
                    UNDERLYING,
                    depegStrike,
                    address(gdaiPriceProvider),
                    UNDERLYING,
                    name,
                    symbol,
                    address(controller)
                )
            );

        (depegEpochId, ) = factory.createEpoch(depegMarketId, begin, end, fee);
        MintableToken(UNDERLYING).mint(USER);
    }

    function _setupDIA() internal {
        vm.selectFork(arbForkId);
        UNDERLYING = address(new MintableToken("Magic Internet Money", "MIM"));
        address timelock = address(new TimeLock(ADMIN));
        factory = new VaultFactoryV2(WETH, TREASURY, address(timelock));
        controller = new ControllerGeneric(address(factory), TREASURY);
        factory.whitelistController(address(controller));

        diaPriceProvider = new DIAPriceProvider(DIA_ORACLE_V2, DIA_DECIMALS);

        // TODO: Change this to price feed when MIM/USD live
        depegStrike = diaStrikePrice;
        string memory name = string("Magic Internet Money");
        string memory symbol = string("MIM");
        (depegPremium, depegCollateral, depegMarketId) = factory
            .createNewMarket(
                VaultFactoryV2.MarketConfigurationCalldata(
                    UNDERLYING,
                    depegStrike,
                    address(diaPriceProvider),
                    UNDERLYING,
                    name,
                    symbol,
                    address(controller)
                )
            );

        (depegEpochId, ) = factory.createEpoch(depegMarketId, begin, end, fee);
        MintableToken(UNDERLYING).mint(USER);
    }

    function _setupCVI() internal {
        vm.selectFork(arbForkId);
        UNDERLYING = address(new MintableToken("CVI Volatility", "CVI"));
        address timelock = address(new TimeLock(ADMIN));
        factory = new VaultFactoryV2(WETH, TREASURY, address(timelock));
        controller = new ControllerGeneric(address(factory), TREASURY);
        factory.whitelistController(address(controller));

        cviPriceProvider = new CVIPriceProvider(
            CVI_ORACLE,
            TIME_OUT,
            CVI_DECIMALS
        );
        int256 cviStrike = cviPriceProvider.getLatestPrice() - 1;

        depegStrike = uint256(cviStrike);
        string memory name = string("CVI Volatility");
        string memory symbol = string("CVI");
        (depegPremium, depegCollateral, depegMarketId) = factory
            .createNewMarket(
                VaultFactoryV2.MarketConfigurationCalldata(
                    UNDERLYING,
                    depegStrike,
                    address(cviPriceProvider),
                    UNDERLYING,
                    name,
                    symbol,
                    address(controller)
                )
            );

        (depegEpochId, ) = factory.createEpoch(depegMarketId, begin, end, fee);
        MintableToken(UNDERLYING).mint(USER);
    }

    function helperCalculateFeeAdjustedValue(
        uint256 _amount,
        uint16 _fee
    ) internal pure returns (uint256) {
        return _amount - ((_amount * _fee) / 10000);
    }

    ////////////////////////////////////////////////
    //                FUNCTIONS                  //
    ////////////////////////////////////////////////

    function test_GenericEndToEndEpoch() public {
        vm.startPrank(USER);
        configureEndEpochState(
            premium,
            collateral,
            epochId,
            begin,
            end,
            DEPOSIT_AMOUNT
        );
        uint256 cachedBalance = MintableToken(UNDERLYING).balanceOf(USER);

        //trigger end
        controller.triggerEndEpoch(marketId, epochId);
        assertEq(VaultV2(premium).previewWithdraw(epochId, DEPOSIT_AMOUNT), 0);
        assertEq(
            VaultV2(collateral).previewWithdraw(epochId, DEPOSIT_AMOUNT),
            AMOUNT_AFTER_FEE
        );

        //withdraw from vaults
        VaultV2(premium).withdraw(epochId, DEPOSIT_AMOUNT, USER, USER);
        VaultV2(collateral).withdraw(epochId, DEPOSIT_AMOUNT, USER, USER);

        //check vaults balance
        assertEq(VaultV2(premium).balanceOf(USER, epochId), 0);
        assertEq(VaultV2(collateral).balanceOf(USER, epochId), 0);

        //check user ERC20 balance
        assertEq(
            MintableToken(UNDERLYING).balanceOf(USER),
            cachedBalance + AMOUNT_AFTER_FEE
        );
        vm.stopPrank();
    }

    function test_GenericDepegRedstone() public {
        vm.startPrank(USER);
        configureDepegState(
            depegPremium,
            depegCollateral,
            depegEpochId,
            begin,
            PREMIUM_DEPOSIT_AMOUNT,
            COLLAT_DEPOSIT_AMOUNT
        );
        uint256 cachedBalance = MintableToken(UNDERLYING).balanceOf(USER);

        //trigger depeg
        controller.triggerLiquidation(depegMarketId, depegEpochId);
        premiumShareValue = helperCalculateFeeAdjustedValue(
            VaultV2(depegCollateral).finalTVL(depegEpochId),
            fee
        );
        collateralShareValue = helperCalculateFeeAdjustedValue(
            VaultV2(depegPremium).finalTVL(depegEpochId),
            fee
        );

        //check vault balances on withdraw
        assertEq(
            premiumShareValue,
            VaultV2(depegPremium).previewWithdraw(
                depegEpochId,
                PREMIUM_DEPOSIT_AMOUNT
            )
        );
        assertEq(
            collateralShareValue,
            VaultV2(depegCollateral).previewWithdraw(
                depegEpochId,
                COLLAT_DEPOSIT_AMOUNT
            )
        );

        //withdraw from vaults
        VaultV2(depegPremium).withdraw(
            depegEpochId,
            PREMIUM_DEPOSIT_AMOUNT,
            USER,
            USER
        );
        VaultV2(depegCollateral).withdraw(
            depegEpochId,
            COLLAT_DEPOSIT_AMOUNT,
            USER,
            USER
        );

        //check vaults balance
        assertEq(VaultV2(depegPremium).balanceOf(USER, depegEpochId), 0);
        assertEq(VaultV2(depegCollateral).balanceOf(USER, depegEpochId), 0);

        //check user ERC20 balance
        assertEq(
            MintableToken(UNDERLYING).balanceOf(USER),
            cachedBalance + collateralShareValue + premiumShareValue
        );
        vm.stopPrank();
    }

    function test_GenericDepegChainlink() public {
        _setupChainlink();
        vm.startPrank(USER);
        configureDepegState(
            depegPremium,
            depegCollateral,
            depegEpochId,
            begin,
            PREMIUM_DEPOSIT_AMOUNT,
            COLLAT_DEPOSIT_AMOUNT
        );
        uint256 cachedBalance = MintableToken(UNDERLYING).balanceOf(USER);

        //trigger depeg
        controller.triggerLiquidation(depegMarketId, depegEpochId);
        premiumShareValue = helperCalculateFeeAdjustedValue(
            VaultV2(depegCollateral).finalTVL(depegEpochId),
            fee
        );
        collateralShareValue = helperCalculateFeeAdjustedValue(
            VaultV2(depegPremium).finalTVL(depegEpochId),
            fee
        );

        //check vault balances on withdraw
        assertEq(
            premiumShareValue,
            VaultV2(depegPremium).previewWithdraw(
                depegEpochId,
                PREMIUM_DEPOSIT_AMOUNT
            )
        );
        assertEq(
            collateralShareValue,
            VaultV2(depegCollateral).previewWithdraw(
                depegEpochId,
                COLLAT_DEPOSIT_AMOUNT
            )
        );

        //withdraw from vaults
        VaultV2(depegPremium).withdraw(
            depegEpochId,
            PREMIUM_DEPOSIT_AMOUNT,
            USER,
            USER
        );
        VaultV2(depegCollateral).withdraw(
            depegEpochId,
            COLLAT_DEPOSIT_AMOUNT,
            USER,
            USER
        );

        //check vaults balance
        assertEq(VaultV2(depegPremium).balanceOf(USER, depegEpochId), 0);
        assertEq(VaultV2(depegCollateral).balanceOf(USER, depegEpochId), 0);

        //check user ERC20 balance
        assertEq(
            MintableToken(UNDERLYING).balanceOf(USER),
            cachedBalance + collateralShareValue + premiumShareValue
        );
        vm.stopPrank();
    }

    function test_GenericDepegChainlinkVol() public {
        _setupChainlinkGoerli();
        vm.startPrank(USER);
        configureDepegState(
            depegPremium,
            depegCollateral,
            depegEpochId,
            begin,
            PREMIUM_DEPOSIT_AMOUNT,
            COLLAT_DEPOSIT_AMOUNT
        );
        uint256 cachedBalance = MintableToken(UNDERLYING).balanceOf(USER);

        //trigger depeg
        controller.triggerLiquidation(depegMarketId, depegEpochId);
        premiumShareValue = helperCalculateFeeAdjustedValue(
            VaultV2(depegCollateral).finalTVL(depegEpochId),
            fee
        );
        collateralShareValue = helperCalculateFeeAdjustedValue(
            VaultV2(depegPremium).finalTVL(depegEpochId),
            fee
        );

        //check vault balances on withdraw
        assertEq(
            premiumShareValue,
            VaultV2(depegPremium).previewWithdraw(
                depegEpochId,
                PREMIUM_DEPOSIT_AMOUNT
            )
        );
        assertEq(
            collateralShareValue,
            VaultV2(depegCollateral).previewWithdraw(
                depegEpochId,
                COLLAT_DEPOSIT_AMOUNT
            )
        );

        //withdraw from vaults
        VaultV2(depegPremium).withdraw(
            depegEpochId,
            PREMIUM_DEPOSIT_AMOUNT,
            USER,
            USER
        );
        VaultV2(depegCollateral).withdraw(
            depegEpochId,
            COLLAT_DEPOSIT_AMOUNT,
            USER,
            USER
        );

        //check vaults balance
        assertEq(VaultV2(depegPremium).balanceOf(USER, depegEpochId), 0);
        assertEq(VaultV2(depegCollateral).balanceOf(USER, depegEpochId), 0);

        //check user ERC20 balance
        assertEq(
            MintableToken(UNDERLYING).balanceOf(USER),
            cachedBalance + collateralShareValue + premiumShareValue
        );
        vm.stopPrank();
    }

    function test_GenericDepegGdai() public {
        _setupGdai();
        vm.startPrank(USER);
        configureDepegState(
            depegPremium,
            depegCollateral,
            depegEpochId,
            begin,
            PREMIUM_DEPOSIT_AMOUNT,
            COLLAT_DEPOSIT_AMOUNT
        );
        uint256 cachedBalance = MintableToken(UNDERLYING).balanceOf(USER);

        //trigger depeg
        controller.triggerLiquidation(depegMarketId, depegEpochId);
        premiumShareValue = helperCalculateFeeAdjustedValue(
            VaultV2(depegCollateral).finalTVL(depegEpochId),
            fee
        );
        collateralShareValue = helperCalculateFeeAdjustedValue(
            VaultV2(depegPremium).finalTVL(depegEpochId),
            fee
        );

        //check vault balances on withdraw
        assertEq(
            premiumShareValue,
            VaultV2(depegPremium).previewWithdraw(
                depegEpochId,
                PREMIUM_DEPOSIT_AMOUNT
            )
        );
        assertEq(
            collateralShareValue,
            VaultV2(depegCollateral).previewWithdraw(
                depegEpochId,
                COLLAT_DEPOSIT_AMOUNT
            )
        );

        //withdraw from vaults
        VaultV2(depegPremium).withdraw(
            depegEpochId,
            PREMIUM_DEPOSIT_AMOUNT,
            USER,
            USER
        );
        VaultV2(depegCollateral).withdraw(
            depegEpochId,
            COLLAT_DEPOSIT_AMOUNT,
            USER,
            USER
        );

        //check vaults balance
        assertEq(VaultV2(depegPremium).balanceOf(USER, depegEpochId), 0);
        assertEq(VaultV2(depegCollateral).balanceOf(USER, depegEpochId), 0);

        //check user ERC20 balance
        assertEq(
            MintableToken(UNDERLYING).balanceOf(USER),
            cachedBalance + collateralShareValue + premiumShareValue
        );
        vm.stopPrank();
    }

    function test_GenericDepegDIA() public {
        _setupDIA();
        vm.startPrank(USER);
        configureDepegState(
            depegPremium,
            depegCollateral,
            depegEpochId,
            begin,
            PREMIUM_DEPOSIT_AMOUNT,
            COLLAT_DEPOSIT_AMOUNT
        );
        uint256 cachedBalance = MintableToken(UNDERLYING).balanceOf(USER);

        //trigger depeg
        controller.triggerLiquidation(depegMarketId, depegEpochId);
        premiumShareValue = helperCalculateFeeAdjustedValue(
            VaultV2(depegCollateral).finalTVL(depegEpochId),
            fee
        );
        collateralShareValue = helperCalculateFeeAdjustedValue(
            VaultV2(depegPremium).finalTVL(depegEpochId),
            fee
        );

        //check vault balances on withdraw
        assertEq(
            premiumShareValue,
            VaultV2(depegPremium).previewWithdraw(
                depegEpochId,
                PREMIUM_DEPOSIT_AMOUNT
            )
        );
        assertEq(
            collateralShareValue,
            VaultV2(depegCollateral).previewWithdraw(
                depegEpochId,
                COLLAT_DEPOSIT_AMOUNT
            )
        );

        //withdraw from vaults
        VaultV2(depegPremium).withdraw(
            depegEpochId,
            PREMIUM_DEPOSIT_AMOUNT,
            USER,
            USER
        );
        VaultV2(depegCollateral).withdraw(
            depegEpochId,
            COLLAT_DEPOSIT_AMOUNT,
            USER,
            USER
        );

        //check vaults balance
        assertEq(VaultV2(depegPremium).balanceOf(USER, depegEpochId), 0);
        assertEq(VaultV2(depegCollateral).balanceOf(USER, depegEpochId), 0);

        //check user ERC20 balance
        assertEq(
            MintableToken(UNDERLYING).balanceOf(USER),
            cachedBalance + collateralShareValue + premiumShareValue
        );
        vm.stopPrank();
    }

    function test_GenericDepegCVIVol() public {
        _setupCVI();
        vm.startPrank(USER);
        configureDepegState(
            depegPremium,
            depegCollateral,
            depegEpochId,
            begin,
            PREMIUM_DEPOSIT_AMOUNT,
            COLLAT_DEPOSIT_AMOUNT
        );
        uint256 cachedBalance = MintableToken(UNDERLYING).balanceOf(USER);

        //trigger depeg
        controller.triggerLiquidation(depegMarketId, depegEpochId);
        premiumShareValue = helperCalculateFeeAdjustedValue(
            VaultV2(depegCollateral).finalTVL(depegEpochId),
            fee
        );
        collateralShareValue = helperCalculateFeeAdjustedValue(
            VaultV2(depegPremium).finalTVL(depegEpochId),
            fee
        );

        //check vault balances on withdraw
        assertEq(
            premiumShareValue,
            VaultV2(depegPremium).previewWithdraw(
                depegEpochId,
                PREMIUM_DEPOSIT_AMOUNT
            )
        );
        assertEq(
            collateralShareValue,
            VaultV2(depegCollateral).previewWithdraw(
                depegEpochId,
                COLLAT_DEPOSIT_AMOUNT
            )
        );

        //withdraw from vaults
        VaultV2(depegPremium).withdraw(
            depegEpochId,
            PREMIUM_DEPOSIT_AMOUNT,
            USER,
            USER
        );
        VaultV2(depegCollateral).withdraw(
            depegEpochId,
            COLLAT_DEPOSIT_AMOUNT,
            USER,
            USER
        );

        //check vaults balance
        assertEq(VaultV2(depegPremium).balanceOf(USER, depegEpochId), 0);
        assertEq(VaultV2(depegCollateral).balanceOf(USER, depegEpochId), 0);

        //check user ERC20 balance
        assertEq(
            MintableToken(UNDERLYING).balanceOf(USER),
            cachedBalance + collateralShareValue + premiumShareValue
        );
        vm.stopPrank();
    }
}
