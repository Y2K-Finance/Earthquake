// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IConditionProvider {
    function getLatestPrice() external view returns (int256);

    function conditionMet(
        uint256 _value,
        uint256 _marketId
    ) external view returns (bool, int256 price);

    function latestRoundData()
        external
        view
        returns (uint80, int256, uint256, uint256, uint80);
}
