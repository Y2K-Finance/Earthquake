// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Test.sol";
import {Vault} from "../src/Vault.sol";
import {VaultFactory, TimeLock} from "../src/VaultFactory.sol";
import {Controller} from "../src/Controller.sol";
import {RewardsFactory} from "../src/rewards/RewardsFactory.sol";
import {RewardBalances} from "../src/rewards/RewardBalances.sol";
import {GovToken} from "./GovToken.sol";

/// @author nexusflip

contract RewardsBalanceHelper is Test {

    uint256 beginEpoch;
    uint256 endEpoch;
    uint256 rewardsBal;
    uint256 rewardDuration;
    uint256 periodFinish;

    address[] farms;

    address hedge;
    address risk;
    address hedgeAddr;
    address riskAddr;

    address constant admin = address(1);
    address constant alice = address(2);
    address constant arbitrum_sequencer = 0xFdB631F5EE196F0ed6FAa767959853A9F217697D;
    address constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address constant tokenUSDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address constant oracleUSDC = 0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3;

    uint256 constant SINGLE_MARKET_INDEX = 1;
    uint256 constant FEE = 5;
    uint256 constant BEGIN_DAYS = 2 days;
    uint256 constant END_DAYS = 30 days;
    uint256 constant AMOUNT = 10 ether;
    int256 constant DEPEG_STRIKE = 995555555555555555;

    Controller controller;
    VaultFactory vaultFactory;
    RewardsFactory rewardsFactory;
    RewardBalances rewardBalances;
    GovToken govToken;
    TimeLock timelocker;

    function setUp() public {
        vm.startPrank(admin);

        vaultFactory = new VaultFactory(admin,WETH,admin);
        controller = new Controller(address(vaultFactory), arbitrum_sequencer);
        vaultFactory.setController(address(controller));
        timelocker = vaultFactory.timelocker();

        endEpoch = block.timestamp + END_DAYS;
        beginEpoch = block.timestamp + BEGIN_DAYS;

        govToken = new GovToken();
        rewardsFactory = new RewardsFactory(address(govToken), address(vaultFactory));

        (hedge, risk) = vaultFactory.createNewMarket(FEE, tokenUSDC, DEPEG_STRIKE, beginEpoch, endEpoch, oracleUSDC, "y2kUSDC_991*");
        (hedgeAddr, riskAddr) = rewardsFactory.createStakingRewards(SINGLE_MARKET_INDEX, endEpoch);

        farms.push(0x05f318Ed71F42848E5a3f249805e51520D77c654);
        farms.push(0x07EDb0ed167CDF787e0C7Cb212cF2b60CEbc4a70);
        rewardBalances = new RewardBalances(farms);
        
        govToken.moneyPrinterGoesBrr(hedgeAddr);
        govToken.moneyPrinterGoesBrr(riskAddr);
        
        vm.stopPrank();
    }
}