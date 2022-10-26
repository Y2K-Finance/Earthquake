// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import { OpsReady, IOps } from "./OpsReady.sol";
import {IController} from "../../src/interfaces/IController.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract KeeperGelato is OpsReady, Ownable {
    address public immutable controller;
    mapping(bytes32 => bytes32) public tasks;

    constructor(address payable _ops, address payable _treasuryTask,address _controller) OpsReady(_ops, _treasuryTask) {
        controller = _controller;
    }
    
    function startTask(uint256 _marketIndex, uint256 _epochID) external {
        bytes32 taskId = IOps(ops).createTask(
            address(this), 
            this.executePayload.selector,
            address(this),
            abi.encodeWithSelector(this.checker.selector, _marketIndex, _epochID)
        );
        bytes32 payloadKey  = keccak256(abi.encodePacked(_marketIndex, _epochID));
        tasks[payloadKey] = taskId;
    }
    
    function executePayload(bytes memory _payloadData) external onlyOps {
        (bytes memory callData, bytes32 taskId) = abi.decode(_payloadData, (bytes, bytes32));
        
        //execute task
        (bool success, ) = controller.call(callData);
        require(success, "executePayload: call failed");

        //cancel task
        IOps(ops).cancelTask(taskId);
    }
    
    function checker(uint256 _marketIndex, uint256 _epochID)
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        //check if task can be executed
        (bool canExecDepeg,) = controller.staticcall(
            abi.encodeWithSelector(bytes4(keccak256("triggerDepeg(uint256,uint256)")), 
            _marketIndex, _epochID));

        (bool canExecEnd,) = controller.staticcall(
            abi.encodeWithSelector(bytes4(keccak256("triggerEndEpoch(uint256,uint256)")), 
            _marketIndex, _epochID));

        //execute task payload
        if(canExecDepeg) {
            execPayload = abi.encodeWithSelector(bytes4(keccak256("triggerDepeg(uint256,uint256)")), 
            _marketIndex, _epochID);

            execPayload = abi.encode(execPayload, tasks[keccak256(abi.encodePacked(_marketIndex, _epochID))]);
        }

        if(canExecEnd){
            execPayload = abi.encodeWithSelector(
            bytes4(keccak256("triggerEndEpoch(uint256,uint256)")),
            _marketIndex, _epochID
            );
            execPayload = abi.encode(execPayload, tasks[keccak256(abi.encodePacked(_marketIndex, _epochID))]);
        }
        
        canExec = canExecDepeg || canExecEnd;
        
    }

    function deposit(uint256 _amount) external payable {
        treasury.depositFunds{value: _amount}(address(this), ETH, _amount);
    }

    function withdraw(uint256 _amount) external onlyOwner{
        treasury.withdrawFunds(payable(msg.sender), ETH, _amount);
    }
}