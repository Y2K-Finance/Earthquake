// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../Helper.sol";
import "../../../src/v2/VaultFactoryV2.sol";
import "../../../src/v2/VaultV2.sol";
import "../../../src/v2/Controllers/ControllerPeggedAssetV2.sol";
import {FixedPointMathLib} from "@solmate/utils/FixedPointMathLib.sol";


contract EndToEndV2Test is Helper {
    using FixedPointMathLib for uint256;

    VaultFactoryV2 public factory;
    ControllerPeggedAssetV2 public controller;

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

    uint256 public constant AMOUNT_AFTER_FEE = 19.95 ether;
    uint256 public constant PREMIUM_DEPOSIT_AMOUNT = 2 ether;
    uint256 public constant COLLAT_DEPOSIT_AMOUNT = 10 ether;
    uint256 public constant DEPOSIT_AMOUNT = 10 ether;
    uint256 public constant DEALT_AMOUNT = 20 ether;

    uint40 public begin;
    uint40 public end;

    uint16 public fee;

    string public ARBITRUM_RPC_URL = vm.envString("ARBITRUM_RPC_URL");

    function setUp() public {
        arbForkId = vm.createFork(ARBITRUM_RPC_URL);
        vm.selectFork(arbForkId);
        
        UNDERLYING = address(new MintableToken("UnderLyingToken", "utkn"));

        factory = new VaultFactoryV2(
                ADMIN,
                WETH,
                TREASURY
            );
        
        controller = new ControllerPeggedAssetV2(address(factory), ARBITRUM_SEQUENCER, TREASURY);

        factory.whitelistController(address(controller));
        
        //create end epoch market
        oracle = address(0x3);
        strike = uint256(0x2);
        string memory name = string("USD Coin");
        string memory symbol = string("USDC");

        (
            premium,
            collateral,
            marketId
        ) = factory.createNewMarket(
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
        depegStrike = uint256(2 ether);
        (
            depegPremium,
            depegCollateral,
            depegMarketId
        ) = factory.createNewMarket(
            VaultFactoryV2.MarketConfigurationCalldata(
                USDC_TOKEN,
                depegStrike,
                USDC_CHAINLINK,
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

        epochId = factory.createEpoch(
                marketId,
                begin,
                end,
                fee
       );

       //create epoch for depeg
        depegEpochId = factory.createEpoch(
                depegMarketId,
                begin,
                end,
                fee
       );

       MintableToken(UNDERLYING).mint(USER);
    }

    function testEndToEndEndEpoch() public {
        vm.startPrank(USER);

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
        assertEq(VaultV2(premium).balanceOf(USER ,epochId), DEPOSIT_AMOUNT);
        assertEq(VaultV2(collateral).balanceOf(USER ,epochId), DEPOSIT_AMOUNT);

        //check user underlying balance
        assertEq(USER.balance, DEALT_AMOUNT);

        //warp to epoch end
        vm.warp(end + 1 days);
        
        //trigger end of epoch
        controller.triggerEndEpoch(marketId, epochId);

        //check vault balances on withdraw
        assertEq(VaultV2(premium).previewWithdraw(epochId, DEPOSIT_AMOUNT), 0);
        assertEq(VaultV2(collateral).previewWithdraw(epochId, DEPOSIT_AMOUNT), AMOUNT_AFTER_FEE);

        //withdraw from vaults
        VaultV2(premium).withdraw(epochId, DEPOSIT_AMOUNT, USER, USER);
        VaultV2(collateral).withdraw(epochId, DEPOSIT_AMOUNT, USER, USER);

        //check vaults balance
        assertEq(VaultV2(premium).balanceOf(USER ,epochId), 0);
        assertEq(VaultV2(collateral).balanceOf(USER ,epochId), 0);

        //check user ERC20 balance
        assertEq(USER.balance, DEALT_AMOUNT);

        vm.stopPrank();
    }

    function testEndToEndDepeg() public {
        vm.startPrank(USER);

        vm.warp(begin - 10 days);
        //deal ether
        vm.deal(USER, DEALT_AMOUNT);

        //approve gov token
        MintableToken(UNDERLYING).approve(depegPremium, PREMIUM_DEPOSIT_AMOUNT);
        MintableToken(UNDERLYING).approve(depegCollateral, COLLAT_DEPOSIT_AMOUNT);

        //deposit in both vaults
        VaultV2(depegPremium).deposit(depegEpochId, PREMIUM_DEPOSIT_AMOUNT, USER);
        VaultV2(depegCollateral).deposit(depegEpochId, COLLAT_DEPOSIT_AMOUNT, USER);

        //check deposit balances
        assertEq(VaultV2(depegPremium).balanceOf(USER ,depegEpochId), PREMIUM_DEPOSIT_AMOUNT);
        assertEq(VaultV2(depegCollateral).balanceOf(USER ,depegEpochId), COLLAT_DEPOSIT_AMOUNT);

        //check user underlying balance
        assertEq(USER.balance, DEALT_AMOUNT);

        //warp to epoch begin
        vm.warp(begin + 1 hours);
        
        //trigger depeg
        controller.triggerDepeg(depegMarketId, depegEpochId);

        premiumShareValue = helperCalculateFeeAdjustedValue(VaultV2(depegCollateral).finalTVL(depegEpochId), fee);
        collateralShareValue = helperCalculateFeeAdjustedValue(VaultV2(depegPremium).finalTVL(depegEpochId), fee);

        //check vault balances on withdraw
        assertEq(premiumShareValue, VaultV2(depegPremium).previewWithdraw(depegEpochId, PREMIUM_DEPOSIT_AMOUNT));
        assertEq(collateralShareValue, VaultV2(depegCollateral).previewWithdraw(depegEpochId, COLLAT_DEPOSIT_AMOUNT));

        //withdraw from vaults
        VaultV2(depegPremium).withdraw(depegEpochId, PREMIUM_DEPOSIT_AMOUNT, USER, USER);
        VaultV2(depegCollateral).withdraw(depegEpochId, COLLAT_DEPOSIT_AMOUNT, USER, USER);

        //check vaults balance
        assertEq(VaultV2(depegPremium).balanceOf(USER ,depegEpochId), 0);
        assertEq(VaultV2(depegCollateral).balanceOf(USER ,depegEpochId), 0);

        //check user ERC20 balance
        assertEq(USER.balance, DEALT_AMOUNT);

        vm.stopPrank();
    }

    function helperCalculateFeeAdjustedValue(uint256 amount, uint16 fee) internal pure returns (uint256) {
        return amount - amount.mulDivUp(fee, 10000);
    }
}