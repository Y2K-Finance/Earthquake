// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// AutomationCompatible.sol imports the functions from both ./AutomationBase.sol and
// ./interfaces/AutomationCompatibleInterface.sol
import "@chainlink/AutomationCompatible.sol";
import "./interfaces/IUpkeepRefunder.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IController} from "../../../src/interfaces/IController.sol";

interface KeeperRegistryLike {
    function getUpkeep(uint256 id)
        external
        view
        returns (
            address target,
            uint32 executeGas,
            bytes memory checkData,
            uint96 balance,
            address lastKeeper,
            address admin,
            uint64 maxValidBlocknumber
        );

    function addFunds(uint256 id, uint96 amount) external;
}

contract UpkeepController is Ownable, AutomationCompatibleInterface {

    KeeperRegistryLike public keeperRegistry;
    IController controller;
    address public owner;
    address public linkToken;
    // uint256 public marketIndex;
    // uint256 public epochBegin;
    // uint256 public epochId;
    uint256 public biggestMarketIndex;

    mapping(uint256 => uint256) public marketIndexToCurrentEpochId;

    constructor(IController _controller, address _linkToken/*, uint _marketIndex, uint _epochBegin, uint _epochId*/){
        controller = IController(_controller);
        // marketIndex = _marketIndex;
        // epochBegin = _epochBegin;
        // epochId = _epochId;
        linkToken = _linkToken;
    }


    function startTask(uint256 _marketIndex, uint256 _epochId) public onlyOwner {
        if(biggestMarketIndex < _marketIndex) {
            biggestMarketIndex = _marketIndex;
        }

        marketIndexToCurrentEpochId[_marketIndex] = _epochId;
    }

    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory /* performData */) {

        // for (uint i = 0; i < biggestMarketIndex; i++) {

        //     if(block.timestamp < epochBegin){
        //         return (false, "");
        //     }

        //     else if(block.timestamp < epochId){
        //         return (true, 
        //         abi.encodeWithSelector(
        //             bytes4(keccak256("triggerDepeg(uint256,uint256)")), 
        //     marketIndex, epochID));
        //     }

        //     else{
        //         return (true, abi.encodeWithSelector(
        //             bytes4(keccak256("triggerEndEpoch(uint256,uint256)")), 
        //     marketIndex, epochID));
        //     }
        // }

        return true;
    }

    function performUpkeep(bytes calldata performData) external override {
        for (uint i = 0; i < biggestMarketIndex; i++) {
            performData = abi.encodeWithSelector(bytes4(keccak256("triggerDepeg(uint256,uint256)")), i, marketIndexToCurrentEpochId[i]);
            (bool success, ) = controller.call(performData);

            // require(success, "performUpkeep: call failed");
            //withdraw funds?
        }
    }
}

