/******************************************************* 
NOTE: Development in progress by JG. Reached functional milestone; Live VST data is accessible. 
***/
// SPDX-License-Identifier: MIT
//pragma solidity ^0.8.4;
pragma solidity ^0.8.0;

import "@chainlink/interfaces/AggregatorV3Interface.sol";
import "@chainlink/interfaces/AggregatorV2V3Interface.sol";
import "@redstone-finance/evm-connector/contracts/data-services/RapidDemoConsumerBase.sol";

import {IVaultFactoryV2} from "../interfaces/IVaultFactoryV2.sol";
import {IVaultV2} from "../interfaces/IVaultV2.sol";

import "./IPriceProvider.sol";
import "./RedstonePriceProvider.sol";

contract RedstoneMockPriceProvider is RedstonePriceProvider {

    constructor(address _sequencer, address _factory) RedstonePriceProvider(_sequencer, _factory) {
       
    }

    function getLatestRawPrice(address _token) public override view returns (int256) {
    
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            vaultFactory.tokenToOracle(_token)
        );
        
        (uint80 roundID, int256 price, , , uint80 answeredInRound) = priceFeed
            .latestRoundData();
        return price;
    }
    
    
    function getLatestRawDecimals(address _token) public override view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            vaultFactory.tokenToOracle(_token)
        );
        
        (uint80 roundID, int256 price, , , uint80 answeredInRound) = priceFeed
            .latestRoundData();
       uint256 decimals = priceFeed.decimals(); 
       return  decimals;
    }
}



