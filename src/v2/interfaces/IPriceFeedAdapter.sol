// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IPriceFeedAdapter {
    function getValueForDataFeed(
        bytes32 dataFeedId
    ) external view returns (uint256);
}
