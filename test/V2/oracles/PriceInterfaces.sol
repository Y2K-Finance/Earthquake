// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IChainlink {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);
}

interface IChainlinkUniversal {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);
}

interface IPriceFeedAdapter {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function symbol() external view returns (string memory);

    function getDataFeedId() external view returns (bytes32);
}
