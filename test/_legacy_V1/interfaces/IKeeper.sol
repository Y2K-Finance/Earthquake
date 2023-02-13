// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract KeeperGelato {
    function startTask(uint256 _marketIndex, uint256 _epochID) external {}

    function checker(uint256 _marketIndex, uint256 _epochID)
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {}

    function deposit(uint256 _amount) external payable {}

    function withdraw(uint256 _amount) external {}
}
