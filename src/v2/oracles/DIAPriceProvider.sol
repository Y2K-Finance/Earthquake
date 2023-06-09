/******************************************************* 
NOTE: Development in progress by JG. Reached functional milestone; Live VST data is accessible. 
***/
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IConditionProvider} from "../interfaces/IConditionProvider.sol";
import {IDIAPriceFeed} from "../interfaces/IDIAPriceFeed.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract DIAPriceProvider is IConditionProvider, Ownable {
    string public constant PAIR_NAME = "BTC/USD";
    IDIAPriceFeed public diaPriceFeed;

    constructor(address _priceFeed) {
        if (_priceFeed == address(0)) revert ZeroAddress();
        diaPriceFeed = IDIAPriceFeed(_priceFeed);
    }

    /** @notice Fetch token price from priceFeedAdapter (Redston oracle address)
     * @return int256 Current token price
     */
    function getLatestPrice() public view override returns (int256) {
        (uint128 price, ) = diaPriceFeed.getValue(PAIR_NAME);
        return int128(price);
    }

    /** @notice Fetch price and return condition
     * @dev The strike is hashed as an int256 to enable comparison vs. price for earthquake
        and conditional check vs. strike to ensure vaidity
     * @param _strike Strike price
     * @return condition boolean If condition is met i.e. strike > price
     * @return price Current price for token
     */
    // TODO: Seems counterintuitive to convert price, return it, and convert it back
    function conditionMet(
        uint256 _strike
    ) public view virtual returns (bool condition, int256 price) {
        price = getLatestPrice();
        return (_strike > uint256(price), price);
    }

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error ZeroAddress();
}
