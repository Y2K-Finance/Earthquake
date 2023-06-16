/******************************************************* 
NOTE: Development in progress by JG. Reached functional milestone; Live VST data is accessible. 
***/
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IConditionProvider} from "../interfaces/IConditionProvider.sol";
import {IGdaiPriceFeed} from "../interfaces/IGdaiPriceFeed.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract GdaiPriceProvider is IConditionProvider, Ownable {
    IGdaiPriceFeed public gdaiPriceFeed;
    bytes public strikeHash;

    event StrikeUpdated(bytes strikeHash, int256 strikePrice);

    constructor(address _priceFeed) {
        if (_priceFeed == address(0)) revert ZeroAddress();
        gdaiPriceFeed = IGdaiPriceFeed(_priceFeed);
    }

    function updateStrikeHash(int256 strikePrice) external onlyOwner {
        bytes memory _strikeHash = abi.encode(strikePrice);
        strikeHash = _strikeHash;
        emit StrikeUpdated(_strikeHash, strikePrice);
    }

    /** @notice Fetch token price from priceFeedAdapter (Redston oracle address)
     * @return int256 Current token price
     */
    function getLatestPrice() public view virtual returns (int256) {
        return gdaiPriceFeed.accPnlPerToken();
    }

    /** @notice Fetch price and return condition
     * @dev The strike is hashed as an int256 to enable comparison vs. price for earthquake
        and conditional check vs. strike to ensure vaidity
     * @param _strike Strike price
     * @return condition boolean If condition is met i.e. strike > price
     * @return price Current price for token
     */
    function conditionMet(
        uint256 _strike
    ) public view virtual returns (bool condition, int256 price) {
        uint256 strikeUint;
        int256 strikeInt = abi.decode(strikeHash, (int256));

        if (strikeInt < 0) strikeUint = uint256(-strikeInt);
        else strikeUint = uint256(strikeInt);

        if (_strike != strikeUint) revert InvalidStrike();

        price = getLatestPrice();

        return (strikeInt > price, price);
    }

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error ZeroAddress();
    error InvalidStrike();
    error InvalidInput();
}
