// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Helper.sol";
import "../../src/v2/VaultV2.sol";
import "../../src/v2/interfaces/IVaultV2.sol";

contract VaultV2Test is Helper {
    VaultV2 vault;
    VaultV2 counterpartyVault;
    address controller;

    function setUp() public {
        controller = address(0x54);

        UNDERLYING = address(new MintableToken("UnderLyingToken", "utkn"));

        vault = new VaultV2(
            false,
            UNDERLYING,
            "Vault",
            "v",
            "randomURI",
            TOKEN,
            STRIKE,
            controller
        );
        vm.warp(120000);
        MintableToken(UNDERLYING).mint(address(this));

        counterpartyVault = new VaultV2(
            false,
            UNDERLYING,
            "Vault",
            "v",
            "randomURI",
            TOKEN,
            STRIKE,
            controller
        );

        vault.setCounterPartyVault(address(counterpartyVault));

        MintableToken(UNDERLYING).mint(USER);
    }

    function testVaultCreation() public {
        // test all revert cases
        vm.expectRevert(VaultV2.AddressZero.selector);
        new VaultV2(
            false,
            address(0), // wrong underlying
            "Vault",
            "v",
            "randomURI",
            TOKEN,
            STRIKE,
            controller
        );

        vm.expectRevert(VaultV2.AddressZero.selector);
        new VaultV2(
            false,
            UNDERLYING,
            "Vault",
            "v",
            "randomURI",
            address(0), // wrong token
            STRIKE,
            controller
        );

        vm.expectRevert(VaultV2.AddressZero.selector);
        new VaultV2(
            false,
            UNDERLYING,
            "Vault",
            "v",
            "randomURI",
            TOKEN,
            STRIKE,
            address(0) // wrong controller
        );

        // test success case
        VaultV2 vault2 = new VaultV2(
            false,
            UNDERLYING,
            "Vault",
            "v",
            "randomURI",
            TOKEN,
            STRIKE,
            controller
        );

        assertEq(address(vault2.asset()), UNDERLYING);
        assertEq(string(vault2.name()), string("Vault"));
        assertEq(string(vault2.symbol()), string("v"));
        assertEq(vault2.token(), TOKEN);
        assertEq(vault2.strike(), STRIKE);
        assertEq(vault2.controller(), controller);
        assertEq(vault2.factory(), address(this));
    }

    function testSetEpoch() public {
        // test revert cases

        vm.startPrank(NOTADMIN);
        vm.expectRevert(
            abi.encodeWithSelector(VaultV2.AddressNotFactory.selector, NOTADMIN)
        );
        vault.setEpoch(1, 1, 1);
        vm.stopPrank();

        // assumes that factory is set to address(this)
        vm.expectRevert(VaultV2.InvalidEpoch.selector);
        vault.setEpoch(0, 0, 0);
        vm.expectRevert(VaultV2.InvalidEpoch.selector);
        vault.setEpoch(1, 0, 0);
        vm.expectRevert(VaultV2.InvalidEpoch.selector);
        vault.setEpoch(1, 1, 0);
        vm.expectRevert(VaultV2.InvalidEpoch.selector);
        vault.setEpoch(1, 0, 1);

        uint40 begin = uint40(block.timestamp);
        uint40 end = uint40(block.timestamp + 1 days);
        uint256 epochId = 1;

        vault.setEpoch(begin, end, epochId);

        vm.expectRevert(VaultV2.EpochAlreadyExists.selector);
        vault.setEpoch(begin, end, epochId);

        vm.expectRevert(VaultV2.EpochEndMustBeAfterBegin.selector);
        vault.setEpoch(end, begin, epochId + 1);

        // test success case
        assertTrue(vault.epochExists(epochId));
        (uint40 b, uint40 e, uint40 c) = vault.getEpochConfig(epochId);
        assertEq(b, begin);
        assertEq(e, end);
        assertEq(c, block.timestamp);

        helperSetEpoch(begin + 1, end + 1, epochId + 1);
        // get all epochs
        uint256[] memory epochs = vault.getAllEpochs();
        assertEq(epochs.length, 2);
        assertEq(epochs[0], epochId);
        assertEq(epochs[1], epochId + 1);
    }

    function testDeposit() public {
        // test revert cases
        vm.expectRevert(VaultV2.EpochDoesNotExist.selector);
        vault.deposit(20, 1, USER);

        uint40 begin = uint40(block.timestamp);
        uint40 end = uint40(block.timestamp + 1 days);
        uint256 epochId = 1;

        helperSetEpoch(begin, end, epochId);

        vm.warp(begin + 1);
        vm.expectRevert(VaultV2.EpochAlreadyStarted.selector);
        vault.deposit(epochId, 1, USER);

        // test success case
        vm.startPrank(USER);
        // approve tokens to vault
        vm.warp(begin - 1);
        // MintableToken(UNDERLYING).approve(address(vault), 10 ether);

        MintableToken(UNDERLYING).approve(address(vault), 10 ether);

        MintableToken(UNDERLYING).allowance(USER, address(vault));

        // deposit tokens
        vault.deposit(epochId, 10 ether, USER);
        // check balances
        assertEq(vault.balanceOf(USER, epochId), 10 ether);
        vm.stopPrank();
        // check deposit after epoch started
    }

    function testWithdraw() public {
        // test revert cases
        vm.expectRevert(VaultV2.EpochDoesNotExist.selector);
        vault.withdraw(20, 1, USER, USER);

        uint40 begin = uint40(block.timestamp);
        uint40 end = uint40(block.timestamp + 1 days);
        uint256 epochId = 1;

        helperSetEpoch(begin, end, epochId);

        vm.warp(begin + 1);

        vm.expectRevert(VaultV2.EpochNotResolved.selector);
        vault.withdraw(epochId, 1, USER, USER);

        // test success case
        begin = uint40(block.timestamp);
        end = uint40(block.timestamp + 1 days);
        epochId = 3;

        helperSetEpoch(begin, end, epochId);

        // approve tokens to vault
        MintableToken(UNDERLYING).approve(address(vault), 10 ether);
        // deposit tokens
        vault.deposit(epochId, 10 ether, USER);
        // check balances
        assertEq(vault.balanceOf(USER, epochId), 10 ether);

        vm.startPrank(controller);
        // resolve epoch
        vault.resolveEpoch(epochId);
        vm.stopPrank();

        vm.startPrank(USER);
        // withdraw tokens
        vault.withdraw(epochId, 10 ether, USER, USER);
        // check balances
        assertEq(vault.balanceOf(USER, epochId), 0);
        vm.stopPrank();
    }

    function testResolveEpoch() public {
        // test revert cases
        uint40 begin = uint40(block.timestamp);
        uint40 end = uint40(block.timestamp + 1 days);
        uint256 epochId = 1;
        uint256 wrongEpochId = 2;

        helperSetEpoch(begin, end, epochId);

        vm.startPrank(NOTADMIN);
        vm.expectRevert(
            abi.encodeWithSelector(
                VaultV2.AddressNotController.selector,
                NOTADMIN
            )
        );
        vault.resolveEpoch(epochId);
        vm.stopPrank();

        vm.startPrank(controller);

        vm.warp(begin + 1);
        vm.expectRevert(VaultV2.EpochDoesNotExist.selector);
        vault.resolveEpoch(wrongEpochId);

        vm.warp(begin - 1);
        vm.expectRevert(VaultV2.EpochNotStarted.selector);
        vault.resolveEpoch(epochId);

        vm.warp(begin + 1);
        vault.resolveEpoch(epochId);
        vm.expectRevert(VaultV2.EpochAlreadyEnded.selector);
        vault.resolveEpoch(epochId);

        vm.stopPrank();

        // test success case
        begin = uint40(block.timestamp + 1 days);
        end = uint40(block.timestamp + 2 days);
        epochId = 2;
        helperSetEpoch(begin, end, epochId);
        // test depeg
        // deposit tokens before epoch starts
        MintableToken(UNDERLYING).approve(address(vault), 10 ether);
        vault.deposit(epochId, 10 ether, USER);
        // end epoch after epoch started to simulate strike price met
        vm.warp(begin + 1);
        vm.startPrank(controller);
        vault.resolveEpoch(epochId);
        vm.stopPrank();
        assertTrue(vault.epochResolved(epochId));
        // check final TVL
        assertEq(vault.finalTVL(epochId), 10 ether);

        // test epoch resolvement after epoch ended
        // create new epoch
        begin = uint40(block.timestamp + 1 days);
        end = uint40(block.timestamp + 2 days);
        epochId = 3;
        helperSetEpoch(begin, end, epochId);
        // deposit tokens before epoch starts
        MintableToken(UNDERLYING).approve(address(vault), 10 ether);
        vault.deposit(epochId, 10 ether, USER);
        // end epoch after epoch ended
        vm.warp(end + 1);
        vm.startPrank(controller);
        vault.resolveEpoch(epochId);
        vm.stopPrank();
        assertTrue(vault.epochResolved(epochId));
        // check final TVL
        assertEq(vault.finalTVL(epochId), 10 ether);
    }

    function testClaimTVL() public {
        // test revert cases
        uint40 begin = uint40(block.timestamp);
        uint40 end = uint40(block.timestamp + 1 days);
        uint256 epochId = 1;
        uint256 wrongEpochId = 2;

        helperSetEpoch(begin, end, epochId);

        vm.startPrank(USER);
        // deposit tokens before epoch starts
        MintableToken(UNDERLYING).approve(address(vault), 10 ether);
        vault.deposit(epochId, 10 ether, USER);

        MintableToken(UNDERLYING).approve(address(counterpartyVault), 10 ether);
        counterpartyVault.deposit(epochId, 10 ether, USER);
        vm.stopPrank();

        vm.startPrank(NOTADMIN);
        vm.expectRevert(
            abi.encodeWithSelector(
                VaultV2.AddressNotController.selector,
                NOTADMIN
            )
        );
        vault.setClaimTVL(epochId, 10 ether);
        vm.stopPrank();

        vm.startPrank(controller);
        vm.warp(begin + 1);
        vm.expectRevert(VaultV2.EpochDoesNotExist.selector);
        vault.setClaimTVL(wrongEpochId, 10 ether);

        vm.expectRevert(VaultV2.EpochNotResolved.selector);
        vault.setClaimTVL(epochId, 10 ether);

        /*vm.warp(begin + 1);
        // test claim TVL is less than counterparty tvl

        vault.resolveEpoch(epochId);
        counterpartyVault.resolveEpoch(epochId);

        vm.expectRevert(VaultV2.InvalidClaimTVL.selector);
        vault.setClaimTVL(epochId,  11 ether);*/

        vm.stopPrank();

        // test success case
        // start new epoch
        begin = uint40(block.timestamp + 1 days);
        end = uint40(block.timestamp + 2 days);
        epochId = 2;
        helperSetEpoch(begin, end, epochId);
        // deposit tokens before epoch starts
        MintableToken(UNDERLYING).approve(address(vault), 10 ether);
        vault.deposit(epochId, 10 ether, USER);

        MintableToken(UNDERLYING).approve(address(counterpartyVault), 10 ether);
        counterpartyVault.deposit(epochId, 10 ether, USER);

        vm.startPrank(controller);
        vm.warp(begin + 1);
        vault.resolveEpoch(epochId);
        counterpartyVault.resolveEpoch(epochId);
        vault.setClaimTVL(epochId, 10 ether);
        vm.stopPrank();
        assertEq(vault.claimTVL(epochId), 10 ether);
    }

    function testSendTokens() public {
        // test revert cases
        // create new epoch
        uint40 begin = uint40(block.timestamp + 1 days);
        uint40 end = uint40(block.timestamp + 2 days);
        uint256 epochId = 1;
        uint256 wrongEpochId = 2;

        helperSetEpoch(begin, end, epochId);

        vm.startPrank(USER);
        // deposit tokens before epoch starts
        MintableToken(UNDERLYING).approve(address(vault), 10 ether);
        vault.deposit(epochId, 10 ether, USER);
        vm.stopPrank();

        vm.startPrank(NOTADMIN);
        vm.expectRevert(
            abi.encodeWithSelector(
                VaultV2.AddressNotController.selector,
                NOTADMIN
            )
        );
        vault.sendTokens(epochId, 10 ether, address(counterpartyVault));
        vm.stopPrank();

        vm.startPrank(controller);
        vm.expectRevert(VaultV2.EpochDoesNotExist.selector);
        vault.sendTokens(wrongEpochId, 10 ether, address(counterpartyVault));

        vm.expectRevert(VaultV2.EpochNotResolved.selector);
        vault.sendTokens(epochId, 10 ether, address(counterpartyVault));

        vm.warp(begin + 1);
        vault.resolveEpoch(epochId);

        vm.expectRevert(VaultV2.AmountExceedsTVL.selector);
        vault.sendTokens(epochId, 11 ether, address(counterpartyVault));

        vm.expectRevert(
            abi.encodeWithSelector(
                VaultV2.DestinationNotAuthorized.selector,
                NOTADMIN
            )
        );
        vault.sendTokens(epochId, 10 ether, NOTADMIN);

        vm.stopPrank();

        // test success case
        // start new epoch
        begin = uint40(block.timestamp + 1 days);
        end = uint40(block.timestamp + 2 days);
        epochId = 2;
        helperSetEpoch(begin, end, epochId);
        // deposit tokens before epoch starts
        MintableToken(UNDERLYING).approve(address(vault), 10 ether);
        vault.deposit(epochId, 10 ether, USER);

        vm.startPrank(controller);
        vm.warp(begin + 1);
        vault.resolveEpoch(epochId);
        uint256 balanceBefore = MintableToken(UNDERLYING).balanceOf(
            address(counterpartyVault)
        );
        console.log("whitelist", vault.whitelistedAddresses(TREASURY));
        // send tokens to treasury and counterparty
        vault.sendTokens(epochId, 1 ether, TREASURY);
        // checkou epochAccounting
        assertEq(vault.epochAccounting(epochId), 1 ether);
        vault.sendTokens(epochId, 9 ether, address(counterpartyVault));
        // checkou epochAccounting
        assertEq(vault.epochAccounting(epochId), 10 ether);
        uint256 balanceAfter = MintableToken(UNDERLYING).balanceOf(
            address(counterpartyVault)
        );
        assertEq(balanceAfter > balanceBefore, true);
        vm.stopPrank();
    }

    function setEpochNull() public {
        // test revert cases
        // test success case
    }

    function testWhiteListAddress() public {
        // test revert cases
        vm.startPrank(NOTADMIN);
        vm.expectRevert(
            abi.encodeWithSelector(VaultV2.AddressNotFactory.selector, NOTADMIN)
        );
        vault.whiteListAddress(NOTADMIN);
        vm.stopPrank();

        vm.expectRevert(VaultV2.AddressZero.selector);
        vault.whiteListAddress(address(0));

        // test success case
        address whitelistedDestination = address(0x111);
        // expect address(this) to be factory
        vault.whiteListAddress(whitelistedDestination);
        assertEq(vault.whitelistedAddresses(whitelistedDestination), true);

        vault.whiteListAddress(whitelistedDestination);
        assertEq(vault.whitelistedAddresses(whitelistedDestination), false);
    }

    function testChangeController() public {
        // test revert cases
        vm.startPrank(NOTADMIN);
        vm.expectRevert(
            abi.encodeWithSelector(VaultV2.AddressNotFactory.selector, NOTADMIN)
        );
        vault.changeController(NOTADMIN);
        vm.stopPrank();

        vm.expectRevert(VaultV2.AddressZero.selector);
        vault.changeController(address(0));

        // test success case
        address newController = address(0x111);
        // expect address(this) to be factory
        vault.changeController(newController);

        assertEq(vault.controller(), newController);

        // test old controller can't call functions
        vm.startPrank(controller);
        vm.expectRevert(
            abi.encodeWithSelector(
                VaultV2.AddressNotController.selector,
                controller
            )
        );
        vault.resolveEpoch(1);
        vm.stopPrank();
    }

    function testSetCounterPartyVault() public {
        // test revert cases
        vm.startPrank(NOTADMIN);
        vm.expectRevert(
            abi.encodeWithSelector(VaultV2.AddressNotFactory.selector, NOTADMIN)
        );
        vault.setCounterPartyVault(NOTADMIN);
        vm.stopPrank();

        vm.expectRevert(VaultV2.AddressZero.selector);
        vault.setCounterPartyVault(address(0));

        // test success case
        address newCounterPartyVault = address(0x111);
        // expect address(this) to be factory
        vault.setCounterPartyVault(newCounterPartyVault);

        assertEq(vault.counterPartyVault(), newCounterPartyVault);
    }

    function helperSetEpoch(
        uint40 _epochBegin,
        uint40 _epochEnd,
        uint256 _epochId
    ) public {
        vault.setEpoch(_epochBegin, _epochEnd, _epochId);
        counterpartyVault.setEpoch(_epochBegin, _epochEnd, _epochId);
    }

    // deployer contract acts as factory and must emulate VaultFactoryV2.treasury()
    function treasury() public pure returns (address) {
        return TREASURY;
    }
}
