/******************************************************* 
NOTE: Development in progress by JG. Reached functional milestone; Live VST data is accessible. 
***/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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


/******************************************************* 
NOTE: Development in progress by JG. Reached functional milestone; Live VST data is accessible. 
Below was the testing script used to access live data using this contract. 
The Smart Contract below has been tested via https://github.com/redstone-finance/redstone-evm-examples
--- To conduct a test, one can (a) pull the repo (b) add the contract into contracts, and (c) this test script into tests. Then run yarn test, and oobserve the VST data. 

TODO / Puzzles:
- Y2K: How do we simulate Historical Data for this VST service 
- RedStone: How do we replicate the function of "usingDataService" on chain?


const { WrapperBuilder } = require("@redstone-finance/evm-connector");
//const { ethers } = require("ethers");


describe("RedstonePriceProvider", function () {
  let contract;

  beforeEach(async () => {
    // Deploy contract
    const RedstonePriceProvider = await ethers.getContractFactory("RedstonePriceProvider");
    //contract = await RedstonePriceProvider.deploy();
    const sequencerAddress = ethers.constants.AddressZero;
    const factoryAddress = ethers.constants.AddressZero;
    contract = await RedstonePriceProvider.deploy(sequencerAddress, factoryAddress);
      
  });

  it("Get VST price securely", async function () {
    // Wrapping the contract
    const wrappedContract = WrapperBuilder.wrap(contract).usingDataService({
      dataServiceId: "redstone-rapid-demo",
      uniqueSignersCount: 1,
      dataFeeds: ["VST"],
    }, ["https://d33trozg86ya9x.cloudfront.net"]);

    // Interact with the contract (getting oracle value securely)
    const ethPriceFromContract = await wrappedContract.getLatestPrice(ethers.constants.AddressZero);
    console.log({ ethPriceFromContract });
  });
});


**************************************/
