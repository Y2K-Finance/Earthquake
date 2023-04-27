// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/interfaces/AggregatorV3Interface.sol";
import "@chainlink/interfaces/AggregatorV2V3Interface.sol";
import "@redstone-finance/evm-connector/contracts/data-services/RapidDemoConsumerBase.sol";

import {IVaultFactoryV2} from "../interfaces/IVaultFactoryV2.sol";
import {IVaultV2} from "../interfaces/IVaultV2.sol";

import "./IPriceProvider.sol";
import "./RedstonePriceProvider.sol";

contract RedstoneMockPriceProvider is RedstonePriceProvider {

    uint256 marketId;

    constructor(address _sequencer, address _factory, string memory _symbol) RedstonePriceProvider(_sequencer, _factory, _symbol) {
       
    }
        
    function setMarket(uint256 _marketId) public {
        marketId = _marketId;
    }

    function getLatestRawPrice() public override view returns (int256) {
        if (marketId == 0) revert ZeroAddress();
    
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            vaultFactory.marketToOracle(marketId)
        );
        
        (uint80 roundID, int256 price, , , uint80 answeredInRound) = priceFeed
            .latestRoundData();
        return price;
    }
    
    
    function getLatestRawDecimals() public override view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            vaultFactory.marketToOracle(marketId)
        );
        
        (uint80 roundID, int256 price, , , uint80 answeredInRound) = priceFeed
            .latestRoundData();
       uint256 decimals = priceFeed.decimals(); 
       return  decimals;
    }
}



