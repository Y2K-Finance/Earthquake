// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Helper} from "../../Helper.sol";
import {
    PythPriceProvider
} from "../../../../src/v2/oracles/individual/PythPriceProvider.sol";
import {TimeLock} from "../../../../src/v2/TimeLock.sol";
import {
    MockOracleAnswerNegativePyth,
    MockOracleExponentTooSmallPyth
} from "../MockOracles.sol";
import {IPriceFeedAdapter} from "../PriceInterfaces.sol";

contract PythPriceProviderTest is Helper {
    uint256 public arbForkId;
    PythPriceProvider public pythProvider;
    uint256 public marketId = 2;

    ////////////////////////////////////////////////
    //                HELPERS                     //
    ////////////////////////////////////////////////

    function setUp() public {
        arbForkId = vm.createFork(ARBITRUM_RPC_URL);
        vm.selectFork(arbForkId);

        pythProvider = new PythPriceProvider(
            PYTH_CONTRACT,
            PYTH_FDUSD_FEED_ID,
            TIME_OUT,
            18
        );

        uint256 condition = 2;
        pythProvider.setConditionType(marketId, condition);
    }

    ////////////////////////////////////////////////
    //                STATE                       //
    ////////////////////////////////////////////////

    function testRedStoneCreation() public {
        assertEq(pythProvider.timeOut(), TIME_OUT);
        assertEq(pythProvider.priceFeedId(), PYTH_FDUSD_FEED_ID);
        assertEq(address(pythProvider.pyth()), PYTH_CONTRACT);
        assertEq(pythProvider.decimals(), 18);
    }

    ////////////////////////////////////////////////
    //                FUNCTIONS                  //
    ////////////////////////////////////////////////
    function testLatestRoundDataPyth() public {
        (
            uint80 roundId,
            int256 price,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = pythProvider.latestRoundData();
        assertTrue(price != 0);
        assertTrue(updatedAt != 0);
    }

    function testLatestPricePyth() public {
        int256 price = pythProvider.getLatestPrice();
        assertTrue(price != 0);
    }

    function testConditionMet() public {
        (bool condition, int256 price) = pythProvider.conditionMet(
            2 ether,
            marketId
        );
        assertTrue(price != 0);
        assertEq(condition, true);
    }

    function testConditionOneMetPyth() public {
        uint256 conditionType = 1;
        uint256 marketIdOne = 1;
        pythProvider.setConditionType(marketIdOne, conditionType);
        (bool condition, int256 price) = pythProvider.conditionMet(
            0.01 ether,
            marketIdOne
        );
        assertTrue(price != 0);
        assertEq(condition, true);
    }

    function testConditionTwoMetPyth() public {
        (bool condition, int256 price) = pythProvider.conditionMet(
            2 ether,
            marketId
        );
        assertTrue(price != 0);
        assertEq(condition, true);
    }

    ////////////////////////////////////////////////
    //              REVERT CASES                  //
    ////////////////////////////////////////////////

    function testRevertConstructorInputs() public {
        vm.expectRevert(PythPriceProvider.ZeroAddress.selector);
        new PythPriceProvider(address(0), PYTH_FDUSD_FEED_ID, TIME_OUT, 18);

        vm.expectRevert(PythPriceProvider.InvalidInput.selector);
        new PythPriceProvider(PYTH_CONTRACT, bytes32(0), TIME_OUT, 18);

        vm.expectRevert(PythPriceProvider.InvalidInput.selector);
        new PythPriceProvider(PYTH_CONTRACT, PYTH_FDUSD_FEED_ID, 0, 18);
    }

    function testRevertConditionTypeSetPyth() public {
        vm.expectRevert(PythPriceProvider.ConditionTypeSet.selector);
        pythProvider.setConditionType(2, 0);
    }

    function testRevertInvalidInputConditionPyth() public {
        vm.expectRevert(PythPriceProvider.InvalidInput.selector);
        pythProvider.setConditionType(0, 0);

        vm.expectRevert(PythPriceProvider.InvalidInput.selector);
        pythProvider.setConditionType(0, 3);
    }

    function testRevertOraclePriceNegative() public {
        address mockPyth = address(new MockOracleAnswerNegativePyth());
        pythProvider =  new PythPriceProvider(
            mockPyth,
            PYTH_FDUSD_FEED_ID,
            TIME_OUT,
            18
        );
        vm.expectRevert(PythPriceProvider.OraclePriceNegative.selector);
        pythProvider.getLatestPrice();
    }

    function testRevertOracleExponentTooSmall() public {
        address mockPyth = address(new MockOracleExponentTooSmallPyth());
        pythProvider =  new PythPriceProvider(
            mockPyth,
            PYTH_FDUSD_FEED_ID,
            TIME_OUT,
            18
        );
        vm.expectRevert(PythPriceProvider.ExponentTooSmall.selector);
        pythProvider.getLatestPrice();
    }
}
