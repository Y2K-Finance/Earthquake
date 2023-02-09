// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../Helper.sol";
import "../../../src/v2/VaultFactoryV2.sol";
import "../../../src/v2/VaultV2.sol";
import "../../../src/v2/interfaces/IVaultV2.sol";
import "../../../src/v2/Controllers/ControllerPeggedAssetV2.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract EndToEndV2Test is Helper {
    VaultFactoryV2 public factory;
    ControllerPeggedAssetV2 public controller;

    address public premium;
    address public collateral;
    address public oracle;

    uint256 public marketId;
    uint256 public strike;
    uint256 public epochId;

    uint40 public begin;
    uint40 public end;

    uint16 public fee;

    uint256 public constant AMOUNT_AFTER_FEE = 19.95 ether;
    uint256 public constant DEPOSIT_AMOUNT = 10 ether;
    uint256 public constant DEALT_AMOUNT = 20 ether;

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

       MintableToken(UNDERLYING).mint(USER);
    }

    function testEndToEndDeposit() public {
        vm.startPrank(USER);

        //deal ether
        vm.deal(USER, DEALT_AMOUNT);

        //approve gov token
        MintableToken(UNDERLYING).approve(premium, DEPOSIT_AMOUNT);
        MintableToken(UNDERLYING).approve(collateral, DEPOSIT_AMOUNT);

        //allowance for gov token
        MintableToken(UNDERLYING).allowance(USER, premium);
        MintableToken(UNDERLYING).allowance(USER, collateral);

        //deposit in both vaults
        VaultV2(premium).deposit(epochId, DEPOSIT_AMOUNT, USER);
        VaultV2(collateral).deposit(epochId, DEPOSIT_AMOUNT, USER);

        //check deposit balances
        assertEq(VaultV2(premium).balanceOf(USER ,epochId), DEPOSIT_AMOUNT);
        assertEq(VaultV2(collateral).balanceOf(USER ,epochId), DEPOSIT_AMOUNT);

        //check user underlying balance
        assertEq(USER.balance, DEALT_AMOUNT);

        //warp to epoch end
        vm.warp(end + 1 days);
        
        //trigger end of epoch
        controller.triggerEndEpoch(marketId, epochId);

        //check vault balances on withdraw
        assertEq(VaultV2(premium).previewWithdraw(epochId, DEPOSIT_AMOUNT), 0);
        assertEq(VaultV2(collateral).previewWithdraw(epochId, DEPOSIT_AMOUNT), 19.95 ether);

        //withdraw from vaults
        VaultV2(premium).withdraw(epochId, DEPOSIT_AMOUNT, USER, USER);
        VaultV2(collateral).withdraw(epochId, DEPOSIT_AMOUNT, USER, USER);

        //check vaults balance
        assertEq(VaultV2(premium).balanceOf(USER ,epochId), 0);
        assertEq(VaultV2(collateral).balanceOf(USER ,epochId), 0);

        //check user ERC20 balance
        assertEq(USER.balance, DEALT_AMOUNT);

        vm.stopPrank();
    }

}