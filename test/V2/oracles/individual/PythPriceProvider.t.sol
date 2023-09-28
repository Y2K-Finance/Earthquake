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
import {IPyth} from "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import {PythStructs} from "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";

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
            TIME_OUT
        );

        uint256 condition = 2;
        pythProvider.setConditionType(marketId, condition);
    }

    ////////////////////////////////////////////////
    //                STATE                       //
    ////////////////////////////////////////////////

    function testCreation() public {
        assertEq(pythProvider.timeOut(), TIME_OUT);
        assertEq(pythProvider.priceFeedId(), PYTH_FDUSD_FEED_ID);
        assertEq(address(pythProvider.pyth()), PYTH_CONTRACT);

        PythStructs.Price memory answer = IPyth(PYTH_CONTRACT).getPriceUnsafe(
            PYTH_FDUSD_FEED_ID
        );
        assertEq(pythProvider.decimals(), uint256(int256(-answer.expo)));
    }

    ////////////////////////////////////////////////
    //                FUNCTIONS                  //
    ////////////////////////////////////////////////
    function testLatestRoundDataPyth() public {
        (, int256 price, , uint256 updatedAt, ) = pythProvider
            .latestRoundData();
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
        new PythPriceProvider(address(0), PYTH_FDUSD_FEED_ID, TIME_OUT);

        vm.expectRevert(PythPriceProvider.InvalidInput.selector);
        new PythPriceProvider(PYTH_CONTRACT, bytes32(0), TIME_OUT);

        vm.expectRevert(PythPriceProvider.InvalidInput.selector);
        new PythPriceProvider(PYTH_CONTRACT, PYTH_FDUSD_FEED_ID, 0);
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
        pythProvider = new PythPriceProvider(
            mockPyth,
            PYTH_FDUSD_FEED_ID,
            TIME_OUT
        );
        vm.expectRevert(PythPriceProvider.OraclePriceNegative.selector);
        pythProvider.getLatestPrice();
    }

    function testRevertOracleExponentTooSmall() public {
        address mockPyth = address(new MockOracleExponentTooSmallPyth());
        pythProvider = new PythPriceProvider(
            mockPyth,
            PYTH_FDUSD_FEED_ID,
            TIME_OUT
        );
        PythStructs.Price memory answer = IPyth(mockPyth).getPriceUnsafe(
            PYTH_FDUSD_FEED_ID
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                PythPriceProvider.ExponentTooSmall.selector,
                answer.expo
            )
        );
        pythProvider.getLatestPrice();
    }
}
