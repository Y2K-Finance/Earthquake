// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IConditionProvider {
    function setConditionType(uint256 _marketId, uint256 _condition) external;

    function getLatestPrice() external view returns (int256);

    function conditionMet(
        uint256 _value,
        uint256 _marketId
    ) external view returns (bool, int256 price);

    function latestRoundData()
        external
        view
        returns (uint80, int256, uint256, uint256, uint80);

    function marketIdToConditionType(
        uint256 _marketId
    ) external view returns (uint256);
}
