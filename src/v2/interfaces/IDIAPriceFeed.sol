// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IDIAPriceFeed {
    function getValue(
        string memory key
    ) external view returns (uint128, uint128);
}
