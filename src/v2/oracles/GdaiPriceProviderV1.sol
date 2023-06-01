/******************************************************* 
NOTE: Development in progress by JG. Reached functional milestone; Live VST data is accessible. 
***/
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IConditionProviderInt} from "../interfaces/IConditionProviderInt.sol";
import {IGdaiPriceFeed} from "../interfaces/IGdaiPriceFeed.sol";

contract GdaiPriceProviderV1 is IConditionProviderInt {
    IGdaiPriceFeed public gdaiPriceFeed;

    constructor(address _priceFeed) {
        if (_priceFeed == address(0)) revert ZeroAddress();
        gdaiPriceFeed = IGdaiPriceFeed(_priceFeed);
    }

    /** @notice Fetch token price from priceFeedAdapter (Redston oracle address)
     * @return int256 Current token price
     */
    function getLatestPrice() public view virtual returns (int256) {
        return gdaiPriceFeed.accPnlPerToken();
    }

    // NOTE: _marketId unused but receiving marketId makes Generic controller composabile for future
    /** @notice Fetch price and return condition
     * @param _strike Strike price
     * @return boolean If condition is met i.e. strike > price
     * @return price Current price for token
     */
    function conditionMet(
        int256 _strike
    ) public view virtual returns (bool, int256 price) {
        price = getLatestPrice();
        return (_strike < price, price);
    }

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error ZeroAddress();
}
