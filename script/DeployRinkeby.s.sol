// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/VaultFactory.sol";
import "../src/Controller.sol";
import "../src/rewards/RewardsFactory.sol";
import "../test/GovToken.sol";

/*
forge script script/DeployRinkeby.s.sol:DeployRinkebyScript --rpc-url $ARBITRUM_RINKEBY_RPC_URL  --private-key $PRIVATE_KEY --broadcast -vvvv
*/
contract DeployRinkebyScript is Script {

    VaultFactory vaultFactory;
    Controller controller;
    RewardsFactory rewardsFactory;
    GovToken govToken;

    address WETH = 0x207eD1742cc0BeBD03E50e855d3a14E41f93A461;

    address tokenUSDC = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;
    address tokenDAI = 0x4dCf5ac4509888714dd43A5cCc46d7ab389D9c23;

    address oracleUSDC = 0x5f0423B1a6935dc5596e7A24d98532b67A0AeFd8;
    address oracleDAI = 0x3e3546c6b5689f7EAa1BA7Bc9571322c3168D786;

    address arbitrum_sequencer = 0x9912bb73e2aD6aEa14d8D72d5826b8CBE3b6c4E2;


    address public admin = 0xFB0a3A93e9acd461747e7D613eb3722d53B96613;

    int256 depegAAA = 99;
    int256 depegBBB = 97;
    int256 depegCCC = 95;
    //int256 depegPrice = 109;

    uint256 endEpoch;
    uint256 nextEpoch;

    uint256 beginEpoch;
    uint256 nextBegin;
    
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
    }

    function run() public {
        vm.startBroadcast();

        // setUp();
        
        //create New Market and respective farms
        // Create USDC market
        //index 1
        vaultFactory.createNewMarket(50, tokenUSDC, depegAAA, beginEpoch, endEpoch, oracleUSDC, "y2kUSDC_99*SET");
        rewardsFactory.createStakingRewards(1, endEpoch);

        //index 2
        vaultFactory.createNewMarket(50, tokenUSDC, depegBBB, beginEpoch, endEpoch, oracleUSDC, "y2kUSDC_97*SET");
        rewardsFactory.createStakingRewards(2, endEpoch);

        //index 3
        vaultFactory.createNewMarket(50, tokenUSDC, depegCCC, beginEpoch, endEpoch, oracleUSDC, "y2kUSDC_95*SET");
        rewardsFactory.createStakingRewards(3, endEpoch);

        // Create DAI market
        //index 4
        vaultFactory.createNewMarket(50, tokenDAI, depegAAA, beginEpoch, endEpoch, oracleDAI, "y2kDAI_99*SET");
        rewardsFactory.createStakingRewards(4, endEpoch);

        //index 5
        vaultFactory.createNewMarket(50, tokenDAI, depegBBB, beginEpoch, endEpoch, oracleDAI, "y2kDAI_97*SET");
        rewardsFactory.createStakingRewards(5, endEpoch);

        //index 6
        vaultFactory.createNewMarket(50, tokenDAI, depegCCC, beginEpoch, endEpoch, oracleDAI, "y2kDAI_95*SET");
        rewardsFactory.createStakingRewards(6, endEpoch);

        //deploy More Assets and respective farms
        // Deploy more USDC market
        vaultFactory.deployMoreAssets(1, nextBegin, nextEpoch);
        rewardsFactory.createStakingRewards(1, nextEpoch);

        vaultFactory.deployMoreAssets(2, nextBegin, nextEpoch);
        rewardsFactory.createStakingRewards(2, nextEpoch);
        
        vaultFactory.deployMoreAssets(3, nextBegin, nextEpoch);
        rewardsFactory.createStakingRewards(3, nextEpoch);

        // Deploy more DAI market
        vaultFactory.deployMoreAssets(4, nextBegin, nextEpoch);
        rewardsFactory.createStakingRewards(4, nextEpoch);

        vaultFactory.deployMoreAssets(5, nextBegin, nextEpoch);
        rewardsFactory.createStakingRewards(5, nextEpoch);

        vaultFactory.deployMoreAssets(6, nextBegin, nextEpoch);
        rewardsFactory.createStakingRewards(6, nextEpoch);

        vm.stopBroadcast();
    }
}
