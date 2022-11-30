// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// AutomationCompatible.sol imports the functions from both ./AutomationBase.sol and
// ./interfaces/AutomationCompatibleInterface.sol
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface IController {

    function triggerDepeg(uint256 marketIndex, uint256 epochEnd) external;

}

contract UpkeepController is Ownable, AutomationCompatibleInterface {

    IController controller;
    uint256 public biggestMarketIndex;

    mapping(uint256 => uint256) public marketIndexToCurrentEpochId;

    constructor(IController _controller, uint256 epochId){
        controller = IController(_controller);
        for (uint256 i = 1; i <= 3; i++) {
            marketIndexToCurrentEpochId[i] = epochId;
        }
    }


    function startTask(uint256 _marketIndex, uint256 _epochId) public onlyOwner {
        if(biggestMarketIndex < _marketIndex) {
            biggestMarketIndex = _marketIndex;
        }

        marketIndexToCurrentEpochId[_marketIndex] = _epochId;
    }

    function checkUpkeep(bytes calldata /* checkData */) external override returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = false;
        for (uint256 i=1; i<=3; i++) {
            (bool success, ) = address(controller).call(abi.encodeWithSignature("triggerDepeg(uint256,uint256)", i, marketIndexToCurrentEpochId[i]));
            upkeepNeeded = upkeepNeeded || success;
        }
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        bool upkeepNeeded = false;
        for (uint256 i = 1; i <= 3; i++) {
            (bool success, ) = address(controller).call(abi.encodeWithSignature("triggerDepeg(uint256,uint256)", i, marketIndexToCurrentEpochId[i]));
            upkeepNeeded = upkeepNeeded || success;
        }
        require(upkeepNeeded, "At least 1 market");
    }

    function depeg() external {
        controller.triggerDepeg(1, marketIndexToCurrentEpochId[1]);
    }
}