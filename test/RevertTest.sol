// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "forge-std/Test.sol";
import {Vault} from "../src/Vault.sol";
import {VaultFactory} from "../src/VaultFactory.sol";
import {Controller} from "../src/Controller.sol";
import {PegOracle} from "../src/oracles/PegOracle.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";
import "@chainlink/interfaces/AggregatorV3Interface.sol";

import {FakeOracle} from "./oracles/FakeOracle.sol";
import {IWETH} from "./interfaces/IWETH.sol";

contract RevertTest is Test {
    
    VaultFactory vaultFactory;
    Controller controller;

    address WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

    address tokenFRAX = 0x17FC002b466eEc40DaE837Fc4bE5c67993ddBd6F;
    address tokenMIM = 0xFEa7a6a0B346362BF88A9e4A88416B77a57D6c2A;
    address tokenFEI = 0x4A717522566C7A09FD2774cceDC5A8c43C5F9FD2;
    address tokenUSDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address tokenDAI = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;
    address tokenSTETH = 0xEfa0dB536d2c8089685630fafe88CF7805966FC3;

    address oracleFRAX = 0x0809E3d38d1B4214958faf06D8b1B1a2b73f2ab8;
    address oracleMIM = 0x87121F6c9A9F6E90E59591E4Cf4804873f54A95b;
    address oracleFEI = 0x7c4720086E6feb755dab542c46DE4f728E88304d;
    address oracleUSDC = 0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3;
    address oracleDAI = 0xc5C8E77B397E531B8EC06BFb0048328B30E9eCfB;
    address oracleSTETH = 0x07C5b924399cc23c24a95c8743DE4006a32b7f2a;
    address oracleETH = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
    address linkFRAX = 0xB9E1E3A9feFf48998E45Fa90847ed4D467E8BcfD;

    address arbitrum_sequencer = 0xFdB631F5EE196F0ed6FAa767959853A9F217697D;

    address admin = address(1);

    address alice = address(2);
    address bob = address(3);
    address chad = address(4);
    address degen = address(5);

    int256 depegAAA = 99;
    int256 depegBBB = 97;
    int256 depegCCC = 95;

    uint256 endEpoch;
    uint256 beginEpoch;
    
    function setUp() public {
        vaultFactory = new VaultFactory(admin,WETH,admin);
        controller = new Controller(address(vaultFactory),admin, arbitrum_sequencer);

        vm.prank(admin);
        vaultFactory.setController(address(controller));

        endEpoch = block.timestamp + 30 days;
        beginEpoch = block.timestamp + 2 days;
    }

    function testDeployMoreAssetsRevert() public {
        //create fake oracle for price feed
        vm.startPrank(admin);
        FakeOracle fakeOracle = new FakeOracle(oracleFRAX, 90995265);
        vaultFactory.createNewMarket(50, tokenFRAX, depegAAA, beginEpoch, endEpoch, address(fakeOracle), "y2kFRAX_99*SET");
        vm.stopPrank();

        //expect MarketDoesNotExist
        vm.startPrank(admin);
        vm.expectRevert(abi.encodeWithSelector(VaultFactory.MarketDoesNotExist.selector, 3));
        vaultFactory.deployMoreAssets(3, beginEpoch, endEpoch);
        vm.stopPrank();

        //to-do: assertEquals between pre and post-revert variables

        
    }

    function testGetLatestPriceReverts() public {
        //create invalid controller(w/any address other than arbitrum_sequencer)
        controller = new Controller(address(vaultFactory),admin, oracleFEI);

        //create fake oracle for price feed
        vm.startPrank(admin);
        FakeOracle fakeOracle = new FakeOracle(oracleFRAX, 90995265);
        vaultFactory.createNewMarket(50, tokenFRAX, depegAAA, beginEpoch, endEpoch, address(fakeOracle), "y2kFRAX_99*SET");
        vm.stopPrank();

        //expect SequencerDown and GracePeriodNotOver
        vm.startPrank(admin);
        vm.expectRevert(Controller.SequencerDown.selector);
        controller.getLatestPrice(tokenFRAX);
        vm.stopPrank();

        //expect GracePeriodNotOver


        //to-do: 
        //use vm.warp() to force GracePeriodNotOver()
        //assertEquals between pre and post-revert variables
    }



}