// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Test.sol";
import {Vault} from "../src/Vault.sol";
import {VaultFactory} from "../src/VaultFactory.sol";
import {Controller} from "../src/Controller.sol";
import {PegOracle} from "../src/oracles/PegOracle.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";
import "@chainlink/interfaces/AggregatorV3Interface.sol";
import {Helper} from "./Helper.sol";

import {FakeOracle} from "./oracles/FakeOracle.sol";
import {IWETH} from "./interfaces/IWETH.sol";

contract RevertTest is Helper {

    function testDeployMoreAssetsRevert() public {
        //create fake oracle for price feed
        vm.startPrank(admin);
        FakeOracle fakeOracle = new FakeOracle(oracleFRAX, 90995265);
        vaultFactory.createNewMarket(50, tokenFRAX, depegAAA, beginEpoch, endEpoch, address(fakeOracle), "y2kFRAX_99*");
        vm.stopPrank();

        //expect MarketDoesNotExist
        vm.startPrank(admin);
        vm.expectRevert(abi.encodeWithSelector(VaultFactory.MarketDoesNotExist.selector, 3));
        vaultFactory.deployMoreAssets(3, beginEpoch, endEpoch, FEE);
        vm.stopPrank();

        //to-do: assertEquals between pre and post-revert variables

        
    }

    function testGetLatestPriceReverts() public {
        //to-do: find way to force SequencerDown()
        //use vm.warp() to force GracePeriodNotOver()
        //assertEquals between pre and post-revert variables
    }



}