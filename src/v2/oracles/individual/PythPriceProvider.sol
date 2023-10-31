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
    uint256 public immutable decimals;
    uint256 public immutable timeOut;
    bytes32 public immutable priceFeedId;

    event MarketConditionSet(uint256 indexed marketId, uint256 conditionType);

    error ExponentTooSmall(int256 expo);

    constructor(address _pythContract, bytes32 _priceFeedId, uint256 _timeOut) {
        if (_pythContract == address(0)) revert ZeroAddress();
        if (_priceFeedId == bytes32(0)) revert InvalidInput();
        if (_timeOut == 0) revert InvalidInput();
        pyth = IPyth(_pythContract);
        priceFeedId = _priceFeedId;
        timeOut = _timeOut;
        PythStructs.Price memory answer = pyth.getPriceUnsafe(priceFeedId);
        decimals = (int256(-answer.expo)).toUint256();
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
        PythStructs.Price memory answer = pyth.getPriceUnsafe(priceFeedId);
        updatedAt = answer.publishTime;
        price = (int256(answer.price));
    }

    /** @notice Fetch token price from priceFeedAdapter (Redston oracle address)
     * @return int256 Current token price
     */
    function getLatestPrice() public view virtual returns (int256) {
        PythStructs.Price memory answer = pyth.getPriceNoOlderThan(
            priceFeedId,
            timeOut
        );
        if (answer.price <= 0) revert OraclePriceNegative();

        int256 price = answer.price;
        int256 calcDecimals = answer.expo + 18;
        if (calcDecimals < 0) {
            revert ExponentTooSmall(answer.expo);
        }
        price = price * int256(10 ** (calcDecimals.toUint256()));
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
        uint256 /* _marketId */
    ) public view virtual returns (bool, int256 price) {
        uint256 conditionType = _strike % 2 ** 1;
        if (conditionType == 1) _strike -= 1;

        price = getLatestPrice();
        if (conditionType == 1) return (int256(_strike) < price, price);
        else if (conditionType == 0) return (int256(_strike) > price, price);
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
