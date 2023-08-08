// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Helper} from "../../Helper.sol";
import {VaultFactoryV2} from "../../../../src/v2/VaultFactoryV2.sol";
import {
    CVIPriceProvider
} from "../../../../src/v2/oracles/individual/CVIPriceProvider.sol";
import {TimeLock} from "../../../../src/v2/TimeLock.sol";
import {
    MockOracleAnswerZeroCVI,
    MockOracleTimeOutCVI
} from "../MockOracles.sol";

contract CVIPriceProviderTest is Helper {
    uint256 public arbForkId;
    VaultFactoryV2 public factory;
    CVIPriceProvider public cviPriceProvider;
    uint256 public marketId = 1;

    ////////////////////////////////////////////////
    //                HELPERS                     //
    ////////////////////////////////////////////////

    function setUp() public {
        arbForkId = vm.createFork(ARBITRUM_RPC_URL);
        vm.selectFork(arbForkId);

        address timelock = address(new TimeLock(ADMIN));
        factory = new VaultFactoryV2(WETH, TREASURY, address(timelock));
        cviPriceProvider = new CVIPriceProvider(
            CVI_ORACLE,
            TIME_OUT,
            CVI_DECIMALS
        );

        uint256 condition = 1;
        cviPriceProvider.setConditionType(marketId, condition);
    }

    ////////////////////////////////////////////////
    //                STATE                       //
    ////////////////////////////////////////////////
    function testCVICreation() public {
        assertEq(cviPriceProvider.timeOut(), TIME_OUT);
        assertEq(address(cviPriceProvider.priceFeedAdapter()), CVI_ORACLE);
        assertEq(cviPriceProvider.decimals(), CVI_DECIMALS);
        assertEq(cviPriceProvider.description(), "CVI");
    }

    ////////////////////////////////////////////////
    //                FUNCTIONS                  //
    ////////////////////////////////////////////////
    function testLatestRoundDataCVI() public {
        (
            uint80 roundId,
            int256 price,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = cviPriceProvider.latestRoundData();
        assertTrue(price != 0);
        assertTrue(roundId != 0);
        assertEq(startedAt, 1);
        assertTrue(updatedAt != 0);
        assertTrue(answeredInRound != 0);
    }

    function testLatestPriceCVI() public {
        int256 price = cviPriceProvider.getLatestPrice();
        assertTrue(price != 0);
    }

    function testConditionOneMetCVI() public {
        (bool condition, int256 price) = cviPriceProvider.conditionMet(
            100,
            marketId
        );
        assertTrue(price != 0);
        assertEq(condition, true);
    }

    function testConditionTwoMetCVI() public {
        uint256 conditionType = 2;
        uint256 marketIdTwo = 2;
        cviPriceProvider.setConditionType(marketIdTwo, conditionType);
        (bool condition, int256 price) = cviPriceProvider.conditionMet(
            0.1 ether,
            marketIdTwo
        );
        assertTrue(price != 0);
        assertEq(condition, true);
    }

    ////////////////////////////////////////////////
    //              REVERT CASES                  //
    ////////////////////////////////////////////////
    function testRevertConstructorInputs() public {
        vm.expectRevert(CVIPriceProvider.ZeroAddress.selector);
        new CVIPriceProvider(address(0), TIME_OUT, CVI_DECIMALS);

        vm.expectRevert(CVIPriceProvider.InvalidInput.selector);
        new CVIPriceProvider(CVI_ORACLE, 0, CVI_DECIMALS);
    }

    function testRevertConditionTypeSetCVI() public {
        vm.expectRevert(CVIPriceProvider.ConditionTypeSet.selector);
        cviPriceProvider.setConditionType(1, 0);
    }

    function testRevertInvalidInputConditionCVI() public {
        vm.expectRevert(CVIPriceProvider.InvalidInput.selector);
        cviPriceProvider.setConditionType(0, 0);

        vm.expectRevert(CVIPriceProvider.InvalidInput.selector);
        cviPriceProvider.setConditionType(0, 3);
    }

    function testRevertOraclePriceZeroCVI() public {
        address mockOracle = address(new MockOracleAnswerZeroCVI());
        cviPriceProvider = new CVIPriceProvider(
            mockOracle,
            TIME_OUT,
            CVI_DECIMALS
        );
        vm.expectRevert(CVIPriceProvider.OraclePriceZero.selector);
        cviPriceProvider.getLatestPrice();
    }

    function testRevertTimeOut() public {
        address mockOracle = address(
            new MockOracleTimeOutCVI(block.timestamp, TIME_OUT)
        );
        cviPriceProvider = new CVIPriceProvider(
            mockOracle,
            TIME_OUT,
            CVI_DECIMALS
        );
        vm.expectRevert(CVIPriceProvider.PriceTimedOut.selector);
        cviPriceProvider.getLatestPrice();
    }
}
