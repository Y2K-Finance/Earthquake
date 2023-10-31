// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IConditionProvider} from "../../interfaces/IConditionProvider.sol";
import {IGdaiPriceFeed} from "../../interfaces/IGdaiPriceFeed.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract GdaiPriceProvider is IConditionProvider, Ownable {
    IGdaiPriceFeed public immutable gdaiPriceFeed;
    uint256 public immutable decimals;
    string public description;

    event MarketConditionSet(uint256 indexed marketId, uint256 conditionType);

    constructor(address _priceFeed) {
        if (_priceFeed == address(0)) revert ZeroAddress();
        gdaiPriceFeed = IGdaiPriceFeed(_priceFeed);
        decimals = gdaiPriceFeed.decimals();
        description = "gTrade pnl";
    }

    /*//////////////////////////////////////////////////////////////
                                 PUBLIC
    //////////////////////////////////////////////////////////////*/
    function latestRoundData()
        public
        view
        returns (
            uint80 roundId,
            int256 price,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        roundId = 1;
        price = gdaiPriceFeed.accPnlPerToken();
        startedAt = 1;
        updatedAt = block.timestamp;
        answeredInRound = 1;
    }

    /** @notice Fetch token price from priceFeedAdapter (Redston oracle address)
     * @return price Current token price
     */
    function getLatestPrice() public view virtual returns (int256 price) {
        price = gdaiPriceFeed.accPnlPerToken();

        if (decimals < 18) {
            uint256 calcDecimals = 10 ** (18 - (decimals));
            price = price * int256(calcDecimals);
        } else if (decimals > 18) {
            uint256 calcDecimals = 10 ** ((decimals - 18));
            price = price / int256(calcDecimals);
        }
    }

    /** @notice Fetch price and return condition
     * @dev The strike is hashed as an int256 to enable comparison vs. price for earthquake
        and conditional check vs. strike to ensure vaidity
     * @param _strike Strike price
     * @return condition boolean If condition is met i.e. strike > price
     * @return price Current price for token
     */
    function conditionMet(
        uint256 _strike,
        uint256 /* _marketId */
    ) public view virtual returns (bool condition, int256 price) {
        int256 strikeInt = int256(_strike);
        uint256 conditionType = _strike % 2 ** 1;

        price = getLatestPrice();
        if (conditionType == 1) return (strikeInt < price, price);
        else if (conditionType == 0) return (strikeInt > price, price);
        else revert ConditionTypeNotSet();
    }

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error ZeroAddress();
    error InvalidInput();
    error ConditionTypeNotSet();
    error ConditionTypeSet();
}
