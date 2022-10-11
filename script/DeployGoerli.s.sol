// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/VaultFactory.sol";
import "../src/Controller.sol";
import "../src/rewards/RewardsFactory.sol";
import "../test/GovToken.sol";
import "../test/oracles/DepegOracle.sol";
import "../src/rewards/StakingRewards.sol";

/*
forge script script/DeployGoerli.s.sol:DeployGoerliScript --rpc-url $ARBITRUM_GOERLI_RPC_URL  --private-key $PRIVATE_KEY --broadcast -vv
*/
contract DeployGoerliScript is Script {

    VaultFactory vaultFactory;
    Controller controller;
    RewardsFactory rewardsFactory;
    GovToken govToken;
    DepegOracle depegOracle;

    address WETH = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;

    address tokenUSDC = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;
    address tokenDAI = 0x4dCf5ac4509888714dd43A5cCc46d7ab389D9c23;

    address oracleUSDC = 0xAb5c49580294Aff77670F839ea425f5b78ab3Ae7;
    address oracleDAI = 0x0d79df66BE487753B02D015Fb622DED7f0E9798d;

    address arbitrum_sequencer = 0x9912bb73e2aD6aEa14d8D72d5826b8CBE3b6c4E2;


    address public admin = 0xFB0a3A93e9acd461747e7D613eb3722d53B96613;

    int256 depegAAA = 990000000000000000;
    int256 depegBBB = 970000000000000000;
    int256 depegCCC = 950000000000000000;
    //int256 depegPrice = 109;

    uint256 endEpoch;
    uint256 nextEpoch;

    uint256 beginEpoch;
    uint256 nextBegin;

    uint256 FEE = 55;

    function run() public {
        vm.startBroadcast();

        // setUp();
        vaultFactory = new VaultFactory(admin,WETH, admin);
        controller = new Controller(address(vaultFactory), arbitrum_sequencer);

        vaultFactory.setController(address(controller));

        govToken = new GovToken();

        rewardsFactory = new RewardsFactory(address(govToken), address(vaultFactory));

        //depegOracle = new DepegOracle(oracleDAI, admin);
                
        console2.log("Controller address", address(controller));
        console2.log("Vault Factory address", address(vaultFactory));
        console2.log("Rewards Factory address", address(rewardsFactory));
        console2.log("GovToken address", address(govToken));
        //console2.log("DepegOracle address", address(depegOracle));

        beginEpoch = block.timestamp + 3 days;
        endEpoch = beginEpoch + 7 days;
        
        nextBegin = endEpoch + 7 days;
        nextEpoch = nextBegin + 7 days;
        
        //create New Market and respective farms
        // Create USDC market
        //index 1
        vaultFactory.createNewMarket(FEE, tokenUSDC, depegAAA, beginEpoch, endEpoch, oracleUSDC, "y2kUSDC_99*");
        (address rHedge, address rRisk) = rewardsFactory.createStakingRewards(1, endEpoch);
        //sending gov tokens to farms
        govToken.moneyPrinterGoesBrr(rHedge);
        govToken.moneyPrinterGoesBrr(rRisk);
        StakingRewards(rHedge).notifyRewardAmount(govToken.balanceOf(rHedge));
        StakingRewards(rRisk).notifyRewardAmount(govToken.balanceOf(rRisk));

        //index 2
        vaultFactory.createNewMarket(FEE, tokenUSDC, depegBBB, beginEpoch, endEpoch, oracleUSDC, "y2kUSDC_97*");
        (rHedge, rRisk) = rewardsFactory.createStakingRewards(2, endEpoch);
                //sending gov tokens to farms
        govToken.moneyPrinterGoesBrr(rHedge);
        govToken.moneyPrinterGoesBrr(rRisk);
        StakingRewards(rHedge).notifyRewardAmount(govToken.balanceOf(rHedge));
        StakingRewards(rRisk).notifyRewardAmount(govToken.balanceOf(rRisk));

        //index 3
        vaultFactory.createNewMarket(FEE, tokenUSDC, depegCCC, beginEpoch, endEpoch, oracleUSDC, "y2kUSDC_95*");
        (rHedge, rRisk) = rewardsFactory.createStakingRewards(3, endEpoch);
                //sending gov tokens to farms
        govToken.moneyPrinterGoesBrr(rHedge);
        govToken.moneyPrinterGoesBrr(rRisk);
        StakingRewards(rHedge).notifyRewardAmount(govToken.balanceOf(rHedge));
        StakingRewards(rRisk).notifyRewardAmount(govToken.balanceOf(rRisk));

        // Create DAI market
        //index 4
        vaultFactory.createNewMarket(FEE, tokenDAI, depegAAA, beginEpoch, endEpoch, oracleDAI, "y2kDAI_99*");
        (rHedge, rRisk) = rewardsFactory.createStakingRewards(4, endEpoch);
                //sending gov tokens to farms
        govToken.moneyPrinterGoesBrr(rHedge);
        govToken.moneyPrinterGoesBrr(rRisk);
        StakingRewards(rHedge).notifyRewardAmount(govToken.balanceOf(rHedge));
        StakingRewards(rRisk).notifyRewardAmount(govToken.balanceOf(rRisk));

        //index 5
        vaultFactory.createNewMarket(FEE, tokenDAI, depegBBB, beginEpoch, endEpoch, oracleDAI, "y2kDAI_97*");
        (rHedge, rRisk) = rewardsFactory.createStakingRewards(5, endEpoch);
                //sending gov tokens to farms
        govToken.moneyPrinterGoesBrr(rHedge);
        govToken.moneyPrinterGoesBrr(rRisk);
        StakingRewards(rHedge).notifyRewardAmount(govToken.balanceOf(rHedge));
        StakingRewards(rRisk).notifyRewardAmount(govToken.balanceOf(rRisk));

        //index 6
        vaultFactory.createNewMarket(FEE, tokenDAI, depegCCC, beginEpoch, endEpoch, oracleDAI, "y2kDAI_95*");
        (rHedge, rRisk) = rewardsFactory.createStakingRewards(6, endEpoch);
                //sending gov tokens to farms
        govToken.moneyPrinterGoesBrr(rHedge);
        govToken.moneyPrinterGoesBrr(rRisk);
        StakingRewards(rHedge).notifyRewardAmount(govToken.balanceOf(rHedge));
        StakingRewards(rRisk).notifyRewardAmount(govToken.balanceOf(rRisk));

        //deploy More Assets and respective farms
        // Deploy more USDC market

        vaultFactory.deployMoreAssets(1, nextBegin, nextEpoch, FEE);
        (rHedge, rRisk) = rewardsFactory.createStakingRewards(1, nextEpoch);
                //sending gov tokens to farms
        govToken.moneyPrinterGoesBrr(rHedge);
        govToken.moneyPrinterGoesBrr(rRisk);
        StakingRewards(rHedge).notifyRewardAmount(govToken.balanceOf(rHedge));
        StakingRewards(rRisk).notifyRewardAmount(govToken.balanceOf(rRisk));


        vaultFactory.deployMoreAssets(2, nextBegin, nextEpoch, FEE);
        (rHedge, rRisk) = rewardsFactory.createStakingRewards(2, nextEpoch);
                //sending gov tokens to farms
        govToken.moneyPrinterGoesBrr(rHedge);
        govToken.moneyPrinterGoesBrr(rRisk);
        StakingRewards(rHedge).notifyRewardAmount(govToken.balanceOf(rHedge));
        StakingRewards(rRisk).notifyRewardAmount(govToken.balanceOf(rRisk));
        
        vaultFactory.deployMoreAssets(3, nextBegin, nextEpoch, FEE);
        (rHedge, rRisk) = rewardsFactory.createStakingRewards(3, nextEpoch);
                //sending gov tokens to farms
        govToken.moneyPrinterGoesBrr(rHedge);
        govToken.moneyPrinterGoesBrr(rRisk);
        StakingRewards(rHedge).notifyRewardAmount(govToken.balanceOf(rHedge));
        StakingRewards(rRisk).notifyRewardAmount(govToken.balanceOf(rRisk));

        // Deploy more DAI market
        vaultFactory.deployMoreAssets(4, nextBegin, nextEpoch, FEE);
        (rHedge, rRisk) = rewardsFactory.createStakingRewards(4, nextEpoch);
                //sending gov tokens to farms
        govToken.moneyPrinterGoesBrr(rHedge);
        govToken.moneyPrinterGoesBrr(rRisk);
        StakingRewards(rHedge).notifyRewardAmount(govToken.balanceOf(rHedge));
        StakingRewards(rRisk).notifyRewardAmount(govToken.balanceOf(rRisk));

        vaultFactory.deployMoreAssets(5, nextBegin, nextEpoch, FEE);
        (rHedge, rRisk) = rewardsFactory.createStakingRewards(5, nextEpoch);
                //sending gov tokens to farms
        govToken.moneyPrinterGoesBrr(rHedge);
        govToken.moneyPrinterGoesBrr(rRisk);
        StakingRewards(rHedge).notifyRewardAmount(govToken.balanceOf(rHedge));
        StakingRewards(rRisk).notifyRewardAmount(govToken.balanceOf(rRisk));

        vaultFactory.deployMoreAssets(6, nextBegin, nextEpoch, FEE);
        (rHedge, rRisk) = rewardsFactory.createStakingRewards(6, nextEpoch);
                //sending gov tokens to farms
        govToken.moneyPrinterGoesBrr(rHedge);
        govToken.moneyPrinterGoesBrr(rRisk);
        StakingRewards(rHedge).notifyRewardAmount(govToken.balanceOf(rHedge));
        StakingRewards(rRisk).notifyRewardAmount(govToken.balanceOf(rRisk));

        vm.stopBroadcast();
    }
}
