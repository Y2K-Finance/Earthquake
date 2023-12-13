// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "./MintableToken.sol";
import {VaultV2} from "../../src/v2/VaultV2.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Helper is Test {
    event MarketAsserted(uint256 marketId, bytes32 assertionId);
    event AssertionResolved(bytes32 assertionId, bool assertion);
    event ProtocolFeeCollected(uint256 indexed epochId, uint256 indexed fee);
    event BondUpdated(uint256 newBond);
    event RewardUpdated(uint256 newReward);
    event MarketConditionSet(uint256 indexed marketId, uint256 conditionType);
    event CoverageStartUpdated(uint256 startTime);
    event AssertionDataUpdated(uint256 newData);
    event RelayerUpdated(address relayer, bool state);
    event DescriptionSet(uint256 marketId, string description);

    uint256 public constant STRIKE = 1000000000000000000;
    uint256 public constant COLLATERAL_MINUS_FEES = 21989999998398551453;
    uint256 public constant COLLATERAL_MINUS_FEES_DIV10 = 2198999999839855145;
    uint256 public constant NEXT_COLLATERAL_MINUS_FEES = 21827317001456829250;
    uint256 public constant USER1_EMISSIONS_AFTER_WITHDRAW =
        1096655439903230405190;
    uint256 public constant USER2_EMISSIONS_AFTER_WITHDRAW =
        96655439903230405190;
    uint256 public constant USER_AMOUNT_AFTER_WITHDRAW = 13112658495640855090;
    uint256 public constant AMOUNT_AFTER_FEE = 19.95 ether;
    uint256 public constant PREMIUM_DEPOSIT_AMOUNT = 2 ether;
    uint256 public constant COLLAT_DEPOSIT_AMOUNT = 10 ether;
    uint256 public constant PREMIUM_AFTER_FEE = 1.99 ether;
    uint256 public constant COLLAT_AFTER_FEE = 9.95 ether;
    uint256 public constant DEPOSIT_AMOUNT = 10 ether;
    uint256 public constant DEALT_AMOUNT = 20 ether;
    uint256 public constant TIME_OUT = 1 days;

    address public constant ADMIN = address(0x1);
    address public constant WETH = address(0x888);
    address public constant TREASURY = address(0x777);
    address public constant NOTADMIN = address(0x99);
    address public constant USER = 0xCCA23C05a9Cf7e78830F3fd55b1e8CfCCbc5E50F;
    address public constant USER2 = address(0x12312);
    address public constant ARBITRUM_SEQUENCER =
        0xFdB631F5EE196F0ed6FAa767959853A9F217697D;
    address public constant ARBITRUM_SEQUENCER_GOERLI =
        0x4da69F028a5790fCCAfe81a75C0D24f46ceCDd69;
    address public constant USDC_CHAINLINK =
        0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3;
    address public constant BTC_CHAINLINK =
        0x6ce185860a4963106506C203335A2910413708e9;
    address public constant ETH_VOL_CHAINLINK =
        0x1B8e08a5457b12ae3CbC4233e645AEE2fA809e39;
    address public constant USDC_TOKEN =
        0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address public constant VST_PRICE_FEED_GOERLI =
        0x449F0bC26B7Ad7b48DA2674Fb4030F0e9323b466;
    address public constant VST_PRICE_FEED =
        0xd2F9EB49F563aAacE73eb1D19305dD5812F33179;
    address public constant SECOND_PRICE_FEED = address(0x123);
    address public constant GDAI_VAULT =
        0xd85E038593d7A098614721EaE955EC2022B9B91B;
    address public constant DIA_ORACLE_V2 =
        0xd041478644048d9281f88558E6088e9da97df624;
    uint256 public constant DIA_DECIMALS = 18;
    address public constant CVI_ORACLE =
        0x649813B6dc6111D67484BaDeDd377D32e4505F85;
    uint256 public constant CVI_DECIMALS = 0;
    address public constant PYTH_CONTRACT =
        0xff1a0f4744e8582DF1aE09D5611b887B6a12925C;
    bytes32 public constant PYTH_FDUSD_FEED_ID =
        0xccdc1a08923e2e4f4b1e6ea89de6acbc5fe1948e9706f5604b8cb50bc1ed3979;
    address public constant RELAYER = address(0x55);
    address public UNDERLYING = address(0x123);
    address public TOKEN = address(new MintableToken("Token", "tkn"));
    address public WETH_ADDRESS = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    // keeper variables
    address public ops = 0xB3f5503f93d5Ef84b06993a1975B9D21B962892F;
    address public treasuryTask = 0xB2f34fd4C16e656163dADFeEaE4Ae0c1F13b140A;

    string public ARBITRUM_RPC_URL = vm.envString("ARBITRUM_RPC_URL");
    string public ARBITRUM_GOERLI_RPC_URL =
        vm.envString("ARBITRUM_GOERLI_RPC_URL");

    ////////////////////////////////////////////////
    //                Vault Helpers               //
    ////////////////////////////////////////////////
    function configureEndEpochState(
        address _premiumVault,
        address _collateralVault,
        uint256 _epochId,
        uint256 _begin,
        uint256 _end,
        uint256 _depositAmount
    ) public {
        vm.warp(_begin - 1 days);
        MintableToken(UNDERLYING).approve(_premiumVault, _depositAmount);
        MintableToken(UNDERLYING).approve(_collateralVault, _depositAmount);

        //deposit in both vaults
        VaultV2(_premiumVault).deposit(_epochId, _depositAmount, USER);
        VaultV2(_collateralVault).deposit(_epochId, _depositAmount, USER);

        //check deposit balances
        assertEq(
            VaultV2(_premiumVault).balanceOf(USER, _epochId),
            _depositAmount
        );
        assertEq(
            VaultV2(_collateralVault).balanceOf(USER, _epochId),
            _depositAmount
        );

        vm.warp(_end + 1 days);
    }

    function configureDepegState(
        address _premiumVault,
        address _collatVault,
        uint256 _epochId,
        uint256 _begin,
        uint256 _premiumDepositAmount,
        uint256 _collatDepositAmount
    ) public {
        vm.warp(_begin - 1 days);
        MintableToken(UNDERLYING).approve(_premiumVault, _premiumDepositAmount);
        MintableToken(UNDERLYING).approve(_collatVault, _collatDepositAmount);

        //deposit in both vaults
        VaultV2(_premiumVault).deposit(_epochId, _premiumDepositAmount, USER);
        VaultV2(_collatVault).deposit(_epochId, _collatDepositAmount, USER);

        //check deposit balances
        assertEq(
            VaultV2(_premiumVault).balanceOf(USER, _epochId),
            _premiumDepositAmount
        );
        assertEq(
            VaultV2(_collatVault).balanceOf(USER, _epochId),
            _collatDepositAmount
        );

        vm.warp(_begin + 1 hours);
    }
}
