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

contract RedstonePriceProvider is RapidDemoConsumerBase,IPriceProvider {
    uint16 private constant GRACE_PERIOD_TIME = 3600;
    IVaultFactoryV2 public immutable vaultFactory;
    AggregatorV2V3Interface internal sequencerUptimeFeed;
 
    constructor(address _sequencer, address _factory) {
        if (_factory == address(0)) revert ZeroAddress();
        vaultFactory = IVaultFactoryV2(_factory);
        
        if (_sequencer == address(0)) revert ZeroAddress();
        sequencerUptimeFeed = AggregatorV2V3Interface(_sequencer);

    }
    
    function getLatestRawPrice(address _token) public virtual view returns (int256) {    
       uint256 priceIn = getOracleNumericValueFromTxMsg(bytes32("VST")); 
       int256 price = int256(priceIn); // TODO Check this for errors
       return price;
    }
    
    function getLatestRawDecimals(address _token) public  virtual view returns (uint256) {
       return 18;
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
        
        int256 price = getLatestRawPrice(_token); 
        uint256 decimals = getLatestRawDecimals(_token);
        
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