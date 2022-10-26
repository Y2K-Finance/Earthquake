// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import {
    SafeERC20,
    IERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IOps {
    function gelato() external view returns (address payable);
    function createTask(
        address _execAddress,
        bytes4 _execSelector,
        address _resolverAddress,
        bytes calldata _resolverData
    ) external returns (bytes32 task);

    function cancelTask(bytes32 _taskId) external;
}

interface ITaskTreasury {
    function depositFunds(
        address _receiver,
        address _token,
        uint256 _amount
    ) external payable;

    function withdrawFunds(
        address payable _receiver,
        address _token,
        uint256 _amount
    ) external;
}

abstract contract OpsReady {
    address public immutable ops;
    address public immutable treasuryTask;
    address payable public immutable gelato;
    address public constant ETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

    modifier onlyOps() {
        require(msg.sender == ops, "OpsReady: onlyOps");
        _;
    }

    constructor(address _ops, address _treasuryTask) {
        ops = _ops;
        treasuryTask = _treasuryTask;
        gelato = IOps(_ops).gelato();
    }

    function depositFunds(
        address _token,
        uint256 _amount) external payable {
        ITaskTreasury(ops).depositFunds{value: msg.value}(address(this), _token, _amount);
    }

    function _withdrawFunds(
        address payable _receiver,
        address _token,
        uint256 _amount
    ) internal {
        ITaskTreasury(ops).withdrawFunds(_receiver, _token, _amount);
    }
}