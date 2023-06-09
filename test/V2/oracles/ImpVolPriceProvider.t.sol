// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Helper} from "../Helper.sol";
import {VaultFactoryV2} from "../../../src/v2/VaultFactoryV2.sol";
import {TimeLock} from "../../../src/v2/TimeLock.sol";
import {
    ImpVolPriceProvider
} from "../../../src/v2/oracles/ImpVolPriceProvider.sol";
import {
    MockOracleAnswerOne,
    MockOracleGracePeriod,
    MockOracleAnswerZero,
    MockOracleRoundOutdated,
    MockOracleTimeOut
} from "./MockOracles.sol";

contract ImpVolPriceProviderTest is Helper {
    ImpVolPriceProvider public impVolPriceProvider;
    uint256 public arbForkId;
    uint256 public expiryTimestamp;
    // TODO: Review the strike price
    uint256 public strikePrice = 10e8;

    ////////////////////////////////////////////////
    //                HELPERS                     //
    ////////////////////////////////////////////////
    function setUp() public {
        arbForkId = vm.createFork(ARBITRUM_RPC_URL);
        vm.selectFork(arbForkId);
        expiryTimestamp = block.timestamp + 1;

        impVolPriceProvider = new ImpVolPriceProvider(DIA_ORACLE_V2);
        impVolPriceProvider.updateExpiry(expiryTimestamp);
    }

    ////////////////////////////////////////////////
    //                STATE                       //
    ////////////////////////////////////////////////
    function testImpCreation() public {
        assertEq(address(impVolPriceProvider.volPriceFeed()), DIA_ORACLE_V2);
        assertEq(impVolPriceProvider.expirationTime(), expiryTimestamp);
    }

    ////////////////////////////////////////////////
    //                FUNCTIONS                  //
    ////////////////////////////////////////////////
    function testLatestPrice() private {
        int256 price = impVolPriceProvider.getLatestPrice();
        assertTrue(price != 0);
    }

    function testConditionMetImp() private {
        (bool condition, int256 price) = impVolPriceProvider.conditionMet(
            strikePrice
        );
        assertTrue(price != 0);
        assertEq(condition, true);
    }

    ////////////////////////////////////////////////
    //              REVERT CASES                  //
    ////////////////////////////////////////////////

    function testRevertConstructorInputs() public {
        vm.expectRevert(ImpVolPriceProvider.ZeroAddress.selector);
        new ImpVolPriceProvider(address(0));
    }

    function testRevertUpdateExpiry() public {
        vm.expectRevert(ImpVolPriceProvider.InvalidInput.selector);
        impVolPriceProvider.updateExpiry(block.timestamp - 5 days);
    }

    function testRevertLatestPrice() private {
        vm.expectRevert(ImpVolPriceProvider.ExpiredMarket.selector);
        vm.roll(expiryTimestamp + 1);
        impVolPriceProvider.getLatestPrice();
    }
}
