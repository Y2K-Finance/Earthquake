// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/VaultFactory.sol";
import "../src/Controller.sol";

//forge script script/DeployContract.s.sol:ContractScript --rpc-url $ARBITRUM_RPC_URL  --private-key $PRIVATE_KEY --broadcast -vvvv
contract DeployScript is Script {

    VaultFactory vaultFactory;
    Controller controller;

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

    address public admin = 0xFB0a3A93e9acd461747e7D613eb3722d53B96613;

    int256 depegAAA = 99;
    int256 depegBBB = 97;
    int256 depegCCC = 95;
    //int256 depegPrice = 109;

    uint256 endEpoch;
    uint256 beginEpoch;
    
    function setUp() public {
        vaultFactory = new VaultFactory(admin,WETH,admin);
        controller = new Controller(address(vaultFactory),admin);

        vm.prank(admin);
        vaultFactory.setController(address(controller));

        endEpoch = block.timestamp + 30 days;
        beginEpoch = block.timestamp + 2 days;
    }

    function run() public {
        vm.startBroadcast();
        
        //create New Market

        // Create FRAX market
        //index 1
        vaultFactory.createNewMarket(50, tokenFRAX, depegAAA, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_99*SET");
        //index 2
        vaultFactory.createNewMarket(50, tokenFRAX, depegBBB, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_97*SET");
        //index 3
        vaultFactory.createNewMarket(50, tokenFRAX, depegCCC, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_95*SET");

        // Create MIM market
        //index 4
        vaultFactory.createNewMarket(50, tokenMIM, depegAAA, beginEpoch, endEpoch, oracleMIM, "y2kMIM_99*SET");
        //index 5
        vaultFactory.createNewMarket(50, tokenMIM, depegBBB, beginEpoch, endEpoch, oracleMIM, "y2kMIM_97*SET");
        //index 6
        vaultFactory.createNewMarket(50, tokenMIM, depegCCC, beginEpoch, endEpoch, oracleMIM, "y2kMIM_95*SET");

        // Create FEI market
        //index 7
        vaultFactory.createNewMarket(50, tokenFEI, depegAAA, beginEpoch, endEpoch, oracleFEI, "y2kFEI_99*SET");
        //index 8
        vaultFactory.createNewMarket(50, tokenFEI, depegBBB, beginEpoch, endEpoch, oracleFEI, "y2kFEI_97*SET");
        //index 9
        vaultFactory.createNewMarket(50, tokenFEI, depegCCC, beginEpoch, endEpoch, oracleFEI, "y2kFEI_95*SET");

        // Create USDC market
        //index 10
        vaultFactory.createNewMarket(50, tokenUSDC, depegAAA, beginEpoch, endEpoch, oracleUSDC, "y2kUSDC_99*SET");
        //index 11
        vaultFactory.createNewMarket(50, tokenUSDC, depegBBB, beginEpoch, endEpoch, oracleUSDC, "y2kUSDC_97*SET");
        //index 12
        vaultFactory.createNewMarket(50, tokenUSDC, depegCCC, beginEpoch, endEpoch, oracleUSDC, "y2kUSDC_95*SET");

        // Create DAI market
        //index 13
        vaultFactory.createNewMarket(50, tokenDAI, depegAAA, beginEpoch, endEpoch, oracleDAI, "y2kDAI_99*SET");
        //index 14
        vaultFactory.createNewMarket(50, tokenDAI, depegBBB, beginEpoch, endEpoch, oracleDAI, "y2kDAI_97*SET");
        //index 15
        vaultFactory.createNewMarket(50, tokenDAI, depegCCC, beginEpoch, endEpoch, oracleDAI, "y2kDAI_95*SET");

        //deploy More Assets

        // Deploy more FRAX market
        vaultFactory.deployMoreAssets(1, beginEpoch + 30 days, endEpoch + 30 days);
        vaultFactory.deployMoreAssets(2, beginEpoch + 30 days, endEpoch + 30 days);
        vaultFactory.deployMoreAssets(3, beginEpoch + 30 days, endEpoch + 30 days);

        // Deploy more MIM market
        vaultFactory.deployMoreAssets(4, beginEpoch + 30 days, endEpoch + 30 days);
        vaultFactory.deployMoreAssets(5, beginEpoch + 30 days, endEpoch + 30 days);
        vaultFactory.deployMoreAssets(6, beginEpoch + 30 days, endEpoch + 30 days);

        // Deploy more FEI market
        vaultFactory.deployMoreAssets(7, beginEpoch + 30 days, endEpoch + 30 days);
        vaultFactory.deployMoreAssets(8, beginEpoch + 30 days, endEpoch + 30 days);
        vaultFactory.deployMoreAssets(9, beginEpoch + 30 days, endEpoch + 30 days);

        // Deploy more USDC market
        vaultFactory.deployMoreAssets(10, beginEpoch + 30 days, endEpoch + 30 days);
        vaultFactory.deployMoreAssets(11, beginEpoch + 30 days, endEpoch + 30 days);
        vaultFactory.deployMoreAssets(12, beginEpoch + 30 days, endEpoch + 30 days);

        // Deploy more DAI market
        vaultFactory.deployMoreAssets(13, beginEpoch + 30 days, endEpoch + 30 days);
        vaultFactory.deployMoreAssets(14, beginEpoch + 30 days, endEpoch + 30 days);
        vaultFactory.deployMoreAssets(15, beginEpoch + 30 days, endEpoch + 30 days);

        vm.stopBroadcast();
    }
}
