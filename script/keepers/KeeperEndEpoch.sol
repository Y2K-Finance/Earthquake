// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import { OpsReady, IOps } from "./OpsReady.sol";
import {IController} from "../../src/interfaces/IController.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract KeeperGelatoEndEpoch is OpsReady, Ownable {
    address public immutable controller;
    mapping(bytes32 => bytes32) public tasks;

    constructor(address payable _ops, address payable _treasuryTask,address _controller) OpsReady(_ops, _treasuryTask) {
        controller = _controller;
    }
    
    function startTask(uint256 _marketIndex, uint256 _epochID) external {
        bytes32 taskId = IOps(ops).createTask(
            address(this), 
            this.execute.selector,
            address(this),
            abi.encodeWithSelector(this.checker.selector, _marketIndex, _epochID)
        );
        bytes32 payloadKey  = keccak256(abi.encodePacked(_marketIndex, _epochID));
        tasks[payloadKey] = taskId;
    }
    
    function execute(uint256 _marketIndex, uint256 _epochID) external onlyOps {

        bytes32 taskId = tasks[keccak256(abi.encodePacked(_marketIndex, _epochID))];        
        IController(controller).triggerEndEpoch(_marketIndex, _epochID);

        //cancel task
        IOps(ops).cancelTask(taskId);
    }
    
    function checker(uint256 _marketIndex, uint256 _epochID)
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        canExec = _epochID <= block.timestamp;

        execPayload = abi.encodeWithSelector(
        this.execute.selector,
        _marketIndex, _epochID
        );
    }

    function deposit(uint256 _amount) external payable {
        treasury.depositFunds{value: _amount}(address(this), ETH, _amount);
    }

    function withdraw(uint256 _amount) external onlyOwner{
        treasury.withdrawFunds(payable(msg.sender), ETH, _amount);
    }
}