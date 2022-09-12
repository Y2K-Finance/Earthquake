// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/VaultFactory.sol";
import "../src/Controller.sol";
import "../src/rewards/RewardsFactory.sol";
import "../test/GovToken.sol";

//forge script script/DeployContract.s.sol:ContractScript --rpc-url $ARBITRUM_RPC_URL  --private-key $PRIVATE_KEY --broadcast -vv
contract DeployScript is Script {

    VaultFactory vaultFactory;
    Controller controller;
    RewardsFactory rewardsFactory;
    GovToken govToken;

    address WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

    address tokenFRAX = 0x17FC002b466eEc40DaE837Fc4bE5c67993ddBd6F;
    address tokenMIM = 0xFEa7a6a0B346362BF88A9e4A88416B77a57D6c2A;
    address tokenFEI = 0x4A717522566C7A09FD2774cceDC5A8c43C5F9FD2;
    address tokenUSDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address tokenDAI = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;

    address oracleFRAX = 0x0809E3d38d1B4214958faf06D8b1B1a2b73f2ab8;
    address oracleMIM = 0x87121F6c9A9F6E90E59591E4Cf4804873f54A95b;
    address oracleFEI = 0x7c4720086E6feb755dab542c46DE4f728E88304d;
    address oracleUSDC = 0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3;
    address oracleDAI = 0xc5C8E77B397E531B8EC06BFb0048328B30E9eCfB;

    address arbitrum_sequencer = 0xFdB631F5EE196F0ed6FAa767959853A9F217697D;


    address public admin = 0xFB0a3A93e9acd461747e7D613eb3722d53B96613;

    int256 depegAAA = 995555555555555555;
    int256 depegBBB = 975555555555555555;
    int256 depegCCC = 955555555555555555;
    //int256 depegPrice = 109;

    uint256 FEE = 55;

    uint256 endEpoch;
    uint256 nextEpoch;

    uint256 beginEpoch;
    uint256 nextBegin;

    uint256 rewardsDuration = 10 days;
    uint256 rewardRate = 10;
    
    function setUp() public {
        vaultFactory = new VaultFactory(admin,WETH,admin);
        controller = new Controller(address(vaultFactory),admin, arbitrum_sequencer);

        vm.prank(admin);
        vaultFactory.setController(address(controller));

        govToken = new GovToken();

        rewardsFactory = new RewardsFactory(address(govToken), address(vaultFactory), admin);

        endEpoch = block.timestamp + 30 days;
        beginEpoch = block.timestamp + 2 days;

        nextEpoch = endEpoch + 30 days;
        nextBegin = beginEpoch + 30 days;

        console2.log("Controller address", address(controller));
        console2.log("Vault Factory address", address(vaultFactory));
        console2.log("Rewards Factory address", address(rewardsFactory));
    }

    function run() public {
        vm.startBroadcast();
        
        //create New Market

        // Create FRAX market
        //index 1
        vaultFactory.createNewMarket(FEE, tokenFRAX, depegAAA, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_99*");
        rewardsFactory.createStakingRewards(1, endEpoch, rewardsDuration, rewardRate);

        //index 2
        vaultFactory.createNewMarket(FEE, tokenFRAX, depegBBB, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_97*");
        rewardsFactory.createStakingRewards(2, endEpoch, rewardsDuration, rewardRate);

        //index 3
        vaultFactory.createNewMarket(FEE, tokenFRAX, depegCCC, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_95*");
        rewardsFactory.createStakingRewards(3, endEpoch, rewardsDuration, rewardRate);

        // Create MIM market
        //index 4
        vaultFactory.createNewMarket(FEE, tokenMIM, depegAAA, beginEpoch, endEpoch, oracleMIM, "y2kMIM_99*");
        rewardsFactory.createStakingRewards(4, endEpoch, rewardsDuration, rewardRate);

        //index 5
        vaultFactory.createNewMarket(FEE, tokenMIM, depegBBB, beginEpoch, endEpoch, oracleMIM, "y2kMIM_97*");
        rewardsFactory.createStakingRewards(5, endEpoch, rewardsDuration, rewardRate);

        //index 6
        vaultFactory.createNewMarket(FEE, tokenMIM, depegCCC, beginEpoch, endEpoch, oracleMIM, "y2kMIM_95*");
        rewardsFactory.createStakingRewards(6, endEpoch, rewardsDuration, rewardRate);

        // Create FEI market
        //index 7
        vaultFactory.createNewMarket(FEE, tokenFEI, depegAAA, beginEpoch, endEpoch, oracleFEI, "y2kFEI_99*");
        rewardsFactory.createStakingRewards(7, endEpoch, rewardsDuration, rewardRate);

        //index 8
        vaultFactory.createNewMarket(FEE, tokenFEI, depegBBB, beginEpoch, endEpoch, oracleFEI, "y2kFEI_97*");
        rewardsFactory.createStakingRewards(8, endEpoch, rewardsDuration, rewardRate);

        //index 9
        vaultFactory.createNewMarket(FEE, tokenFEI, depegCCC, beginEpoch, endEpoch, oracleFEI, "y2kFEI_95*");
        rewardsFactory.createStakingRewards(9, endEpoch, rewardsDuration, rewardRate);

        // Create USDC market
        //index 10
        vaultFactory.createNewMarket(FEE, tokenUSDC, depegAAA, beginEpoch, endEpoch, oracleUSDC, "y2kUSDC_99*");
        rewardsFactory.createStakingRewards(10, endEpoch, rewardsDuration, rewardRate);

        //index 11
        vaultFactory.createNewMarket(FEE, tokenUSDC, depegBBB, beginEpoch, endEpoch, oracleUSDC, "y2kUSDC_97*");
        rewardsFactory.createStakingRewards(11, endEpoch, rewardsDuration, rewardRate);

        //index 12
        vaultFactory.createNewMarket(FEE, tokenUSDC, depegCCC, beginEpoch, endEpoch, oracleUSDC, "y2kUSDC_95*");
        rewardsFactory.createStakingRewards(12, endEpoch, rewardsDuration, rewardRate);

        // Create DAI market
        //index 13
        vaultFactory.createNewMarket(FEE, tokenDAI, depegAAA, beginEpoch, endEpoch, oracleDAI, "y2kDAI_99*");
        rewardsFactory.createStakingRewards(13, endEpoch, rewardsDuration, rewardRate);

        //index 14
        vaultFactory.createNewMarket(FEE, tokenDAI, depegBBB, beginEpoch, endEpoch, oracleDAI, "y2kDAI_97*");
        rewardsFactory.createStakingRewards(14, endEpoch, rewardsDuration, rewardRate);

        //index 15
        vaultFactory.createNewMarket(FEE, tokenDAI, depegCCC, beginEpoch, endEpoch, oracleDAI, "y2kDAI_95*");
        rewardsFactory.createStakingRewards(15, endEpoch, rewardsDuration, rewardRate);

        //deploy More Assets

        // Deploy more FRAX market
        vaultFactory.deployMoreAssets(1, nextBegin, nextEpoch, FEE);
        rewardsFactory.createStakingRewards(1, nextEpoch, rewardsDuration, rewardRate);

        vaultFactory.deployMoreAssets(2, nextBegin, nextEpoch, FEE);
        rewardsFactory.createStakingRewards(2, nextEpoch, rewardsDuration, rewardRate);

        vaultFactory.deployMoreAssets(3, nextBegin, nextEpoch, FEE);
        rewardsFactory.createStakingRewards(3, nextEpoch, rewardsDuration, rewardRate);

        // Deploy more MIM market
        vaultFactory.deployMoreAssets(4, nextBegin, nextEpoch, FEE);
        rewardsFactory.createStakingRewards(4, nextEpoch, rewardsDuration, rewardRate);

        vaultFactory.deployMoreAssets(5, nextBegin, nextEpoch, FEE);
        rewardsFactory.createStakingRewards(5, nextEpoch, rewardsDuration, rewardRate);

        vaultFactory.deployMoreAssets(6, nextBegin, nextEpoch, FEE);
        rewardsFactory.createStakingRewards(6, nextEpoch, rewardsDuration, rewardRate);

        // Deploy more FEI market
        vaultFactory.deployMoreAssets(7, nextBegin, nextEpoch, FEE);
        rewardsFactory.createStakingRewards(7, nextEpoch, rewardsDuration, rewardRate);

        vaultFactory.deployMoreAssets(8, nextBegin, nextEpoch, FEE);
        rewardsFactory.createStakingRewards(8, nextEpoch, rewardsDuration, rewardRate);

        vaultFactory.deployMoreAssets(9, nextBegin, nextEpoch, FEE);
        rewardsFactory.createStakingRewards(9, nextEpoch, rewardsDuration, rewardRate);

        // Deploy more USDC market
        vaultFactory.deployMoreAssets(10, nextBegin, nextEpoch, FEE);
        rewardsFactory.createStakingRewards(10, nextEpoch, rewardsDuration, rewardRate);

        vaultFactory.deployMoreAssets(11, nextBegin, nextEpoch, FEE);
        rewardsFactory.createStakingRewards(11, nextEpoch, rewardsDuration, rewardRate);
        
        vaultFactory.deployMoreAssets(12, nextBegin, nextEpoch, FEE);
        rewardsFactory.createStakingRewards(12, nextEpoch, rewardsDuration, rewardRate);

        // Deploy more DAI market
        vaultFactory.deployMoreAssets(13, nextBegin, nextEpoch, FEE);
        rewardsFactory.createStakingRewards(13, nextEpoch, rewardsDuration, rewardRate);

        vaultFactory.deployMoreAssets(14, nextBegin, nextEpoch, FEE);
        rewardsFactory.createStakingRewards(14, nextEpoch, rewardsDuration, rewardRate);

        vaultFactory.deployMoreAssets(15, nextBegin, nextEpoch, FEE);
        rewardsFactory.createStakingRewards(15, nextEpoch, rewardsDuration, rewardRate);

        vm.stopBroadcast();
    }
}
