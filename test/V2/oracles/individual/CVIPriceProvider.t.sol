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
} from "../mocks/MockOracles.sol";

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
        uint256 strikePrice = 101; // 1100101
        (bool condition, int256 price) = cviPriceProvider.conditionMet(
            strikePrice,
            marketId
        );
        assertTrue(price != 0);
        assertEq(condition, true);
    }

    function testConditionTwoMetCVI() public {
        uint256 marketIdTwo = 2;
        uint256 strikePrice = 0.1 ether * 10 ** 18;

        (bool condition, int256 price) = cviPriceProvider.conditionMet(
            strikePrice,
            marketIdTwo
        );
        assertTrue(price != 0);
        assertEq(condition, true);
    }

    function testConditionModuloCVI() public {
        uint256 marketIdOne = 1;

        uint256 newStrike = 32222872726273485958746564738398; // Last bit is a 0
        (bool condition, int256 price) = cviPriceProvider.conditionMet(
            uint256(newStrike),
            marketIdOne
        );
        assertEq(condition, true);

        newStrike = 8889999573829384654738291019874637282864372; // Last bit is a 0
        (condition, price) = cviPriceProvider.conditionMet(
            uint256(newStrike),
            marketIdOne
        );
        assertEq(condition, true);

        newStrike = 335162336; // Last bit is a 0
        (condition, price) = cviPriceProvider.conditionMet(
            uint256(newStrike),
            marketIdOne
        );
        assertEq(condition, false);

        newStrike = 574832910; // Last bit is a 0
        (condition, price) = cviPriceProvider.conditionMet(
            uint256(newStrike),
            marketIdOne
        );
        assertEq(condition, false);

        newStrike = 778872637281; // Last bit is a 1
        (condition, price) = cviPriceProvider.conditionMet(
            uint256(newStrike),
            marketIdOne
        );
        assertEq(condition, true);

        newStrike = 2271718293; // Last bit is a 1
        (condition, price) = cviPriceProvider.conditionMet(
            uint256(newStrike),
            marketIdOne
        );
        assertEq(condition, true);

        newStrike = 9900000000049475684939287919117; // Last bit is a 1
        (condition, price) = cviPriceProvider.conditionMet(
            uint256(newStrike),
            marketIdOne
        );
        assertEq(condition, false);

        newStrike = 11901981727465654748499383745647383899283; // Last bit is a 1
        (condition, price) = cviPriceProvider.conditionMet(
            uint256(newStrike),
            marketIdOne
        );
        assertEq(condition, false);
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
