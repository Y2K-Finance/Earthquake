// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@chainlink/interfaces/AggregatorV3Interface.sol";
import "@chainlink/interfaces/AggregatorV2V3Interface.sol";
import {IVaultFactoryV2} from "../interfaces/IVaultFactoryV2.sol";
import {IVaultV2} from "../interfaces/IVaultV2.sol";

import "./IPriceProvider.sol";

contract ChainlinkPriceProvider is IPriceProvider {
    //AggregatorV3Interface internal priceFeed;
    uint16 private constant GRACE_PERIOD_TIME = 3600;
    
    IVaultFactoryV2 public immutable vaultFactory;
    AggregatorV2V3Interface internal sequencerUptimeFeed;

    constructor(address _sequencer,address _factory) {
        if (_factory == address(0)) revert ZeroAddress();
        vaultFactory = IVaultFactoryV2(_factory);
    
        if (_sequencer == address(0)) revert ZeroAddress();
        sequencerUptimeFeed = AggregatorV2V3Interface(_sequencer);
        

    }

    /** @notice Lookup token price
     * @param _token Target token address
     * @return nowPrice Current token price
     */
    function getLatestPrice(address _token) public view returns (int256) {
        (
            ,
            /*uint80 roundId*/
            int256 answer,
            uint256 startedAt, /*uint256 updatedAt*/ /*uint80 answeredInRound*/
            ,

        ) = sequencerUptimeFeed.latestRoundData();

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

        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            vaultFactory.tokenToOracle(_token)
        );
        (uint80 roundID, int256 price, , , uint80 answeredInRound) = priceFeed
            .latestRoundData();
        uint256 decimals = priceFeed.decimals();

        if (decimals < 18) {
            decimals = 10**(18 - (decimals));
            price = price * int256(decimals);
        } else if (decimals == 18) {
            price = price;
        } else {
            decimals = 10**((decimals - 18));
            price = price / int256(decimals);
        }

        if (price <= 0) revert OraclePriceZero();

        if (answeredInRound < roundID) revert RoundIDOutdated();

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

