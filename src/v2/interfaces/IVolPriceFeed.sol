// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IVolPriceFeed {
    function getPrice() external view returns (int256);
}
