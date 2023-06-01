// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IGdaiPriceFeed {
    function accPnlPerToken() external view returns (int256);

    function accPnlPerTokenUsed() external view returns (int256);

    function shareToAssetsPrice() external view returns (uint256);
}
