// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {
    AggregatorV3Interface
} from "@chainlink/interfaces/AggregatorV3Interface.sol";
import {
    AggregatorV2V3Interface
} from "@chainlink/interfaces/AggregatorV2V3Interface.sol";
import {IVaultFactoryV2} from "../interfaces/IVaultFactoryV2.sol";
import {IConditionProvider} from "../interfaces/IConditionProvider.sol";

contract ChainlinkPriceProvider is IConditionProvider {
    uint16 private constant _GRACE_PERIOD_TIME = 3600;
    uint256 public immutable timeOut;
    IVaultFactoryV2 public immutable vaultFactory;
    AggregatorV2V3Interface public immutable sequencerUptimeFeed;
    AggregatorV3Interface public immutable priceFeed;

    constructor(
        address _sequencer,
        address _factory,
        address _priceFeed,
        uint256 _timeOut
    ) {
        if (_factory == address(0)) revert ZeroAddress();
        if (_sequencer == address(0)) revert ZeroAddress();
        if (_priceFeed == address(0)) revert ZeroAddress();
        if (_timeOut == 0) revert InvalidInput();
        vaultFactory = IVaultFactoryV2(_factory);
        sequencerUptimeFeed = AggregatorV2V3Interface(_sequencer);
        priceFeed = AggregatorV3Interface(_priceFeed);
        timeOut = _timeOut;
    }

    /** @notice Fetch token price from priceFeed (Chainlink oracle address)
     * @return int256 Current token price
     */
    function getLatestPrice() public view returns (int256) {
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

        (
            uint80 roundID,
            int256 price,
            ,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        if (price <= 0) revert OraclePriceZero();
        if (answeredInRound < roundID) revert RoundIdOutdated();
        // NOTE: fetching updatedAt for USDC had no updates from 1685019769 to 1685096282 i.e for 21 hours
        // TODO: Need to review the updatedAt window as it was 21 hours for USDC on Arb
        // TODO: What is a suitable timeframe to set timeout as based on this info?
        if ((block.timestamp - updatedAt) > timeOut) revert PriceTimedOut();

        return price;
    }

    /** @notice Fetch price and return condition
     * @param _strike Strike price
     * @return boolean If condition is met i.e. strike > price
     * @return price Current price for token
     */
    function conditionMet(
        uint256 _strike
    ) public view virtual returns (bool, int256 price) {
        price = getLatestPrice();
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
    error PriceTimedOut();
    error InvalidInput();
}
