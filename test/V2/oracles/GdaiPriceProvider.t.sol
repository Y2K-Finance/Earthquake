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
import {IPriceFeedAdapter} from "./PriceInterfaces.sol";

contract GdaiPriceProviderTest is Helper {
    GdaiPriceProvider public gdaiPriceProvider;
    uint256 public arbForkId;
    int256 public strikePrice = -8994085036142722;
    uint256 public marketId = 2;

    event StrikeUpdated(uint256 marketId, bytes strikeHash, int256 strikePrice);

    ////////////////////////////////////////////////
    //                HELPERS                     //
    ////////////////////////////////////////////////
    function setUp() public {
        arbForkId = vm.createFork(ARBITRUM_RPC_URL);
        vm.selectFork(arbForkId);

        gdaiPriceProvider = new GdaiPriceProvider(GDAI_VAULT);
        uint256 condition = 2;
        gdaiPriceProvider.setConditionType(marketId, condition);
    }

    ////////////////////////////////////////////////
    //                STATE                       //
    ////////////////////////////////////////////////
    function testGdaiCreation() public {
        assertEq(address(gdaiPriceProvider.gdaiPriceFeed()), GDAI_VAULT);
        // assertEq(
        //     gdaiPriceProvider.decimals(),
        //     IPriceFeedAdapter(GDAI_VAULT).decimals()
        // );
        // assertEq(
        //     gdaiPriceProvider.description(),
        //     IPriceFeedAdapter(GDAI_VAULT).symbol()
        // );
    }

    ////////////////////////////////////////////////
    //                FUNCTIONS                  //
    ////////////////////////////////////////////////
    function testLatestRoundDataGdai() public {
        (
            uint80 roundId,
            int256 price,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = gdaiPriceProvider.latestRoundData();
        assertTrue(price != 0);
        assertTrue(roundId != 0);
        assertTrue(startedAt != 0);
        assertTrue(updatedAt != 0);
        assertTrue(answeredInRound != 0);
    }

    function testLatestPrice() public {
        int256 price = gdaiPriceProvider.getLatestPrice();
        assertTrue(price != 0);
    }

    function testConditionOneMetGdai() public {
        uint256 conditionType = 1;
        uint256 marketIdOne = 1;
        gdaiPriceProvider.setConditionType(marketIdOne, conditionType);
        int256 newStrike = -10 ether;
        (bool condition, int256 price) = gdaiPriceProvider.conditionMet(
            uint256(newStrike),
            marketIdOne
        );
        assertTrue(price != 0);
        assertEq(condition, true);
    }

    function testConditionTwoMetGdai() public {
        (bool condition, int256 price) = gdaiPriceProvider.conditionMet(
            uint256(strikePrice),
            marketId
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

    function testRevertConditionTypeSetGdai() public {
        vm.expectRevert(GdaiPriceProvider.ConditionTypeSet.selector);
        gdaiPriceProvider.setConditionType(2, 0);
    }

    function testRevertInvalidInputConditionGdai() public {
        vm.expectRevert(GdaiPriceProvider.InvalidInput.selector);
        gdaiPriceProvider.setConditionType(0, 0);

        vm.expectRevert(GdaiPriceProvider.InvalidInput.selector);
        gdaiPriceProvider.setConditionType(0, 3);
    }
}
