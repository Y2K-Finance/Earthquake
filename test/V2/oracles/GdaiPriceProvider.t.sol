// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Helper} from "../Helper.sol";
import {VaultFactoryV2} from "../../../src/v2/VaultFactoryV2.sol";
import {TimeLock} from "../../../src/v2/TimeLock.sol";
import {GdaiPriceProvider} from "../../../src/v2/oracles/GDaiPriceProvider.sol";
import {
    MockOracleAnswerOne,
    MockOracleGracePeriod,
    MockOracleAnswerZero,
    MockOracleRoundOutdated,
    MockOracleTimeOut
} from "./MockOracles.sol";

contract GdaiPriceProviderTest is Helper {
    GdaiPriceProvider public gdaiPriceProvider;
    uint256 public arbForkId;
    int256 public strikePrice = -8994085036142722;

    event StrikeUpdated(bytes strikeHash, int256 strikePrice);

    ////////////////////////////////////////////////
    //                HELPERS                     //
    ////////////////////////////////////////////////
    function setUp() public {
        arbForkId = vm.createFork(ARBITRUM_RPC_URL);
        vm.selectFork(arbForkId);

        gdaiPriceProvider = new GdaiPriceProvider(GDAI_VAULT);
        gdaiPriceProvider.updateStrikeHash(strikePrice);
    }

    ////////////////////////////////////////////////
    //                STATE                       //
    ////////////////////////////////////////////////
    function testGdaiCreation() public {
        assertEq(address(gdaiPriceProvider.gdaiPriceFeed()), GDAI_VAULT);

        assertEq(gdaiPriceProvider.strikeHash(), abi.encode(strikePrice));
    }

    ////////////////////////////////////////////////
    //                FUNCTIONS                  //
    ////////////////////////////////////////////////
    function testUpdateStrike() public {
        int256 newStrikePrice = -1;
        vm.expectEmit(true, true, false, false);
        emit StrikeUpdated(abi.encode(newStrikePrice), newStrikePrice);
        gdaiPriceProvider.updateStrikeHash(newStrikePrice);
        assertEq(gdaiPriceProvider.strikeHash(), abi.encode(newStrikePrice));
    }

    function testLatestPrice() public {
        int256 price = gdaiPriceProvider.getLatestPrice();
        assertTrue(price != 0);
    }

    function testConditionMetGDAI() public {
        (bool condition, int256 price) = gdaiPriceProvider.conditionMet(
            uint256(-strikePrice)
        );
        assertTrue(price != 0);
        assertEq(condition, true);
    }

    ////////////////////////////////////////////////
    //              REVERT CASES                  //
    ////////////////////////////////////////////////

    function testRevertConstructorInputs() public {
        vm.expectRevert(GdaiPriceProvider.ZeroAddress.selector);
        new GdaiPriceProvider(address(0));
    }

    function testRevertInvalidStrike() public {
        vm.expectRevert(GdaiPriceProvider.InvalidStrike.selector);
        gdaiPriceProvider.conditionMet(10 ether);
    }

    function testRevertNotOwner() public {
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        vm.prank(address(0x123));
        gdaiPriceProvider.updateStrikeHash(1);
    }
}
