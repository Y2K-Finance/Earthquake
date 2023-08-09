// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IConditionProvider} from "../../interfaces/IConditionProvider.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {IPyth} from "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import {PythStructs} from "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";

contract PythPriceProvider is Ownable, IConditionProvider {
    using SafeCast for int256;

    IPyth public immutable pyth;

    uint256 public immutable timeOut;
    bytes32 public immutable priceFeedId;

    mapping(uint256 => uint256) public marketIdToConditionType;

    event MarketConditionSet(uint256 indexed marketId, uint256 conditionType);

    constructor(
        address _pythContract,
        bytes32 _priceFeedId,
        uint256 _timeOut
    ) {
        if (_pythContract == address(0)) revert ZeroAddress();
        if (_priceFeedId == bytes32(0))
            revert InvalidInput();
        if (_timeOut == 0) revert InvalidInput();
        pyth = IPyth(_pythContract);
        priceFeedId = _priceFeedId;
        timeOut = _timeOut;
    }

    /*//////////////////////////////////////////////////////////////
                                 ADMIN
    //////////////////////////////////////////////////////////////*/
    function setConditionType(
        uint256 _marketId,
        uint256 _condition
    ) external onlyOwner {
        if (marketIdToConditionType[_marketId] != 0) revert ConditionTypeSet();
        if (_condition != 1 && _condition != 2) revert InvalidInput();
        marketIdToConditionType[_marketId] = _condition;
        emit MarketConditionSet(_marketId, _condition);
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
        PythStructs.Price memory answer = pyth.getPrice(priceFeedId);
        updatedAt = answer.publishTime;
        price = (int256(answer.price));
    }

    /** @notice Fetch token price from priceFeedAdapter (Redston oracle address)
     * @return int256 Current token price
     */
    function getLatestPrice() public view virtual returns (int256) {
        PythStructs.Price memory answer = pyth.getPrice(priceFeedId);
        if (answer.price <= 0) revert OraclePriceNegative();
        // TODO: What is a suitable timeframe to set timeout as based on this info? Update at always timestamp?
        if ((block.timestamp - answer.publishTime) > timeOut) revert PriceTimedOut();

        int256 price = answer.price;
        if (answer.expo < 18) {
            uint256 calcDecimals = 10 ** (int256(18 - answer.expo).toUint256());
            price = price * int256(calcDecimals);
        } else if (answer.expo > 18) {
            uint256 calcDecimals = 10 ** (int256(answer.expo - 18).toUint256());
            price = price / int256(calcDecimals);
        }

        return price;
    }

    // NOTE: _marketId unused but receiving marketId makes Generic controller composabile for future
    /** @notice Fetch price and return condition
     * @param _strike Strike price
     * @return boolean If condition is met i.e. strike > price
     * @return price Current price for token
     */
    function conditionMet(
        uint256 _strike,
        uint256 _marketId
    ) public view virtual returns (bool, int256 price) {
        uint256 conditionType = marketIdToConditionType[_marketId];
        price = getLatestPrice();

        if (conditionType == 1) return (int256(_strike) < price, price);
        else if (conditionType == 2) return (int256(_strike) > price, price);
        else revert ConditionTypeNotSet();
    }

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error ZeroAddress();
    error InvalidInput();
    error OraclePriceNegative();
    error PriceTimedOut();
    error ConditionTypeNotSet();
    error ConditionTypeSet();
}
