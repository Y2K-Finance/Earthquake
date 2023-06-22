// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ICVIPriceFeed {
    function getCVILatestRoundData()
        external
        view
        returns (uint32 cviValue, uint80 cviRoundId, uint256 cviTimestamp);
}
