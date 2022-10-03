// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {StakingRewards} from "./StakingRewards.sol";
import {VaultFactory} from "../VaultFactory.sol";
import {Vault} from "../Vault.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @author MiguelBits

contract RewardsFactory is Ownable {
    address public govToken;
    address public factory;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error MarketDoesNotExist(uint marketId);
    error EpochDoesNotExist();

    /*//////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/
    
    /** @notice Creates staking rewards when event is emitted
      * @param marketIndex Current market epoch ID
      * @param epochdEndId Epoch Id of market
      * @param addressFarms farms addresss [0] hedge [1] risk
      */ 
    event CreatedStakingReward(
        uint indexed marketIndex,
        uint256 indexed epochdEndId,
        address[2] indexed addressFarms
    );

    /** @notice Contract constructor
      * @param _govToken Governance token address
      * @param _factory VaultFactory address
      */
    constructor(
        address _govToken,
        address _factory
    ) {
        govToken = _govToken;
        factory = _factory;
    }

    /*//////////////////////////////////////////////////////////////
                                  METHODS
    //////////////////////////////////////////////////////////////*/
    
    /** @notice Trigger staking rewards event
      * @param _marketIndex Target market index
      * @param _epochEnd End of epoch set for market
      * @return insr Insurance rewards address, first tuple address entry 
      * @return risk Risk rewards address, second tuple address entry 
      */
    function createStakingRewards(uint256 _marketIndex, uint256 _epochEnd, uint256 _rewardDuration, uint256 _rewardRate)
        external
        onlyOwner
        returns (address insr, address risk)
    {
        VaultFactory vaultFactory = VaultFactory(factory);

        address _insrToken = vaultFactory.getVaults(_marketIndex)[0];
        address _riskToken = vaultFactory.getVaults(_marketIndex)[1];

        if(_insrToken == address(0) || _riskToken == address(0))
            revert MarketDoesNotExist(_marketIndex);

        if(Vault(_insrToken).idExists(_epochEnd) == false || Vault(_riskToken).idExists(_epochEnd) == false)
            revert EpochDoesNotExist();

        StakingRewards insrStake = new StakingRewards(
            owner(),
            owner(),
            govToken,
            _insrToken,
            _epochEnd,
            _rewardDuration,
            _rewardRate
        );
        StakingRewards riskStake = new StakingRewards(
            owner(),
            owner(),
            govToken,
            _riskToken,
            _epochEnd,
            _rewardDuration,
            _rewardRate
        );

        address[2] memory Farms;
        Farms = [address(insrStake),address(riskStake)];

        emit CreatedStakingReward(
            _marketIndex,
            _epochEnd,
            Farms
        );

        return (address(insrStake), address(riskStake));
    }
}
