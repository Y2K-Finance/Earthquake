
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../Helper.sol";
import "../../../src/v2/VaultV2.sol";
import "../../../src/v2/interfaces/IVaultV2.sol";
import "../../../src/v2/Controllers/ControllerPeggedAssetV2.sol";
import "../../../src/v2/VaultFactoryV2.sol";

contract ControllerPeggedAssetV2Test is Helper {
    VaultV2 vault;
    VaultV2 counterpartyVault;
    ControllerPeggedAssetV2 controller;
    VaultFactoryV2 factory;

    uint40 begin;
    uint40 end;
    uint16 withdrawalFee;
    uint256 epochId;
    uint256 marketId;

    address premium;
    address collateral;


    function setUp() public {
        factory = new VaultFactoryV2(
            ADMIN,
            WETH,
            TREASURY
        );

        controller = new ControllerPeggedAssetV2(
           address(factory),
           address(0x1),
            TREASURY
        );

        UNDERLYING = address(new MintableToken("UnderLyingToken", "utkn"));


        vm.warp(120000);
        MintableToken(UNDERLYING).mint(address(this));

        address oracle = address(0x3);
        string memory name = string("");
        string memory symbol = string("");

        vm.startPrank(factory.timelocker());
        factory.whitelistController(address(controller));
        vm.stopPrank();

        (
            premium,
            collateral,
            marketId
        ) = factory.createNewMarket(
            VaultFactoryV2.MarketConfigurationCalldata(
                TOKEN,
                STRIKE,
                oracle,
                address(UNDERLYING),
                name,
                symbol,
                address(controller)
            )
        );

        begin = uint40(block.timestamp);
        end = uint40(block.timestamp + 1 days);
        withdrawalFee = 10;

        (epochId, ) = factory.createEpoch(
            marketId,
            begin,
            end,
            withdrawalFee
        );

        MintableToken(UNDERLYING).mint(USER);

    }

   function testTriggerDepeg() public {
        // TODO
        // revert cases

        // success case
    }


    function testRriggerEndEpoch() public {
        // TODO
        // revert cases

        // success case
    }

    function testTriggerNullEpoch() public {
        // TODO
        // revert cases

        // success case
    }

}