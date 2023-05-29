// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {StakingRewards} from "./PausableStakingRewards.sol";
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

    error MarketDoesNotExist(uint256 marketId);
    error EpochDoesNotExist();

    /*//////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    /** @notice Creates staking rewards when event is emitted
     * @param marketEpochId Current market epoch ID
     * @param mIndex Current market index
     * @param hedgeFarm Hedge farm address
     * @param riskFarm Risk farm address
     */
    event CreatedStakingReward(
        bytes32 indexed marketEpochId,
        uint256 indexed mIndex,
        address hedgeFarm,
        address riskFarm
    );

    /** @notice Contract constructor
     * @param _govToken Governance token address
     * @param _factory VaultFactory address
     */
    constructor(address _govToken, address _factory) {
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
    function createStakingRewards(uint256 _marketIndex, uint256 _epochEnd)
        external
        onlyOwner
        returns (address insr, address risk)
    {
        VaultFactory vaultFactory = VaultFactory(factory);

        address _insrToken = vaultFactory.getVaults(_marketIndex)[0];
        address _riskToken = vaultFactory.getVaults(_marketIndex)[1];

        if (_insrToken == address(0) || _riskToken == address(0))
            revert MarketDoesNotExist(_marketIndex);

        if (
            Vault(_insrToken).idExists(_epochEnd) == false ||
            Vault(_riskToken).idExists(_epochEnd) == false
        ) revert EpochDoesNotExist();

        StakingRewards insrStake = new StakingRewards(
            owner(),
            owner(),
            govToken,
            _insrToken,
            _epochEnd
        );
        StakingRewards riskStake = new StakingRewards(
            owner(),
            owner(),
            govToken,
            _riskToken,
            _epochEnd
        );

        emit CreatedStakingReward(
            keccak256(
                abi.encodePacked(
                    _marketIndex,
                    Vault(_insrToken).idEpochBegin(_epochEnd),
                    _epochEnd
                )
            ),
            _marketIndex,
            address(insrStake),
            address(riskStake)
        );

        return (address(insrStake), address(riskStake));
    }
}
