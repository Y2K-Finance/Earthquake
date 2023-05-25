// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {
    AggregatorV3Interface
} from "@chainlink/interfaces/AggregatorV3Interface.sol";
import {
    AggregatorV2V3Interface
} from "@chainlink/interfaces/AggregatorV2V3Interface.sol";
import {IVaultFactoryV2} from "../interfaces/IVaultFactoryV2.sol";
import {IVaultV2} from "../interfaces/IVaultV2.sol";
import {IConditionProvider} from "./IConditionProvider.sol";
import {RedstonePriceProvider} from "./RedstonePriceProvider.sol";

contract RedstoneMockPriceProvider is RedstonePriceProvider {
    mapping(uint256 => address) public marketToPriceFeed;

    event PriceFeedStored(address priceFeed, uint256 marketId);

    constructor(
        address _factory,
        address _priceFeedAdapter
    ) RedstonePriceProvider(_factory, _priceFeedAdapter) {}

    // TODO: Need to add auth check
    function storePriceFeed(uint256 _marketId, address _priceFeed) public {
        if (marketToPriceFeed[_marketId] != address(0)) revert FeedAlreadySet();
        if (_priceFeed == address(0)) revert ZeroAddress();

        marketToPriceFeed[_marketId] = _priceFeed;
        emit PriceFeedStored(_priceFeed, _marketId);
    }

    function getLatestPrice(
        uint256 _marketId
    ) public view override returns (int256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            marketToPriceFeed[_marketId]
        );
        if (address(priceFeed) == address(0)) revert ZeroAddress();

        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price;
    }
}
