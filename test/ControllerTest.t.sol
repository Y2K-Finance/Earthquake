// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Test.sol";
import {Vault} from "../src/Vault.sol";
import {VaultFactory, TimeLock} from "../src/VaultFactory.sol";
import {Controller} from "../src/Controller.sol";
import {PegOracle} from "../src/oracles/PegOracle.sol";
import {StakingRewards} from "../src/rewards/StakingRewards.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";
import "@chainlink/interfaces/AggregatorV3Interface.sol";
import {ControllerHelper} from "./ControllerHelper.sol";
import {RewardBalances} from "../src/rewards/RewardBalances.sol";

import {FakeOracle} from "./oracles/FakeOracle.sol";
import {FakeFakeOracle} from "./oracles/FakeFakeOracle.sol";
import {DepegOracle} from "./oracles/DepegOracle.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract ControllerTest is ControllerHelper {
    /*///////////////////////////////////////////////////////////////
                           ASSERT cases
    //////////////////////////////////////////////////////////////*/

    function testControllerDepeg() public{

        DepositDepeg();

        vm.warp(beginEpoch + 10 days);

        emit log_named_int("strike price", vHedge.strikePrice());
        emit log_named_int("oracle price", controller.getLatestPrice(tokenFRAX));
        assertTrue(controller.getLatestPrice(tokenFRAX) > 900000000000000000 && controller.getLatestPrice(tokenFRAX) < 1000000000000000000);
        assertTrue(vHedge.strikePrice() > 900000000000000000 && controller.getLatestPrice(tokenFRAX) < 1000000000000000000);

        controller.triggerDepeg(SINGLE_MARKET_INDEX, endEpoch);

        assertTrue(vHedge.totalAssets(endEpoch) == vRisk.idClaimTVL(endEpoch), "Claim TVL Risk not equal to Total Tvl Hedge");
        assertTrue(vRisk.totalAssets(endEpoch) == vHedge.idClaimTVL(endEpoch), "Claim TVL Hedge not equal to Total Tvl Risk");
    }

    /*function testControllerEndEpoch() public{

        testDeposit();

        vm.warp(endEpoch + 1 days);

        emit log_named_int("strike price", vHedge.strikePrice());
        emit log_named_int("oracle price", controller.getLatestPrice(tokenFRAX));

        controller.triggerEndEpoch(SINGLE_MARKET_INDEX, endEpoch);
        
        emit log_named_uint("total assets value", vHedge.totalAssets(endEpoch));
        
        assertTrue(vRisk.idClaimTVL(endEpoch) == vHedge.idFinalTVL(endEpoch) + vRisk.idFinalTVL(endEpoch), "Claim TVL not total");
        assertTrue(NULL_BALANCE == vHedge.idClaimTVL(endEpoch), "Hedge Claim TVL not zero");
    }*/

    function testCreateController() public {
        Controller testController = new Controller(address(vaultFactory), arbitrum_sequencer);
        assertEq(address(vaultFactory), address(testController.vaultFactory()));
    }

    function testTriggerEndEpoch() public {
        DepositDepeg();

        vm.startPrank(admin);

        Controller testController = new Controller(address(vaultFactory), arbitrum_sequencer);
        vaultFactory.setController(address(testController));

        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_99*");

        vm.warp(endEpoch + 1 days);
        controller.triggerEndEpoch(SINGLE_MARKET_INDEX, endEpoch);

        VaultFactory testFactory = controller.vaultFactory();
        assertEq(vaultFactory.getVaults(vaultFactory.marketIndex()), testFactory.getVaults(testFactory.marketIndex()));
        vm.stopPrank();
    }

    function testNullEpochHedge() public {

        vm.startPrank(admin);
        vm.deal(degen, AMOUNT);
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_99*");
        vm.stopPrank();

        emit log_named_uint("WETH balance", ERC20(WETH).balanceOf(degen));
        vm.startPrank(degen);
        vHedge.depositETH{value: AMOUNT}(endEpoch, degen);
        vm.stopPrank();

        emit log_named_uint("WETH balance", ERC20(WETH).balanceOf(hedge));

        vm.warp(vHedge.idEpochBegin(endEpoch));
        controller.triggerNullEpoch(vaultFactory.marketIndex(), endEpoch);
        assertTrue(vHedge.idClaimTVL(endEpoch) == AMOUNT && vRisk.idClaimTVL(endEpoch) == 0, "Claim TVL not zero");
        assertTrue(vHedge.idFinalTVL(endEpoch) == AMOUNT && vRisk.idFinalTVL(endEpoch) == 0, "Final TVL not zero");
        assertTrue(vHedge.totalAssets(endEpoch) == AMOUNT && vRisk.totalAssets(endEpoch) == 0, "Total TVL not zero");

        vm.startPrank(degen);
        vHedge.withdraw(endEpoch, AMOUNT, degen, degen);
        vm.stopPrank();

        assertTrue(ERC20(WETH).balanceOf(degen) == AMOUNT, "WETH not returned");
        emit log_named_uint("WETH balance", ERC20(WETH).balanceOf(degen));
    }

    function testNullEpochRisk() public {

        vm.startPrank(admin);
        vm.deal(degen, AMOUNT);
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_99*");
        vm.stopPrank();
        
        emit log_named_uint("WETH balance", ERC20(WETH).balanceOf(degen));
        vm.startPrank(degen);
        vRisk.depositETH{value: AMOUNT}(endEpoch, degen);
        vm.stopPrank();

        vm.warp(vRisk.idEpochBegin(endEpoch));
        controller.triggerNullEpoch(vaultFactory.marketIndex(), endEpoch);

        assertTrue(vRisk.idClaimTVL(endEpoch) == AMOUNT && vHedge.idClaimTVL(endEpoch) == 0, "Claim TVL not zero");
        assertTrue(vRisk.idFinalTVL(endEpoch) == AMOUNT && vHedge.idFinalTVL(endEpoch) == 0, "Final TVL not zero");
        assertTrue(vRisk.totalAssets(endEpoch) == AMOUNT && vHedge.totalAssets(endEpoch) == 0, "Total TVL not zero");
        
        emit log_named_uint("WETH balance", ERC20(WETH).balanceOf(risk));

        vm.startPrank(degen);
        vRisk.withdraw(endEpoch, AMOUNT, degen, degen);
        vm.stopPrank();

        assertTrue(ERC20(WETH).balanceOf(degen) == AMOUNT, "WETH not returned");
        emit log_named_uint("WETH balance", ERC20(WETH).balanceOf(degen));
    }
}