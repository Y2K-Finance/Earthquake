/******************************************************* 
NOTE: Development in progress by JG. Reached functional milestone; Live VST data is accessible. 
***/
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IVaultFactoryV2} from "../interfaces/IVaultFactoryV2.sol";
import {IVaultV2} from "../interfaces/IVaultV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

import "./IPriceProvider.sol";


pragma solidity ^0.8.4;

import "@redstone-finance/evm-connector/contracts/data-services/RapidDemoConsumerBase.sol";

contract RedstonePriceProvider is RapidDemoConsumerBase {
    uint16 private constant GRACE_PERIOD_TIME = 3600;
    IVaultFactoryV2 public immutable vaultFactory;
    AggregatorV2V3Interface internal sequencerUptimeFeed;
 
    constructor(address _sequencer, address _factory) {
        // TODO enable after testing
        //if (_factory == address(0)) revert ZeroAddress();
        vaultFactory = IVaultFactoryV2(_factory);
        
        //if (_sequencer == address(0)) revert ZeroAddress();
        sequencerUptimeFeed = AggregatorV2V3Interface(_sequencer);

    }

    /** @notice Lookup token price
     * @param _token Target token address
     * @return nowPrice Current token price
     */
    function getLatestPrice(address _token) public view returns (int256) {
        if (address(sequencerUptimeFeed) != address(0))
        {
            (, int256 answer, uint256 startedAt, , ) = sequencerUptimeFeed.latestRoundData();

            // Answer == 0: Sequencer is up
            // Answer == 1: Sequencer is down
            bool isSequencerUp = answer == 0;
            if (!isSequencerUp) {
                revert SequencerDown();
            }

            // Make sure the grace period has passed after the sequencer is back up.
            uint256 timeSinceUp = block.timestamp - startedAt;
            if (timeSinceUp <= GRACE_PERIOD_TIME) {
                revert GracePeriodNotOver();
            }
        
        }
        
        uint256 priceIn = getOracleNumericValueFromTxMsg(bytes32("VST")); 
        int256 price = int256(priceIn); 
        uint256 decimals = 18;
        if (decimals < 18) {
            decimals = 10**(18 - decimals);
            price = price * int256(decimals);
        } else if (decimals == 18) {
            price = price;
        } else {
            decimals = 10**(decimals - 18);
            price = price / int256(decimals);
        }

        if (price <= 0) revert OraclePriceZero();

        //(uint80 roundID, int256 price, , , uint80 answeredInRound) = 
        //if (answeredInRound < roundID) revert RoundIDOutdated();

        return price;
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
