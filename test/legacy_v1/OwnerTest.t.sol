// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import {Vault} from "../../src/legacy_v1/Vault.sol";
import {VaultFactory} from "../../src/legacy_v1/VaultFactory.sol";
import {Controller} from "../../src/legacy_v1/Controller.sol";
import {OwnerHelper} from "./OwnerHelper.sol";
import {FakeOracle} from "../oracles/FakeOracle.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";
import {Owned} from "../../src/legacy_v1/rewards/Owned.sol"; 

/// @author nexusflip
/// @author MiguelBits

contract OwnerTest is OwnerHelper{
    
    /*//////////////////////////////////////////////////////////////
                           ASSERT cases
    //////////////////////////////////////////////////////////////*/

    function testOwnerAuthorize() public {
        vm.deal(ALICE, AMOUNT);
        
        vm.startPrank(ADMIN);
        fakeOracle = new FakeOracle(ORACLE_FRAX, STRIKE_PRICE_FAKE_ORACLE);
        vaultFactory.createNewMarket(FEE, TOKEN_FRAX, DEPEG_AAA, beginEpoch, endEpoch, address(fakeOracle), "y2kFRAX_99*");
        vm.stopPrank();

        hedge = vaultFactory.getVaults(1)[0];
        vHedge = Vault(hedge);

        vm.startPrank(ALICE);
        ERC20(WETH).approve(hedge, AMOUNT);
        vHedge.depositETH{value: AMOUNT}(endEpoch, ALICE);

        assertTrue(vHedge.balanceOf(ALICE,endEpoch) == (AMOUNT));
        vm.stopPrank();

        vm.startPrank(ALICE);
        vm.warp(endEpoch + 1 days);
        controller.triggerEndEpoch(vaultFactory.marketIndex(), endEpoch);
        vHedge.setApprovalForAll(BOB, true);
        if(vHedge.isApprovedForAll(ALICE, BOB)){
            emit log_named_uint("Can continue", 1);
        }

        else {
            emit log_named_uint("Cannot continue", 0);
        }
        vm.stopPrank();
        
        vm.startPrank(BOB);
        vHedge.withdraw(endEpoch, AMOUNT, BOB, ALICE);
        assertTrue(vHedge.balanceOf(ALICE,endEpoch) == 0);
        vm.stopPrank();
    }

    function testChangeOwnerFactory() public {
        vm.startPrank(ADMIN);
        vaultFactory.transferOwnership(BOB);
        assertTrue(vaultFactory.owner() == BOB);
    }

    /*//////////////////////////////////////////////////////////////
                           REVERT cases
    //////////////////////////////////////////////////////////////*/

    function testOwnerAddressZero() public {
        vm.expectRevert(bytes("Owner address cannot be 0"));
        new Owned(address(0));
    }

    function testNominatorNotADMIN() public {
        owned = new Owned(ADMIN);

        vm.startPrank(ALICE);
        vm.expectRevert(bytes("Only the contract owner may perform this action"));
        owned.nominateNewOwner(ALICE);
        vm.stopPrank();
    }

    function testNominateBeforeOwner() public {
        owned = new Owned(ADMIN);

        vm.startPrank(ADMIN);
        vm.expectRevert(bytes("You must be nominated before you can accept ownership"));
        owned.acceptOwnership();
        vm.stopPrank();
    }
}