// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {
    AggregatorV3Interface
} from "@chainlink/interfaces/AggregatorV3Interface.sol";
import {
    AggregatorV2V3Interface
} from "@chainlink/interfaces/AggregatorV2V3Interface.sol";
import {IVaultFactoryV2} from "../interfaces/IVaultFactoryV2.sol";
import {IVaultV2} from "../interfaces/IVaultV2.sol";
import {IConditionProvider} from "./IConditionProvider.sol";

contract ChainlinkPriceProvider is IConditionProvider {
    uint16 private constant _GRACE_PERIOD_TIME = 3600;
    IVaultFactoryV2 public immutable vaultFactory;
    AggregatorV2V3Interface public immutable sequencerUptimeFeed;
    AggregatorV3Interface public immutable priceFeed;

    constructor(address _sequencer, address _factory, address _priceFeed) {
        if (_factory == address(0)) revert ZeroAddress();
        if (_sequencer == address(0)) revert ZeroAddress();
        if (_priceFeed == address(0)) revert ZeroAddress();
        vaultFactory = IVaultFactoryV2(_factory);
        sequencerUptimeFeed = AggregatorV2V3Interface(_sequencer);
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    /** @notice Lookup token price
     * @param _marketId Target token address
     * @return nowPrice Current token price
     */
    function getLatestPrice(uint256 _marketId) public view returns (int256) {
        (, int256 answer, uint256 startedAt, , ) = sequencerUptimeFeed
            .latestRoundData();

        // Answer == 0: Sequencer is up || Answer == 1: Sequencer is down
        if (!(answer == 0)) {
            revert SequencerDown();
        }

        // Make sure the grace period has passed after the sequencer is back up - timeSinceUp <= PERIOD
        if ((block.timestamp - startedAt) <= _GRACE_PERIOD_TIME) {
            revert GracePeriodNotOver();
        }

        (uint80 roundID, int256 price, , , uint80 answeredInRound) = priceFeed
            .latestRoundData();
        // NOTE: Removed previous decimal scaling logic - need to confirm why being used
        if (price <= 0) revert OraclePriceZero();
        if (answeredInRound < roundID) revert RoundIdOutdated();

        return price;
    }

    function conditionMet(
        uint256 _strike,
        uint256 _marketId
    ) public view virtual returns (bool, int256 price) {
        price = getLatestPrice(_marketId);
        return (int256(_strike) > price, price);
    }

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error SequencerDown();
    error GracePeriodNotOver();
    error OraclePriceZero();
    error RoundIdOutdated();
    error ZeroAddress();
}
