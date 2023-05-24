// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Config, MintableToken} from "../Helper.sol";
import {IVaultV2} from "../../../src/v2/VaultFactoryV2.sol";
import {VaultV2} from "../../../src/v2/VaultV2.sol";
import {
    ControllerGenericV2
} from "../../../src/v2/Controllers/ControllerGenericV2.sol";
import {
    IPriceFeedAdapter
} from "../../../src/v2/Interfaces/IPriceFeedAdapter.sol";

import {console} from "forge-std/console.sol";

contract EndToEndV2GenericTest is Config {
    function test_GenericEndToEndEpoch() public {
        vm.startPrank(USER);
        configureEndEpochState();
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
        assertEq(USER.balance, DEALT_AMOUNT);
        assertEq(
            MintableToken(UNDERLYING).balanceOf(USER),
            cachedBalance + AMOUNT_AFTER_FEE
        );
        vm.stopPrank();
    }

    function test_GenericEndToEndDepeg() public {
        vm.startPrank(USER);
        configureDepegState();
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

        assertEq(USER.balance, DEALT_AMOUNT);
        assertEq(
            MintableToken(UNDERLYING).balanceOf(USER),
            cachedBalance + collateralShareValue + premiumShareValue
        );
        vm.stopPrank();
    }

    function test_GenericEndToEndNull() public {
        vm.warp(begin + 1 hours);
        controller.triggerNullEpoch(marketId, epochId);
    }

    function test_GenericDepegBelowGoerli() public {
        _setupFork(1, arbGoerliForkId); // price is below

        vm.startPrank(USER);
        configureDepegState();
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
        assertEq(USER.balance, DEALT_AMOUNT);
        assertEq(
            MintableToken(UNDERLYING).balanceOf(USER),
            cachedBalance + collateralShareValue + premiumShareValue
        );
        vm.stopPrank();
    }

    function test_GenericDepegAboveGoerli() public {
        _setupFork(2, arbGoerliForkId); // 2 = price is above

        vm.startPrank(USER);
        configureDepegState();
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
        assertEq(USER.balance, DEALT_AMOUNT);
        assertEq(
            MintableToken(UNDERLYING).balanceOf(USER),
            cachedBalance + collateralShareValue + premiumShareValue
        );
        vm.stopPrank();
    }

    function test_GenericDepegExactGoerli() public {
        _setupFork(3, arbGoerliForkId); // 3 = price is exact
        vm.startPrank(USER);
        configureDepegState();
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
        assertEq(USER.balance, DEALT_AMOUNT);
        assertEq(
            MintableToken(UNDERLYING).balanceOf(USER),
            cachedBalance + collateralShareValue + premiumShareValue
        );
        vm.stopPrank();
    }
}
