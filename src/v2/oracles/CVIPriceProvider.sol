// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IVaultFactoryV2} from "../interfaces/IVaultFactoryV2.sol";
import {IConditionProvider} from "../interfaces/IConditionProvider.sol";
import {ICVIPriceFeed} from "../interfaces/ICVIPriceFeed.sol";

contract CVIPriceProvider is IConditionProvider {
    uint256 public immutable timeOut;
    ICVIPriceFeed public priceFeedAdapter;

    constructor(address _priceFeed, uint256 _timeOut) {
        if (_priceFeed == address(0)) revert ZeroAddress();
        if (_timeOut == 0) revert InvalidInput();
        priceFeedAdapter = ICVIPriceFeed(_priceFeed);
        timeOut = _timeOut;
    }

    /** @notice Fetch token price from priceFeedAdapter (Redston oracle address)
     * @return int256 Current token price
     */
    function getLatestPrice() public view virtual returns (int256) {
        (uint256 price, , uint256 updatedAt) = priceFeedAdapter
            .getCVILatestRoundData();
        if (price == 0) revert OraclePriceZero();

        // TODO: What is a suitable timeframe to set timeout as based on this info? Update at always timestamp?
        if ((block.timestamp - updatedAt) > timeOut) revert PriceTimedOut();

        return int256(price);
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
        return (int256(_strike) < price, price);
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
