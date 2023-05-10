// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Test.sol";
import {Vault} from "../../src/legacy_v1/Vault.sol";
import {VaultFactory, TimeLock} from "../../src/legacy_v1/VaultFactory.sol";
import {Controller} from "../../src/legacy_v1/Controller.sol";
import {RewardsFactory} from "../../src/legacy_v1/rewards/RewardsFactory.sol";
import {RewardBalances} from "../../src/legacy_v1/rewards/RewardBalances.sol";
import {GovToken} from "./GovToken.sol";

/// @author nexusflip

contract RewardsBalanceHelper is Test {

    Controller public controller;

    VaultFactory public vaultFactory;
    TimeLock public timelocker;

    RewardsFactory public rewardsFactory;
    RewardBalances public rewardBalances;
    GovToken public govToken;

    address public constant ARBITRUM_SEQUENCER = 0xFdB631F5EE196F0ed6FAa767959853A9F217697D;
    address public constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address public constant TOKEN_USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address public constant ORACLE_USDC = 0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3;

    address public constant ADMIN = address(1);
    address public constant ALICE = address(2);

    uint256 public constant SINGLE_MARKET_INDEX = 1;
    uint256 public constant FEE = 5;
    uint256 public constant BEGIN_DAYS = 2 days;
    uint256 public constant END_DAYS = 30 days;
    uint256 public constant AMOUNT = 10 ether;
    
    int256 public constant DEPEG_STRIKE = 995555555555555555;

    uint256 public beginEpoch;
    uint256 public endEpoch;
    uint256 public rewardsBal;
    uint256 public rewardDuration;
    uint256 public periodFinish;

    address public hedge;
    address public risk;
    address public hedgeAddr;
    address public riskAddr;
    address[] public farms;

    function setUp() public {
        vm.startPrank(ADMIN);

        vaultFactory = new VaultFactory(ADMIN,WETH,ADMIN);
        controller = new Controller(address(vaultFactory), ARBITRUM_SEQUENCER);
        vaultFactory.setController(address(controller));
        timelocker = vaultFactory.timelocker();

        endEpoch = block.timestamp + END_DAYS;
        beginEpoch = block.timestamp + BEGIN_DAYS;

        govToken = new GovToken();
        rewardsFactory = new RewardsFactory(address(govToken), address(vaultFactory));

        (hedge, risk) = vaultFactory.createNewMarket(FEE, TOKEN_USDC, DEPEG_STRIKE, beginEpoch, endEpoch, ORACLE_USDC, "y2kUSDC_991*");
        (hedgeAddr, riskAddr) = rewardsFactory.createStakingRewards(SINGLE_MARKET_INDEX, endEpoch);

        farms.push(0x05f318Ed71F42848E5a3f249805e51520D77c654);
        farms.push(0x07EDb0ed167CDF787e0C7Cb212cF2b60CEbc4a70);
        rewardBalances = new RewardBalances(farms);
        
        govToken.moneyPrinterGoesBrr(hedgeAddr);
        govToken.moneyPrinterGoesBrr(riskAddr);
        
        vm.stopPrank();
    }
}