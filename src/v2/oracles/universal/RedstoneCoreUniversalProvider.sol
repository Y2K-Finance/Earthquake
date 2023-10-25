// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IUniversalProvider} from "../../interfaces/IUniversalProvider.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@redstone-finance/evm-connector/contracts/data-services/PrimaryProdDataServiceConsumerBase.sol";
import {console} from "forge-std/console.sol";

contract RedstoneCoreUniversalProvider is
    Ownable,
    PrimaryProdDataServiceConsumerBase,
    IUniversalProvider
{
    uint256 public immutable timeOut;

    mapping(uint256 => uint256) public marketIdToConditionType;
    mapping(uint256 => bytes32) public marketIdToDataFeed;
    mapping(uint256 => uint256) public marketIdToPrice;
    mapping(uint256 => uint256) public marketIdToDecimals;
    mapping(uint256 => uint256) public marketIdToUpdatedAt;

    event MarketConditionSet(
        uint256 indexed marketId,
        uint256 indexed conditionType
    );
    event DataFeedSet(
        uint256 indexed marketId,
        bytes32 priceFeed,
        uint256 decimals
    );

    constructor(uint256 _timeOut) {
        if (_timeOut == 0) revert InvalidInput();
        timeOut = _timeOut;
    }

    /*//////////////////////////////////////////////////////////////
                                 ADMIN
    //////////////////////////////////////////////////////////////*/
    function setConditionType(
        uint256 _marketId,
        uint256 _condition
    ) external onlyOwner {
        if (marketIdToConditionType[_marketId] != 0) revert ConditionTypeSet();
        if (_condition != 1 && _condition != 2) revert InvalidInput();
        marketIdToConditionType[_marketId] = _condition;
        emit MarketConditionSet(_marketId, _condition);
    }

    function setPriceFeed(
        uint256 _marketId,
        bytes32 dataFeed,
        uint256 _decimals
    ) external onlyOwner {
        if (dataFeed == bytes32(0)) revert InvalidInput();
        marketIdToDataFeed[_marketId] = dataFeed;
        marketIdToDecimals[_marketId] = _decimals;
        emit DataFeedSet(_marketId, dataFeed, _decimals);
    }

    function updatePrices(uint256[] memory _marketIds) external {
        console.log("market id length", _marketIds.length);
        uint256[] memory prices = extractPrice(_marketIds);
        console.log("prices length", prices.length);
        uint256 length = _marketIds.length;
        for (uint256 i; i < length; ) {
            marketIdToPrice[_marketIds[i]] = prices[i];
            marketIdToUpdatedAt[_marketIds[i]] =
                extractTimestampsAndAssertAllAreEqual() /
                1000;
            unchecked {
                i++;
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                                 PUBLIC
    //////////////////////////////////////////////////////////////*/
    function decimals(
        uint256 marketId
    ) public view returns (uint256 _decimals) {
        _decimals = marketIdToDecimals[marketId];
    }

    function description(
        uint256 _marketId
    ) public view returns (string memory) {
        return string(abi.encodePacked(marketIdToDataFeed[_marketId]));
    }

    function getCurrentPrices(
        uint256[] memory _marketIds
    )
        public
        view
        returns (uint256[] memory prices, uint256[] memory updatedAt)
    {
        uint256 length = _marketIds.length;
        prices = new uint256[](length);
        updatedAt = new uint256[](length);
        for (uint256 i = 0; i < length; i += 1) {
            prices[i] = marketIdToPrice[_marketIds[i]];
            updatedAt[i] = marketIdToUpdatedAt[_marketIds[i]];
        }
    }

    function getDataFeeds(
        uint256[] memory _marketIds
    ) public view returns (bytes32[] memory dataFeeds) {
        uint256 length = _marketIds.length;
        dataFeeds = new bytes32[](length);
        for (uint256 i; i < length; ) {
            dataFeeds[i] = marketIdToDataFeed[_marketIds[i]];
            unchecked {
                i++;
            }
        }
    }

    function extractPrice(
        uint256[] memory _marketIds
    ) public view returns (uint256[] memory price) {
        bytes32[] memory dataFeeds = getDataFeeds(_marketIds);
        // TODO: Remove
        for (uint i; i < dataFeeds.length; i += 1) {
            console.logBytes32(dataFeeds[i]);
        }
        return getOracleNumericValuesFromTxMsg(dataFeeds);
    }

    function latestRoundData(
        uint256 _marketId
    )
        public
        view
        returns (
            uint80 roundId,
            int256 price,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        updatedAt = marketIdToUpdatedAt[_marketId];
        price = int256(marketIdToPrice[_marketId]);
    }

    /** @notice Fetch token price from priceFeedAdapter (Redston oracle address)
     * @return int256 Current token price
     */
    function getLatestPrice(
        uint256 _marketId
    ) public view virtual returns (int256) {
        (, int256 price, , uint256 updatedAt, ) = latestRoundData(_marketId);
        if (price <= 0) revert OraclePriceZero();
        if ((block.timestamp - updatedAt) > timeOut) revert PriceTimedOut();

        uint256 feedDecimals = decimals(_marketId);
        if (feedDecimals < 18) {
            uint256 calcDecimals = 10 ** (18 - (feedDecimals));
            price = price * int256(calcDecimals);
        } else if (feedDecimals > 18) {
            uint256 calcDecimals = 10 ** ((feedDecimals - 18));
            price = price / int256(calcDecimals);
        }

        return price;
    }

    // NOTE: _marketId unused but receiving marketId makes Generic controller composabile for future
    /** @notice Fetch price and return condition
     * @param _strike Strike price
     * @return boolean If condition is met i.e. strike > price
     * @return price Current price for token
     */
    function conditionMet(
        uint256 _strike,
        uint256 _marketId
    ) public view virtual returns (bool, int256 price) {
        uint256 conditionType = marketIdToConditionType[_marketId];
        price = getLatestPrice(_marketId);

        if (conditionType == 1) return (int256(_strike) < price, price);
        else if (conditionType == 2) return (int256(_strike) > price, price);
        else revert ConditionTypeNotSet();
    }

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error ZeroAddress();
    error InvalidInput();
    error OraclePriceZero();
    error RoundIdOutdated();
    error PriceTimedOut();
    error ConditionTypeNotSet();
    error ConditionTypeSet();
}
