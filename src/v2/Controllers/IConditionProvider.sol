// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IConditionProvider {
    function getLatestPrice(uint256 _marketId) external view returns (int256);

    function conditionMet(
        uint256 _value,
        uint256 _marketId
    ) external view returns (bool);
}
