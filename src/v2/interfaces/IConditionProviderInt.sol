// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IConditionProviderInt {
    function getLatestPrice() external view returns (int256);

    function conditionMet(
        int256 _value
    ) external view returns (bool, int256 price);
}
