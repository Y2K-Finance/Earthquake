// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Helper} from "../Helper.sol";
import {VaultFactoryV2} from "../../../src/v2/VaultFactoryV2.sol";
import {TimeLock} from "../../../src/v2/TimeLock.sol";
import {DIAPriceProvider} from "../../../src/v2/oracles/DIAPriceProvider.sol";
import {
    MockOracleAnswerOne,
    MockOracleGracePeriod,
    MockOracleAnswerZero,
    MockOracleRoundOutdated,
    MockOracleTimeOut
} from "./MockOracles.sol";

contract DIAPriceProviderTest is Helper {
    DIAPriceProvider public diaPriceProvider;
    uint256 public arbForkId;
    string public pairName = "BTC/USD";
    uint256 public strikePrice = 50_000e8;

    ////////////////////////////////////////////////
    //                HELPERS                     //
    ////////////////////////////////////////////////
    function setUp() public {
        arbForkId = vm.createFork(ARBITRUM_RPC_URL);
        vm.selectFork(arbForkId);

        diaPriceProvider = new DIAPriceProvider(DIA_ORACLE_V2);
    }

    ////////////////////////////////////////////////
    //                STATE                       //
    ////////////////////////////////////////////////
    function testDIACreation() public {
        assertEq(address(diaPriceProvider.diaPriceFeed()), DIA_ORACLE_V2);
        assertEq(
            abi.encode(diaPriceProvider.PAIR_NAME()),
            abi.encode(pairName)
        );
    }

    ////////////////////////////////////////////////
    //                FUNCTIONS                  //
    ////////////////////////////////////////////////
    function testLatestPrice() public {
        int256 price = diaPriceProvider.getLatestPrice();
        assertTrue(price != 0);
    }

    function testConditionMetDIA() public {
        (bool condition, int256 price) = diaPriceProvider.conditionMet(
            strikePrice
        );
        assertTrue(price != 0);
        assertEq(condition, true);
    }

    ////////////////////////////////////////////////
    //              REVERT CASES                  //
    ////////////////////////////////////////////////

    function testRevertConstructorInputs() public {
        vm.expectRevert(DIAPriceProvider.ZeroAddress.selector);
        new DIAPriceProvider(address(0));
    }
}
