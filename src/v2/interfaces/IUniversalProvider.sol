// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {
    AggregatorV3Interface
} from "@chainlink/interfaces/AggregatorV3Interface.sol";

interface IUniversalProvider {
    function setConditionType(uint256 _marketId, uint256 _condition) external;

    function getLatestPrice(uint256 _marketId) external view returns (int256);

    function decimals(uint256 marketId) external view returns (uint256);

    function description(
        uint256 marketId
    ) external view returns (string memory);

    function conditionMet(
        uint256 _value,
        uint256 _marketId
    ) external view returns (bool, int256 price);

    function latestRoundData(
        uint256 marketId
    ) external view returns (uint80, int256, uint256, uint256, uint80);

    function marketIdToConditionType(
        uint256 _marketId
    ) external view returns (uint256);
}
