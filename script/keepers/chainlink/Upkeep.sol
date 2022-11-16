// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// AutomationCompatible.sol imports the functions from both ./AutomationBase.sol and
// ./interfaces/AutomationCompatibleInterface.sol
import "@chainlink/AutomationCompatible.sol";
import {IController} from "../../../src/interfaces/IController.sol";


contract UpkeepController is AutomationCompatibleInterface {
    IController controller;
    address public owner;
    uint256 public marketIndex;
    uint256 public epochBegin;
    uint256 public epochId;

    modifier onlyOwner{
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    constructor(IController _controller, uint _marketIndex, uint _epochBegin, uint _epochId){
        controller = IController(_controller);
        owner = msg.sender;
        marketIndex = _marketIndex;
        epochBegin = _epochBegin;
        epochId = _epochId;
    }

    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory /* performData */) {
            if(block.timestamp < epochBegin){
                return (false, "");
            }

            else if(block.timestamp < epochId){
                return (true, 
                abi.encodeWithSelector(
                    bytes4(keccak256("triggerDepeg(uint256,uint256)")), 
            marketIndex, epochID));
            }

            else{
                return (true, abi.encodeWithSelector(
                    bytes4(keccak256("triggerEndEpoch(uint256,uint256)")), 
            marketIndex, epochID));
            }
    }

    function performUpkeep(bytes calldata performData) external override {
        (bool success, ) = controller.call(performData);
        require(success, "performUpkeep: call failed");
        //withdraw funds
    }
}

