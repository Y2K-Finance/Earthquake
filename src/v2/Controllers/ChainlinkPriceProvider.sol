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
    AggregatorV2V3Interface public immutable _sequencerUptimeFeed;

    mapping(uint256 => address) public marketToPriceFeed;
    mapping(uint256 => uint256) public marketToCondition;

    event MarketStored(address priceFeed, uint256 marketId, uint256 condition);

    constructor(address _sequencer, address _factory) {
        if (_factory == address(0)) revert ZeroAddress();
        if (_sequencer == address(0)) revert ZeroAddress();
        vaultFactory = IVaultFactoryV2(_factory);
        _sequencerUptimeFeed = AggregatorV2V3Interface(_sequencer);
    }

    // TODO: Add auth check for ... ?
    function storeMarket(
        address _priceFeed,
        uint256 _marketId,
        uint256 _condition
    ) public {
        if (_condition == 0 || _condition > 3) revert InvalidInput();
        if (_priceFeed == address(0)) revert ZeroAddress();
        // TODO: Remove the feed check ??
        if (marketToPriceFeed[_marketId] != address(0)) revert FeedAlreadySet();

        marketToPriceFeed[_marketId] = _priceFeed;
        marketToCondition[_marketId] = _condition;
        emit MarketStored(_priceFeed, _marketId, _condition);
    }

    /** @notice Lookup token price
     * @param _marketId Target token address
     * @return nowPrice Current token price
     */
    function getLatestPrice(uint256 _marketId) public view returns (int256) {
        (, int256 answer, uint256 startedAt, , ) = _sequencerUptimeFeed
            .latestRoundData();

        // Answer == 0: Sequencer is up || Answer == 1: Sequencer is down
        if (!(answer == 0)) {
            revert SequencerDown();
        }

        // Make sure the grace period has passed after the sequencer is back up - timeSinceUp <= PERIOD
        if ((block.timestamp - startedAt) <= _GRACE_PERIOD_TIME) {
            revert GracePeriodNotOver();
        }

        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            marketToPriceFeed[_marketId]
        );
        if (address(priceFeed) == address(0)) revert ZeroAddress();

        (uint80 roundID, int256 price, , , uint80 answeredInRound) = priceFeed
            .latestRoundData();
        // NOTE: Removed previous decimal scaling logic - need to confirm why being used
        if (price <= 0) revert OraclePriceZero();

        if (answeredInRound < roundID) revert RoundIDOutdated();

        return price;
    }

    function conditionMet(
        uint256 _strike,
        uint256 _marketId
    ) public view virtual returns (bool, int256 price) {
        uint256 condition = marketToCondition[_marketId];
        if (condition == 1) {
            price = getLatestPrice(_marketId);
            return (int256(_strike) > price, price);
        } else if (condition == 2) {
            price = getLatestPrice(_marketId);
            return (int256(_strike) < price, price);
        } else if (condition == 3) {
            price = getLatestPrice(_marketId);
            return (int256(_strike) == price, price);
        } else revert ConditionNotSet();
    }

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error SequencerDown();
    error GracePeriodNotOver();
    error OraclePriceZero();
    error RoundIDOutdated();
    error InvalidInput();
    error ZeroAddress();
    error ConditionNotSet();
    error ConditionAlreadySet();
    error FeedAlreadySet();
}
