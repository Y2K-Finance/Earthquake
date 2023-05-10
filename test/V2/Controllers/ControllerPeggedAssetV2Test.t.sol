
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../Helper.sol";
import "../../../src/v2/VaultV2.sol";
import "../../../src/v2/interfaces/IVaultV2.sol";
import "../../../src/v2/Controllers/ControllerPeggedAssetV2.sol";
import "../../../src/v2/VaultFactoryV2.sol";
import "../../../src/v2/TimeLock.sol";

contract ControllerPeggedAssetV2Test is Helper {
    using stdStorage for StdStorage;
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
        
        TimeLock timelock = new TimeLock(ADMIN);

        factory = new VaultFactoryV2(
            WETH,
            TREASURY,
            address(timelock)
        );

        controller = new ControllerPeggedAssetV2(
           address(factory),
           address(new Sequencer())
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

        begin = uint40(block.timestamp+ 30 days);
        end = uint40(block.timestamp + 35 days);
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
        stdstore
            .target(address(factory))
            .sig("marketToOracle(uint256)")
            .with_key(marketId)
            .checked_write(address(this)); // set oracle with faulty updated at time

        vm.warp(begin + 1);
        
        vm.expectRevert(ControllerPeggedAssetV2.PriceOutdated.selector);
        controller.triggerDepeg(marketId, epochId);

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

    function latestRoundData() public view returns (uint80, int256, uint256, uint256, uint80) {
        return (100, int256(STRIKE) - int256(1), 0, block.timestamp - 3 days, 100);
    }

    function decimals() public view returns (uint8) {
        return 18;
    }

}


contract Sequencer is Helper {
    function latestRoundData() public view returns (uint80, int256, uint256, uint256, uint80) {
        return (100, 0, block.timestamp - 1 days, block.timestamp, 100);
    }
}