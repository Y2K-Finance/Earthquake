// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {StakingRewards} from "./StakingRewards.sol";

contract RewardBalances {
    using SafeMath for uint256;
    address[] public stakingRewardsContracts;
    address public owner;

    /* ========== CONSTRUCTOR ========== */
    constructor(address[] memory _stakingRewardsContracts) {
        stakingRewardsContracts = _stakingRewardsContracts;
        owner = msg.sender;
    }

    function balanceOf(address account) external view returns (uint256) {
        uint256 balance; // initialize to 0

        for (uint256 i; i < stakingRewardsContracts.length; i++) { // i initialize to 0
            balance = balance.add(
                StakingRewards(stakingRewardsContracts[i]).earned(account)
            );
        }

        return balance;
    }

    function appendStakingContractAddress(address _stakingRewardsContract)
        public
    {
        require(msg.sender == owner, "RewardBalances: FORBIDDEN");
        require(_stakingRewardsContract != address(0), "RewardBalances: ZERO_ADDRESS");

        stakingRewardsContracts.push(_stakingRewardsContract);
    }


    function appendStakingContractAddressesLoop(address[] memory _stakingRewardsContracts)
        external
    {
        require(msg.sender == owner, "RewardBalances: FORBIDDEN");

        for (uint256 i; i < _stakingRewardsContracts.length; i++) { // initializes to 0
           appendStakingContractAddress(_stakingRewardsContracts[i]);
        }
    }

    function removeStakingContractAddress(uint8 _index) external {
        require(msg.sender == owner, "RewardBalances: FORBIDDEN");
        require(_index <= stakingRewardsContracts.length-1, "RewardBalances: OUT_OF_BOUNDS");

        delete stakingRewardsContracts[_index];
    }
}
