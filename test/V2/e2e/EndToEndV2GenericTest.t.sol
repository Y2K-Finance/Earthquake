// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Config, MintableToken} from "../Helper.sol";
import {IVaultV2} from "../../../src/v2/VaultFactoryV2.sol";
import {VaultV2} from "../../../src/v2/VaultV2.sol";
import {
    ControllerGenericV2
} from "../../../src/v2/Controllers/ControllerGenericV2.sol";

import {console} from "forge-std/console.sol";

contract EndToEndV2GenericTest is Config {
    function testErrorsGenericEndEpoch() public {
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

    function testErrorsGenericLiquidateEpoch() public {
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

    function testErrorsGenericNullEpoch() public {
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

    function testGenericEndToEndEpoch() public {
        vm.startPrank(USER);
        uint256 startingBalance = MintableToken(UNDERLYING).balanceOf(USER);
        configureEndEpochState();

        //trigger end of epoch
        controller.triggerEndEpoch(marketId, epochId);

        //check vault balances on withdraw
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
        // TODO: Fee that works is 0.05% - check this out and the maths surrounding depositing the underlying
        assertEq(
            MintableToken(UNDERLYING).balanceOf(USER),
            helperCalculateFeeAdjustedValue(startingBalance, 5)
        );
        vm.stopPrank();
    }

    function testGenericEndToEndDepeg() public {
        vm.startPrank(USER);
        configureDepegState();

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
        vm.stopPrank();
    }
}
