// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@chainlink/interfaces/AggregatorV3Interface.sol";
import "@chainlink/interfaces/AggregatorV2V3Interface.sol";
import "./IRedstoneCore.sol";
//import "@redstone-finance/evm-connector/contracts/data-services/RapidDemoConsumerBase.sol";

import {IVaultFactoryV2} from "../interfaces/IVaultFactoryV2.sol";
import {IVaultV2} from "../interfaces/IVaultV2.sol";
import "./IPriceProvider.sol";
import {vstOracle} from "../../oracles/vstOracle.sol";

contract RedstonePriceProvider is IPriceProvider {
    uint16 private constant GRACE_PERIOD_TIME = 3600;
    IVaultFactoryV2 public immutable vaultFactory;
    AggregatorV2V3Interface internal sequencerUptimeFeed;
    bytes32 symbol;
    int256 latestPrice;
    vstOracle redstoneOracle;
    uint256 marketId;
    
    constructor(address _sequencer, address _factory, string memory _symbol, address _redstoneOracle) {
        if (_factory == address(0)) revert ZeroAddress();
        redstoneOracle = vstOracle(_redstoneOracle);
        
        //if (_factory == address(0)) revert ZeroAddress();
        vaultFactory = IVaultFactoryV2(_factory);
        
        //if (_sequencer == address(0)) revert ZeroAddress();
        sequencerUptimeFeed = AggregatorV2V3Interface(_sequencer);
        symbol = stringToBytes32(_symbol);
    }
    
    function stringToBytes32(string memory _symbol) public pure returns (bytes32 result) {
        require(bytes(_symbol).length <= 32, "String too long for bytes32 conversion");
        assembly {
            result := mload(add(_symbol, 32))
        }
    }    
    
    function setMarket(uint256 _marketId) public {
        marketId = _marketId;
    }    
    
    /**
     * @notice Get the oracle numeric value from the transaction message
     * @param dataFeedId The identifier of the data feed to retrieve the value from
     * @return The numeric value from the oracle
     */    
    function extGetOracleNumericValueFromTxMsg(bytes32 dataFeedId)
        public
        view
        returns (uint256)
    {
        return redstoneOracle.getValue();
    }

    
    function getLatestRawPrice() public virtual view returns (int256) {    
       // TODO consider implementing token based symbol lookup
       uint256 priceIn = extGetOracleNumericValueFromTxMsg(symbol); 
       int256 price = int256(priceIn); 
       return price;
    }
    
    function getLatestRawDecimals() public  virtual view returns (uint256) {
       return 18;
    }
    
    
    /** @notice Lookup token price
     * @return nowPrice Current token price
     */
    function validateLatestPrice() public view returns (int256) {
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
        
        int256 price = getLatestRawPrice(); 
        uint256 decimals = getLatestRawDecimals();
        
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
        return price;
    }


    /** @notice Lookup token price
     * @return nowPrice Current token price
     */
    function storeLatestPrice() public returns (int256) {
      latestPrice = validateLatestPrice();
      return latestPrice;
    }
    
    /** @notice Lookup token price
     * @return nowPrice Current token price
     */
    function getLatestPrice() public view returns (int256) {
      return latestPrice;
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
    error SignerNotAuthorised(address signerAddress);

}

