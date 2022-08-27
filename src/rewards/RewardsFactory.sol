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
                                  MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

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
                                  EVENTS
    //////////////////////////////////////////////////////////////*/
    event CreatedStakingReward(
        bytes32 indexed MarketEpochId,
        uint256 indexed mIndex,
        uint256 indexed date,
        address hedge_farm,
        address risk_farm
    );

    /*//////////////////////////////////////////////////////////////
                                 MAPPINGS
    //////////////////////////////////////////////////////////////*/

    //mapping(uint => mapping(uint => address[])) public marketIndex_epoch_StakingRewards; //Market Index, Epoch, Staking Rewards [0] = insrance, [1] = risk
    mapping(bytes32 => address[]) public hashedIndex_StakingRewards; //Hashed Index, Staking Rewards [0] = insrance, [1] = risk

    /*//////////////////////////////////////////////////////////////
                                  METHODS
    //////////////////////////////////////////////////////////////*/
    function createStakingRewards(uint256 _marketIndex, uint256 _epoch)
        external
        onlyAdmin
        returns (address insr, address risk)
    {
        VaultFactory vault_factory = VaultFactory(factory);

        address _insrToken = vault_factory.getVaults(_marketIndex)[0];
        address _riskToken = vault_factory.getVaults(_marketIndex)[1];

        StakingRewards insrStake = new StakingRewards(
            admin,
            admin,
            govToken,
            _insrToken,
            _epoch
        );
        StakingRewards riskStake = new StakingRewards(
            admin,
            admin,
            govToken,
            _riskToken,
            _epoch
        );

        bytes32 hashedIndex = keccak256(abi.encode(_marketIndex, _epoch));
        hashedIndex_StakingRewards[hashedIndex] = [
            address(insrStake),
            address(riskStake)
        ];

        emit CreatedStakingReward(
            keccak256(
                abi.encodePacked(
                    _marketIndex,
                    Vault(_insrToken).idEpochBegin(_epoch),
                    _epoch
                )
            ),
            _marketIndex,
            _epoch,
            address(insrStake),
            address(riskStake)
        );

        return (address(insrStake), address(riskStake));
    }

    function getHashedIndex(uint256 _index, uint256 _epoch)
        public
        pure
        returns (bytes32 hashedIndex)
    {
        return keccak256(abi.encode(_index, _epoch));
    }
}
