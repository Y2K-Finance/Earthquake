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
    // TODO: Check if this relates to an individual feed or is generic
    AggregatorV2V3Interface internal immutable _sequencerUptimeFeed;

    mapping(uint256 => address) public marketToPriceFeed;

    event PriceFeedStored(address priceFeed, uint256 marketId);

    constructor(address _sequencer, address _factory) {
        if (_factory == address(0)) revert ZeroAddress();
        vaultFactory = IVaultFactoryV2(_factory);

        if (_sequencer == address(0)) revert ZeroAddress();
        _sequencerUptimeFeed = AggregatorV2V3Interface(_sequencer);
    }

    // TODO: Need to add auth check
    // TODO: Should we check if the feed exists? Or will it never be changed?
    function storePriceFeed(uint256 _marketId, address _priceFeed) public {
        if (marketToPriceFeed[_marketId] != address(0)) revert FeedAlreadySet();
        if (_priceFeed == address(0)) revert ZeroAddress();

        marketToPriceFeed[_marketId] = _priceFeed;
        emit PriceFeedStored(_priceFeed, _marketId);
    }

    /** @notice Lookup token price
     * @param _marketId Target token address
     * @return nowPrice Current token price
     */
    function getLatestPrice(uint256 _marketId) public view returns (int256) {
        (, int256 answer, uint256 startedAt, , ) = _sequencerUptimeFeed
            .latestRoundData();

        // Answer == 0: Sequencer is up || Answer == 1: Sequencer is down
        bool isSequencerUp = answer == 0;
        if (!isSequencerUp) {
            revert SequencerDown();
        }

        // Make sure the grace period has passed after the sequencer is back up.
        uint256 timeSinceUp = block.timestamp - startedAt;
        if (timeSinceUp <= _GRACE_PERIOD_TIME) {
            revert GracePeriodNotOver();
        }

        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            marketToPriceFeed[_marketId]
        );
        if (address(priceFeed) == address(0)) revert ZeroAddress();

        (uint80 roundID, int256 price, , , uint80 answeredInRound) = priceFeed
            .latestRoundData();
        uint256 decimals = priceFeed.decimals();

        if (decimals < 18) {
            decimals = 10 ** (18 - (decimals));
            price = price * int256(decimals);
        } else if (decimals == 18) {
            price = price;
        } else {
            decimals = 10 ** ((decimals - 18));
            price = price / int256(decimals);
        }

        if (price <= 0) revert OraclePriceZero();

        if (answeredInRound < roundID) revert RoundIDOutdated();

        return price;
    }

    // TODO: What if want to check less than or equal to?
    function conditionMet(
        uint256 _strike,
        uint256 _marketId
    ) public view returns (bool) {
        return int256(_strike) > getLatestPrice(_marketId);
    }

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error MarketDoesNotExist(uint256 marketId);
    error SequencerDown();
    error GracePeriodNotOver();
    error ZeroAddress();
    error EpochFinishedAlready();
    error PriceNotAtStrikePrice(int256 price);
    error EpochNotStarted();
    error EpochExpired();
    error OraclePriceZero();
    error RoundIDOutdated();
    error EpochNotExist();
    error EpochNotExpired();
    error VaultNotZeroTVL();
    error VaultZeroTVL();
    error FeedAlreadySet();
}
