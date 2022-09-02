// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {StakingRewards} from "./StakingRewards.sol";
import {VaultFactory} from "../VaultFactory.sol";
import {Vault} from "../Vault.sol";

contract RewardsFactory {
    address public admin;
    address public govToken;
    address public factory;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error MarketDoesNotExist(uint marketId);
    error AddressNotAdmin();
    error EpochDoesNotExist(uint epoch);

    /*//////////////////////////////////////////////////////////////
                                 MAPPINGS
    //////////////////////////////////////////////////////////////*/

    //mapping(uint => mapping(uint => address[])) public marketIndex_epoch_StakingRewards; //Market Index, Epoch, Staking Rewards [0] = insrance, [1] = risk
    // solhint-disable-next-line var-name-mixedcase
    mapping(bytes32 => address[]) public hashedIndex_StakingRewards; //Hashed Index, Staking Rewards [0] = insrance, [1] = risk

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

    /*//////////////////////////////////////////////////////////////
                                  MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /** @notice Only admin addresses can call functions with this modifier
      */
    modifier onlyAdmin() {
        if(msg.sender != admin)
            revert AddressNotAdmin();
        _;
    }

    /** @notice Contract constructor
      * @param _govToken Governance token address
      * @param _factory VaultFactory address
      * @param _admin Admin address
      */
    constructor(
        address _govToken,
        address _factory,
        address _admin
    ) {
        admin = _admin;
        govToken = _govToken;
        factory = _factory;
    }

    /*//////////////////////////////////////////////////////////////
                                  METHODS
    //////////////////////////////////////////////////////////////*/
    
    /** @notice Trigger staking rewards event
      * @param _marketIndex Target market index
      * @param epochEnd End of epoch set for market
      * @return insr Insurance rewards address, first tuple address entry 
      * @return risk Risk rewards address, second tuple address entry 
      */
    function createStakingRewards(uint256 _marketIndex, uint256 epochEnd)
        external
        onlyAdmin
        returns (address insr, address risk)
    {
        VaultFactory vaultFactory = VaultFactory(factory);

        address _insrToken = vaultFactory.getVaults(_marketIndex)[0];
        address _riskToken = vaultFactory.getVaults(_marketIndex)[1];

        if(_insrToken == address(0) || _riskToken == address(0))
            revert MarketDoesNotExist(_marketIndex);

        if(Vault(_insrToken).idExists(epochEnd) == false || Vault(_riskToken).idExists(epochEnd) == false)
            revert EpochDoesNotExist(epochEnd);

        StakingRewards insrStake = new StakingRewards(
            admin,
            admin,
            govToken,
            _insrToken,
            epochEnd
        );
        StakingRewards riskStake = new StakingRewards(
            admin,
            admin,
            govToken,
            _riskToken,
            epochEnd
        );

        bytes32 hashedIndex = keccak256(abi.encode(_marketIndex, epochEnd));
        hashedIndex_StakingRewards[hashedIndex] = [
            address(insrStake),
            address(riskStake)
        ];

        emit CreatedStakingReward(
            keccak256(
                abi.encodePacked(
                    _marketIndex,
                    Vault(_insrToken).idEpochBegin(epochEnd),
                    epochEnd
                )
            ),
            _marketIndex,
            address(insrStake),
            address(riskStake)
        );

        return (address(insrStake), address(riskStake));
    }

    /** @notice Lookup hashed indexes
      * @param _index Target index
      * @param _epoch Target epoch
      * @return hashedIndex hashed index
      */
    function getHashedIndex(uint256 _index, uint256 _epoch)
        public
        pure
        returns (bytes32 hashedIndex)
    {
        return keccak256(abi.encode(_index, _epoch));
    }
}
