// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Test.sol";
import {Vault} from "../src/Vault.sol";
import {VaultFactory} from "../src/VaultFactory.sol";
import {Controller} from "../src/Controller.sol";
import {OwnerHelper} from "./OwnerHelper.sol";
import {FakeOracle} from "./oracles/FakeOracle.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";
import {Owned} from "../src/rewards/Owned.sol"; 

/// @author nexusflip
/// @author MiguelBits

contract OwnerTest is OwnerHelper{
    /*//////////////////////////////////////////////////////////////
                           ASSERT cases
    //////////////////////////////////////////////////////////////*/

    function testOwnerAuthorize() public {
        vm.deal(alice, AMOUNT);
        
        vm.startPrank(admin);
        fakeOracle = new FakeOracle(oracleFRAX, STRIKE_PRICE_FAKE_ORACLE);
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, address(fakeOracle), "y2kFRAX_99*");
        vm.stopPrank();

        hedge = vaultFactory.getVaults(1)[0];
        vHedge = Vault(hedge);

        vm.startPrank(alice);
        ERC20(WETH).approve(hedge, AMOUNT);
        vHedge.depositETH{value: AMOUNT}(endEpoch, alice);

        assertTrue(vHedge.balanceOf(alice,endEpoch) == (AMOUNT));
        vm.stopPrank();

        vm.startPrank(alice);
        vm.warp(endEpoch + 1 days);
        controller.triggerEndEpoch(vaultFactory.marketIndex(), endEpoch);
        vHedge.setApprovalForAll(bob, true);
        if(vHedge.isApprovedForAll(alice, bob)){
            emit log_named_uint("Can continue", 1);
        }

        else {
            emit log_named_uint("Cannot continue", 0);
        }
        vm.stopPrank();
        
        vm.startPrank(bob);
        vHedge.withdraw(endEpoch, AMOUNT, bob, alice);
        assertTrue(vHedge.balanceOf(alice,endEpoch) == 0);
        vm.stopPrank();
    }

    function testChangeOwnerFactory() public {
        vm.startPrank(admin);
        vaultFactory.transferOwnership(bob);
        assertTrue(vaultFactory.owner() == bob);
    }

    /*//////////////////////////////////////////////////////////////
                           REVERT cases
    //////////////////////////////////////////////////////////////*/

    function testOwnerAddressZero() public {
        vm.expectRevert(bytes("Owner address cannot be 0"));
        new Owned(address(0));
    }

    function testNominatorNotAdmin() public {
        owned = new Owned(admin);

        vm.startPrank(alice);
        vm.expectRevert(bytes("Only the contract owner may perform this action"));
        owned.nominateNewOwner(alice);
        vm.stopPrank();
    }

    function testNominateBeforeOwner() public {
        owned = new Owned(admin);

        vm.startPrank(admin);
        vm.expectRevert(bytes("You must be nominated before you can accept ownership"));
        owned.acceptOwnership();
        vm.stopPrank();
    }
}