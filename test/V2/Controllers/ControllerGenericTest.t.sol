// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Helper} from "../Helper.sol";
import {VaultFactoryV2} from "../../../src/v2/VaultFactoryV2.sol";
import {
    ControllerGeneric
} from "../../../src/v2/Controllers/ControllerGeneric.sol";
import {
    RedstonePriceProvider
} from "../../../src/v2/oracles/individual/RedstonePriceProvider.sol";
import {MintableToken} from "../MintableToken.sol";
import {TimeLock} from "../../../src/v2/TimeLock.sol";
import {
    MockOracleConditionMet,
    MockOracleConditionNotMet
} from "../oracles/MockOracles.sol";

contract ControllerGenericTest is Helper {
    VaultFactoryV2 public factory;
    ControllerGeneric public controller;
    RedstonePriceProvider public redstoneProvider;

    address public premium;
    address public collateral;

    uint256 public strike;
    uint256 public marketId;
    uint256 public epochId;
    uint256 public falseId;

    uint40 public begin;
    uint40 public end;
    uint16 public fee;
    uint256 public arbGoerliForkId;

    event EpochResolved(
        uint256 indexed epochId,
        uint256 indexed marketId,
        ControllerGeneric.VaultTVL tvl,
        bool strikeMet,
        int256 depegPrice
    );

    event NullEpoch(
        uint256 indexed epochId,
        uint256 indexed marketId,
        ControllerGeneric.VaultTVL tvl
    );

    ////////////////////////////////////////////////
    //                HELPERS                     //
    ////////////////////////////////////////////////

    function setUp() public {
        arbGoerliForkId = vm.createFork(ARBITRUM_GOERLI_RPC_URL);
        vm.selectFork(arbGoerliForkId);

        UNDERLYING = address(new MintableToken("Vesta Token", "VST"));

        address timelock = address(new TimeLock(ADMIN));
        factory = new VaultFactoryV2(WETH, TREASURY, address(timelock));
        controller = new ControllerGeneric(address(factory), TREASURY);
        factory.whitelistController(address(controller));
        redstoneProvider = new RedstonePriceProvider(
            address(factory),
            VST_PRICE_FEED_GOERLI,
            "VST",
            TIME_OUT
        );

        string memory name = "USD Coin";
        string memory symbol = "USDC";
        uint256 decimals = 6; // 1e6
        strike = 0.1 ether * 10 ** decimals;
        falseId = 999;

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

        begin = uint40(block.timestamp - 5 days);
        end = uint40(block.timestamp - 3 days);
        fee = 50; // 0.5%
        (epochId, ) = factory.createEpoch(marketId, begin, end, fee);

        MintableToken(UNDERLYING).mint(USER);
    }

    function configureDepegStrikeAndOracle(
        int256 _strike,
        address mockOracle
    ) internal {
        (premium, collateral, marketId) = factory.createNewMarket(
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
        (epochId, ) = factory.createEpoch(marketId, begin, end, fee);
        vm.startPrank(USER);
        configureDepegState(
            premium,
            collateral,
            epochId,
            begin,
            PREMIUM_DEPOSIT_AMOUNT,
            COLLAT_DEPOSIT_AMOUNT
        );
        vm.stopPrank();
    }

    ////////////////////////////////////////////////
    //                STATE                       //
    ////////////////////////////////////////////////

    function testControllerCreation() public {
        assertEq(address(controller.vaultFactory()), address(factory));
        assertEq(controller.treasury(), TREASURY);
    }

    ////////////////////////////////////////////////
    //             FUNCTIONS & EVENTS             //
    ////////////////////////////////////////////////

    function testGetVaultFactory() public {
        assertEq(address(controller.getVaultFactory()), address(factory));
    }

    function testCalculateWithdrawalFeeValue() public {
        uint256 feeValue = controller.calculateWithdrawalFeeValue(10e6, 1000);
        assertEq(feeValue, 1e6);
    }

    function testGenericEndToEndEpoch() public {
        vm.startPrank(USER);
        configureEndEpochState(
            premium,
            collateral,
            epochId,
            begin,
            end,
            DEPOSIT_AMOUNT
        );

        //trigger end
        vm.expectEmit(true, true, true, true);
        emit EpochResolved(
            epochId,
            marketId,
            ControllerGeneric.VaultTVL(
                AMOUNT_AFTER_FEE,
                DEPOSIT_AMOUNT,
                0,
                DEPOSIT_AMOUNT
            ),
            false,
            0
        );
        controller.triggerEndEpoch(marketId, epochId);
        vm.stopPrank();
    }

    function testGenericEndToEndNull() public {
        vm.warp(begin + 1 hours);

        vm.expectEmit(true, true, true, true);
        emit NullEpoch(
            epochId,
            marketId,
            ControllerGeneric.VaultTVL(0, 0, 0, 0)
        );
        controller.triggerNullEpoch(marketId, epochId);
    }

    function testGenericDepegRedstone() public {
        vm.startPrank(USER);
        configureDepegState(
            premium,
            collateral,
            epochId,
            begin,
            PREMIUM_DEPOSIT_AMOUNT,
            COLLAT_DEPOSIT_AMOUNT
        );

        //trigger depeg
        int256 price = redstoneProvider.getLatestPrice();
        vm.expectEmit(true, true, true, true);
        emit EpochResolved(
            epochId,
            marketId,
            ControllerGeneric.VaultTVL(
                PREMIUM_AFTER_FEE,
                COLLAT_DEPOSIT_AMOUNT,
                COLLAT_AFTER_FEE,
                PREMIUM_DEPOSIT_AMOUNT
            ),
            true,
            price
        );
        controller.triggerLiquidation(marketId, epochId);

        vm.stopPrank();
    }

    ////////////////////////////////////////////////
    //              REVERT CASES                  //
    ////////////////////////////////////////////////
    function testRevertConstructorInputs() public {
        vm.expectRevert(ControllerGeneric.ZeroAddress.selector);
        controller = new ControllerGeneric(address(0), TREASURY);

        vm.expectRevert(ControllerGeneric.ZeroAddress.selector);
        controller = new ControllerGeneric(address(factory), address(0));
    }

    function testRevertEndEpoch() public {
        vm.expectRevert(
            abi.encodePacked(
                ControllerGeneric.MarketDoesNotExist.selector,
                falseId
            )
        );
        controller.triggerEndEpoch(falseId, epochId);

        // vm.expectRevert(ControllerGeneric.EpochNotExist.selector);
        // controller.triggerEndEpoch(marketId, falseId);

        vm.warp(begin + 1 hours);
        vm.expectRevert(ControllerGeneric.EpochNotExpired.selector);
        controller.triggerEndEpoch(marketId, epochId);

        vm.warp(end + 1 hours);
        vm.startPrank(USER);
        configureEndEpochState(
            premium,
            collateral,
            epochId,
            begin,
            end,
            DEPOSIT_AMOUNT
        );
        vm.stopPrank();

        controller.triggerEndEpoch(marketId, epochId);
        vm.expectRevert(ControllerGeneric.EpochFinishedAlready.selector);
        controller.triggerEndEpoch(marketId, epochId);
    }

    function testRevertNullEpoch() public {
        vm.expectRevert(
            abi.encodePacked(
                ControllerGeneric.MarketDoesNotExist.selector,
                falseId
            )
        );
        controller.triggerNullEpoch(falseId, epochId);

        vm.expectRevert(ControllerGeneric.EpochNotExist.selector);
        controller.triggerNullEpoch(marketId, falseId);

        vm.warp(begin - 1 hours);
        vm.expectRevert(ControllerGeneric.EpochNotStarted.selector);
        controller.triggerNullEpoch(marketId, epochId);

        vm.startPrank(USER);
        configureEndEpochState(
            premium,
            collateral,
            epochId,
            begin,
            end,
            DEPOSIT_AMOUNT
        );
        vm.stopPrank();

        vm.warp(begin + 1 hours);
        vm.expectRevert(ControllerGeneric.VaultNotZeroTVL.selector);
        controller.triggerNullEpoch(marketId, epochId);

        vm.warp(end + 1 hours);
        controller.triggerEndEpoch(marketId, epochId);
        vm.expectRevert(ControllerGeneric.EpochFinishedAlready.selector);
        controller.triggerNullEpoch(marketId, epochId);
    }

    function testRevertMarketDoesNotExist() public {
        vm.expectRevert(
            abi.encodePacked(
                ControllerGeneric.MarketDoesNotExist.selector,
                falseId
            )
        );
        controller.triggerLiquidation(falseId, epochId);
    }

    function testRevertEpochNotExist() public {
        vm.expectRevert(ControllerGeneric.EpochNotExist.selector);
        controller.triggerLiquidation(marketId, falseId);
    }

    function testRevertEpochNotStarted() public {
        vm.warp(begin - 1 hours);
        vm.expectRevert(ControllerGeneric.EpochNotStarted.selector);
        controller.triggerLiquidation(marketId, epochId);
    }

    function testRevertEpochExpired() public {
        vm.warp(end + 1 hours);
        vm.expectRevert(ControllerGeneric.EpochExpired.selector);
        controller.triggerLiquidation(marketId, epochId);
    }

    function testRevertVaultZeroTVL() public {
        vm.warp(begin + 1 hours);
        vm.expectRevert(ControllerGeneric.VaultZeroTVL.selector);
        controller.triggerLiquidation(marketId, epochId);
    }

    function testRevertLiquidate() public {
        vm.startPrank(USER);
        configureDepegState(
            premium,
            collateral,
            epochId,
            begin,
            PREMIUM_DEPOSIT_AMOUNT,
            COLLAT_DEPOSIT_AMOUNT
        );
        vm.stopPrank();

        // NOTE: To make this work - the oracle mocked to return updatedAt less than TIME_OUT and depeg
        address mockOracle = address(
            new MockOracleConditionMet(begin + 1 days)
        );
        int256 mockStrike = 2 ether;
        configureDepegStrikeAndOracle(mockStrike, mockOracle);
        controller.triggerLiquidation(marketId, epochId);
        vm.expectRevert(ControllerGeneric.EpochFinishedAlready.selector);
        controller.triggerLiquidation(marketId, epochId);

        // create new market and mock oracle to test revert case
        mockStrike = 3 ether;
        mockOracle = address(new MockOracleConditionNotMet(mockStrike));
        configureDepegStrikeAndOracle(mockStrike, mockOracle);
        vm.expectRevert(ControllerGeneric.ConditionNotMet.selector);
        controller.triggerLiquidation(marketId, epochId);
    }
}
