/******************************************************* 
NOTE: Development in progress by JG. Reached functional milestone; Live VST data is accessible. 
***/
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IConditionProvider} from "../../interfaces/IConditionProvider.sol";
import {IDIAPriceFeed} from "../../interfaces/IDIAPriceFeed.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract DIAPriceProvider is Ownable, IConditionProvider {
    IDIAPriceFeed public diaPriceFeed;
    uint256 public immutable decimals;
    string public constant description = "BTC/USD";

    event MarketConditionSet(uint256 indexed marketId, uint256 conditionType);

    constructor(address _priceFeed, uint256 _decimals) {
        if (_priceFeed == address(0)) revert ZeroAddress();
        diaPriceFeed = IDIAPriceFeed(_priceFeed);
        decimals = _decimals;
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
        (price, updatedAt) = _getLatestPrice();
        startedAt = 1;
        roundId = 1;
        answeredInRound = 1;
    }

    /** @notice Fetch token price from priceFeedAdapter (Using string name)
     * @return price Current token price
     */
    function getLatestPrice() public view override returns (int256 price) {
        (price, ) = _getLatestPrice();
    }

    /** @notice Fetch price and return condition
     * @dev The strike is hashed as an int256 to enable comparison vs. price for earthquake
        and conditional check vs. strike to ensure vaidity
     * @param _strike Strike price
     * @return condition boolean If condition is met i.e. strike > price
     * @return price current price for token
     */
    function conditionMet(
        uint256 _strike,
        uint256 /* _marketId */
    ) public view virtual returns (bool condition, int256 price) {
        uint256 conditionType = _strike % 2 ** 1;

        assembly {
            // conditionType := and(
            //     0x00000000000000000000000000000000000000000000000000000000000000f,
            //     _strike
            // )
            _strike := and(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0,
                _strike
            )
        }

        (price, ) = _getLatestPrice();
        if (conditionType == 1) return (int256(_strike) < price, price);
        else if (conditionType == 0) return (int256(_strike) > price, price);
        else revert ConditionTypeNotSet();
    }

    /*//////////////////////////////////////////////////////////////
                                 INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _getLatestPrice()
        private
        view
        returns (int256 price, uint256 timestamp)
    {
        uint256 uintPrice;
        (uintPrice, timestamp) = diaPriceFeed.getValue(description);
        price = int256(uintPrice);

        if (decimals < 18) {
            uint256 calcDecimals = 10 ** (18 - (decimals));
            price = price * int256(calcDecimals);
        } else if (decimals > 18) {
            uint256 calcDecimals = 10 ** ((decimals - 18));
            price = price / int256(calcDecimals);
        }
    }

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error ZeroAddress();
    error InvalidInput();
    error ConditionTypeNotSet();
    error ConditionTypeSet();
}
