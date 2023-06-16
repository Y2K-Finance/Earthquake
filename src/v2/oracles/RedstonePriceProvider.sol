// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IVaultFactoryV2} from "../interfaces/IVaultFactoryV2.sol";
import {IConditionProvider} from "../interfaces/IConditionProvider.sol";
import {IPriceFeedAdapter} from "../interfaces/IPriceFeedAdapter.sol";

contract RedstonePriceProvider is IConditionProvider {
    uint256 public immutable timeOut;
    IVaultFactoryV2 public immutable vaultFactory;
    IPriceFeedAdapter public priceFeedAdapter;
    bytes32 public immutable dataFeedId;
    string public symbol;

    constructor(
        address _factory,
        address _priceFeed,
        string memory _dataFeedSymbol,
        uint256 _timeOut
    ) {
        if (_factory == address(0)) revert ZeroAddress();
        if (_priceFeed == address(0)) revert ZeroAddress();
        if (keccak256(bytes(_dataFeedSymbol)) == keccak256(bytes(string(""))))
            revert InvalidInput();
        if (_timeOut == 0) revert InvalidInput();
        vaultFactory = IVaultFactoryV2(_factory);
        priceFeedAdapter = IPriceFeedAdapter(_priceFeed);
        symbol = _dataFeedSymbol;
        dataFeedId = stringToBytes32(_dataFeedSymbol);
        timeOut = _timeOut;
    }

    /** @notice Fetch token price from priceFeedAdapter (Redston oracle address)
     * @return int256 Current token price
     */
    function getLatestPrice() public view virtual returns (int256) {
        (
            uint80 roundId,
            int256 price,
            ,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = priceFeedAdapter.latestRoundData();
        if (price <= 0) revert OraclePriceZero();
        if (answeredInRound < roundId) revert RoundIdOutdated();
        // TODO: What is a suitable timeframe to set timeout as based on this info? Update at always timestamp?
        if ((block.timestamp - updatedAt) > timeOut) revert PriceTimedOut();

        return price;
    }

    // NOTE: _marketId unused but receiving marketId makes Generic controller composabile for future
    /** @notice Fetch price and return condition
     * @param _strike Strike price
     * @return boolean If condition is met i.e. strike > price
     * @return price Current price for token
     */
    function conditionMet(
        uint256 _strike
    ) public view virtual returns (bool, int256 price) {
        price = getLatestPrice();
        return (int256(_strike) > price, price);
    }

    /** @notice Convert string to bytes32
     * @param _symbol Symbol for token
     * @return result Bytes32 representation of string
     */
    function stringToBytes32(
        string memory _symbol
    ) public pure returns (bytes32 result) {
        if (bytes(_symbol).length > 32) revert InvalidInput();
        assembly {
            result := mload(add(_symbol, 32))
        }
    }

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error ZeroAddress();
    error InvalidInput();
    error OraclePriceZero();
    error RoundIdOutdated();
    error PriceTimedOut();
}
