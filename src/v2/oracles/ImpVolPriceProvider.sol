/******************************************************* 
NOTE: Development in progress by JG. Reached functional milestone; Live VST data is accessible. 
***/
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IConditionProvider} from "../interfaces/IConditionProvider.sol";
import {IVolPriceFeed} from "../interfaces/IVolPriceFeed.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ImpVolPriceProvider is IConditionProvider, Ownable {
    uint256 public constant BUFFER_TIME = 4 days;
    IVolPriceFeed public volPriceFeed;
    uint256 public expirationTime;

    // TODO: Additional market variables required to fetch price?

    constructor(address _priceFeed) {
        if (_priceFeed == address(0)) revert ZeroAddress();
        volPriceFeed = IVolPriceFeed(_priceFeed);
    }

    function updateExpiry(uint256 timestamp) external onlyOwner {
        if (block.timestamp > timestamp + BUFFER_TIME) revert InvalidInput();
        expirationTime = timestamp;
    }

    /** @notice Fetch token price from priceFeedAdapter (Redston oracle address)
     * @return int256 Current token price
     */
    // TODO: Change this to correct price feed fetching logic
    // TODO: Need to calc weighted average for the feeds - getAnnualizedVolatlity64x64
    function getLatestPrice() public view override returns (int256) {
        if (block.timestamp > expirationTime) revert ExpiredMarket();
        int256 impliedVolSum;
        for (uint256 i = 0; i < 10; ) {
            impliedVolSum = impliedVolSum + volPriceFeed.getPrice();
            unchecked {
                i++;
            }
        }
        // TODO: Calc weighted average on the impliedVolSum
        // TODO: How does the weighting work on the VIX?
        return impliedVolSum;
    }

    /** @notice Fetch price and return condition
     * @dev The strike is hashed as an int256 to enable comparison vs. price for earthquake
        and conditional check vs. strike to ensure vaidity
     * @param _strike Strike price
     * @return condition boolean If condition is met i.e. strike > price
     * @return price Current price for token
     */
    // TODO: Seems counterintuitive to conver price, return it, and convert it back
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
    error ExpiredMarket();
    error InvalidInput();
}
