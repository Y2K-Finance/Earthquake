// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Helper.sol";
import "../../src/v2/VaultFactoryV2.sol";
import "../../src/v2/VaultV2.sol";
import "../../src/v2/interfaces/IVaultV2.sol";
import "../../src/v2/Controllers/ControllerPeggedAssetV2.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract EndToEndV2Test is Helper {
    VaultFactoryV2 factory;
    ControllerPeggedAssetV2 controller;

    address premium;
    address collateral;
    address oracle;

    uint256 marketId;
    uint256 strike;
    uint256 epochId;

    uint40 begin;
    uint40 end;

    uint16 fee;

    function setUp() public {

        UNDERLYING = address(new MintableToken("UnderLyingToken", "utkn"));

        factory = new VaultFactoryV2(
                ADMIN,
                WETH,
                TREASURY
            );
        
        controller = new ControllerPeggedAssetV2(address(factory), ARBITRUM_SEQUENCER, TREASURY);

        factory.whitelistController(address(controller));
        
        //create market - TO-DO: change oracle
        oracle = address(0x3);
        strike = uint256(0x2);
        string memory name = string("USD Coin");
        string memory symbol = string("USDC");

        (
            premium,
            collateral,
            marketId
        ) = factory.createNewMarket(
            VaultFactoryV2.MarketConfigurationCalldata(
                TOKEN,
                strike,
                oracle,
                UNDERLYING,
                name,
                symbol,
                address(controller)
            )
        );

        vm.warp(120000);
        MintableToken(UNDERLYING).mint(address(this));
        
        //create epoch
        begin = uint40(block.timestamp + 1 days);
        end = uint40(block.timestamp + 2 days);
        fee = uint16(0x5);

        epochId = factory.createEpoch(
                marketId,
                begin,
                end,
                fee
       );

       emit log_named_uint("epochId", epochId);

       (uint40 beginning, uint40 ending) = IVaultV2(premium).getEpochConfig(marketId);

       emit log_named_uint("vault begin epoch", beginning);
       emit log_named_uint("vault end epoch", ending);

       MintableToken(UNDERLYING).mint(USER);
    }

    function testEndToEndDeposit() public {
        vm.startPrank(ADMIN);

        //deal ether
        vm.deal(ADMIN, 20 ether);
        vm.deal(USER, 20 ether);

        vm.stopPrank();

        vm.startPrank(USER);

        //approve gov token
        MintableToken(UNDERLYING).approve(premium, 10 ether);
        MintableToken(UNDERLYING).approve(collateral, 10 ether);

        //allowance for gov token
        MintableToken(UNDERLYING).allowance(USER, premium);
        MintableToken(UNDERLYING).allowance(USER, collateral);

        //deposit in both vaults
        VaultV2(premium).deposit(epochId, 10 ether, USER);
        VaultV2(collateral).deposit(epochId, 10 ether, USER);

        //check deposit balances
        assertEq(VaultV2(premium).balanceOf(USER ,epochId), 10 ether);
        emit log_named_uint("assert premium balance", 1);
        assertEq(VaultV2(collateral).balanceOf(USER ,epochId), 10 ether);
        emit log_named_uint("assert collateral balance", 2);

        //TO-DO:check user balances
        assertEq(IERC1155(premium).balanceOf(USER, epochId), 10 ether);
        emit log_named_uint("assert premium user balance", 3);
        assertEq(IERC1155(collateral).balanceOf(USER, epochId), 10 ether);
        emit log_named_uint("assert collateral user balance", 4);

        vm.stopPrank();

        vm.startPrank(ADMIN);

        vm.warp(end + 1 days);
        
        emit log_named_uint("epoch to end", 10);
        controller.triggerEndEpoch(marketId, end);

        //resolve epoch
        emit log_named_uint("epoch to resolve", 10);
        IVaultV2(premium).resolveEpoch(epochId);
        IVaultV2(collateral).resolveEpoch(epochId);
        emit log_named_uint("epoch resolved", 10);

        IVaultV2(collateral).sendTokens(epochId, VaultV2(collateral).balanceOf(collateral, epochId), premium);

        //check vault balances
        assertEq(VaultV2(premium).balanceOf(USER ,epochId), 20 ether);
        emit log_named_uint("assert premium user balance", 5);
        assertEq(VaultV2(collateral).balanceOf(USER ,epochId), 0);
        emit log_named_uint("assert collateral user balance", 6);

        vm.stopPrank();

        vm.startPrank(USER);

        vm.warp(end);

        //approve gov token
        /*MintableToken(UNDERLYING).approve(premium, 10 ether);
        MintableToken(UNDERLYING).approve(collateral, 10 ether);

        //allowance for gov token
        MintableToken(UNDERLYING).allowance(USER, premium);
        MintableToken(UNDERLYING).allowance(USER, collateral);*/

        //withdraw from vaults
        VaultV2(premium).withdraw(epochId, VaultV2(premium).balanceOf(USER, epochId) , USER, USER);
        VaultV2(collateral).withdraw(epochId, VaultV2(collateral).balanceOf(USER, epochId), USER, USER);

        //check vaults balance
        assertEq(VaultV2(premium).balanceOf(USER ,epochId), 0);
        emit log_named_uint("assert withdraw vault premium user balance", 7);
        assertEq(VaultV2(collateral).balanceOf(USER ,epochId), 0);
        emit log_named_uint("assert withdraw vault collateral user balance", 8);

        vm.stopPrank();
    }

}