// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Helper} from "../Helper.sol";
import {VaultFactoryV2} from "../../../src/v2/VaultFactoryV2.sol";
import {TimeLock} from "../../../src/v2/TimeLock.sol";
import {
    GdaiPriceProviderV1
} from "../../../src/v2/oracles/GDaiPriceProviderV1.sol";
import {
    GdaiPriceProviderV2
} from "../../../src/v2/oracles/GDaiPriceProviderV2.sol";
import {
    MockOracleAnswerOne,
    MockOracleGracePeriod,
    MockOracleAnswerZero,
    MockOracleRoundOutdated,
    MockOracleTimeOut
} from "./MockOracles.sol";

contract GdaiPriceProviderTest is Helper {
    GdaiPriceProviderV1 public gdaiPriceProviderV1;
    GdaiPriceProviderV2 public gdaiPriceProviderV2;
    uint256 public arbForkId;

    ////////////////////////////////////////////////
    //                HELPERS                     //
    ////////////////////////////////////////////////
    function setUp() public {
        arbForkId = vm.createFork(ARBITRUM_RPC_URL);
        vm.selectFork(arbForkId);

        gdaiPriceProviderV1 = new GdaiPriceProviderV1(GDAI_VAULT);
        gdaiPriceProviderV2 = new GdaiPriceProviderV2(GDAI_VAULT);
    }

    ////////////////////////////////////////////////
    //                STATE                       //
    ////////////////////////////////////////////////
    function testGdaiV1Creation() public {
        assertEq(address(gdaiPriceProviderV1.gdaiPriceFeed()), GDAI_VAULT);
    }

    function testGdaiV2Creation() public {
        assertEq(address(gdaiPriceProviderV2.gdaiPriceFeed()), GDAI_VAULT);
    }

    ////////////////////////////////////////////////
    //                FUNCTIONS                  //
    ////////////////////////////////////////////////
    function testLatestPriceV1() public {
        int256 price = gdaiPriceProviderV1.getLatestPrice();
        assertTrue(price != 0);
    }

    function testLatestPriceV2() public {
        int256 price = gdaiPriceProviderV2.getLatestPrice();
        assertTrue(price != 0);
    }

    function testConditionMetV1() public {
        (bool condition, int256 price) = gdaiPriceProviderV1.conditionMet(
            -200 ether
        );
        assertTrue(price != 0);
        assertEq(condition, true);
    }

    function testConditionMetV2() public {
        (bool condition, int256 price) = gdaiPriceProviderV2.conditionMet(
            0.1 ether
        );
        assertTrue(price != 0);
        assertEq(condition, true);
    }

    ////////////////////////////////////////////////
    //              REVERT CASES                  //
    ////////////////////////////////////////////////

    function testRevertConstructorInputsV1() public {
        vm.expectRevert(GdaiPriceProviderV1.ZeroAddress.selector);
        new GdaiPriceProviderV1(address(0));
    }

    function testRevertConstructorInputsV2() public {
        vm.expectRevert(GdaiPriceProviderV2.ZeroAddress.selector);
        new GdaiPriceProviderV2(address(0));
    }
}
