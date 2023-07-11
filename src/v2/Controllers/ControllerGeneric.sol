// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IVaultFactoryV2} from "../interfaces/IVaultFactoryV2.sol";
import {IVaultV2} from "../interfaces/IVaultV2.sol";
import {FixedPointMathLib} from "@solmate/utils/FixedPointMathLib.sol";
import {IConditionProvider} from "../interfaces/IConditionProvider.sol";

/// @author Y2K Finance Team
contract ControllerGeneric {
    using FixedPointMathLib for uint256;
    IVaultFactoryV2 public immutable vaultFactory;
    address public immutable treasury;

    constructor(address _factory, address _treasury) {
        if (_factory == address(0)) revert ZeroAddress();
        if (_treasury == address(0)) revert ZeroAddress();
        vaultFactory = IVaultFactoryV2(_factory);
        treasury = _treasury;
    }

    /*//////////////////////////////////////////////////////////////
                                FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /** @notice Trigger depeg event
     * @param _marketId Target market index
     * @param _epochId End of epoch set for market
     */
    function triggerLiquidation(uint256 _marketId, uint256 _epochId) public {
        (
            IVaultV2 premiumVault,
            IVaultV2 collateralVault
        ) = _checkGenericConditions(_marketId, _epochId);
        int256 price = _checkLiquidationConditions(
            _marketId,
            _epochId,
            premiumVault,
            collateralVault
        );

        premiumVault.resolveEpoch(_epochId);
        collateralVault.resolveEpoch(_epochId);

        uint256 epochFee = vaultFactory.getEpochFee(_epochId);

        uint256 premiumTVL = premiumVault.finalTVL(_epochId);
        uint256 collateralTVL = collateralVault.finalTVL(_epochId);

        uint256 premiumFee = calculateWithdrawalFeeValue(premiumTVL, epochFee);
        uint256 collateralFee = calculateWithdrawalFeeValue(
            collateralTVL,
            epochFee
        );

        uint256 premiumTVLAfterFee = premiumTVL - premiumFee;
        uint256 collateralTVLAfterFee = collateralTVL - collateralFee;

        premiumVault.setClaimTVL(_epochId, collateralTVLAfterFee);
        collateralVault.setClaimTVL(_epochId, premiumTVLAfterFee);

        // send fees to treasury and remaining TVL to respective counterparty vault
        // strike price reached so premium is entitled to collateralTVL - collateralFee
        premiumVault.sendTokens(_epochId, premiumFee, treasury);
        premiumVault.sendTokens(
            _epochId,
            premiumTVLAfterFee,
            address(collateralVault)
        );
        // strike price is reached so collateral is still entitled to premiumTVL - premiumFee but looses collateralTVL
        collateralVault.sendTokens(_epochId, collateralFee, treasury);
        collateralVault.sendTokens(
            _epochId,
            collateralTVLAfterFee,
            address(premiumVault)
        );

        emit EpochResolved(
            _epochId,
            _marketId,
            VaultTVL(
                premiumTVLAfterFee,
                collateralTVL,
                collateralTVLAfterFee,
                premiumTVL
            ),
            true,
            price
        );

        emit ProtocolFeeCollected(
            _epochId,
            _marketId,
            premiumFee,
            collateralFee
        );
    }

    /** @notice Trigger epoch end without depeg event
     * @param _marketId Target market index
     * @param _epochId End of epoch set for market
     */
    function triggerEndEpoch(uint256 _marketId, uint256 _epochId) public {
        (
            IVaultV2 premiumVault,
            IVaultV2 collateralVault
        ) = _checkGenericConditions(_marketId, _epochId);

        _checkEndEpochConditions(_epochId, premiumVault);

        premiumVault.resolveEpoch(_epochId);
        collateralVault.resolveEpoch(_epochId);

        uint256 epochFee = vaultFactory.getEpochFee(_epochId);

        uint256 premiumTVL = premiumVault.finalTVL(_epochId);
        uint256 collateralTVL = collateralVault.finalTVL(_epochId);

        uint256 premiumFee = calculateWithdrawalFeeValue(premiumTVL, epochFee);

        uint256 premiumTVLAfterFee = premiumTVL - premiumFee;
        uint256 collateralTVLAfterFee = collateralTVL + premiumTVLAfterFee;

        // strike price is not reached so premium is entiled to 0
        premiumVault.setClaimTVL(_epochId, 0);
        // strike price is not reached so collateral is entitled to collateralTVL + premiumTVLAfterFee
        collateralVault.setClaimTVL(_epochId, collateralTVLAfterFee);

        // send premium fees to treasury and remaining TVL to collateral vault
        premiumVault.sendTokens(_epochId, premiumFee, treasury);
        // strike price reached so collateral is entitled to collateralTVLAfterFee
        premiumVault.sendTokens(
            _epochId,
            premiumTVLAfterFee,
            address(collateralVault)
        );

        emit EpochResolved(
            _epochId,
            _marketId,
            VaultTVL(collateralTVLAfterFee, collateralTVL, 0, premiumTVL),
            false,
            0
        );

        emit ProtocolFeeCollected(
            _epochId,
            _marketId,
            premiumFee,
            0
        );
    }

    /** @notice Trigger epoch invalid when one vault has 0 TVL
     * @param _marketId Target market index
     * @param _epochId End of epoch set for market
     */
    function triggerNullEpoch(uint256 _marketId, uint256 _epochId) public {
        (
            IVaultV2 premiumVault,
            IVaultV2 collateralVault
        ) = _checkGenericConditions(_marketId, _epochId);
        _checkNullEpochConditions(_marketId, premiumVault);

        //set claim TVL to final TVL if total assets are 0
        if (premiumVault.totalAssets(_epochId) == 0) {
            premiumVault.resolveEpoch(_epochId);
            collateralVault.resolveEpoch(_epochId);

            premiumVault.setClaimTVL(_epochId, 0);
            collateralVault.setClaimTVL(
                _epochId,
                collateralVault.finalTVL(_epochId)
            );

            collateralVault.setEpochNull(_epochId);
        } else if (collateralVault.totalAssets(_epochId) == 0) {
            premiumVault.resolveEpoch(_epochId);
            collateralVault.resolveEpoch(_epochId);

            premiumVault.setClaimTVL(_epochId, premiumVault.finalTVL(_epochId));
            collateralVault.setClaimTVL(_epochId, 0);

            premiumVault.setEpochNull(_epochId);
        } else revert VaultNotZeroTVL();

        emit NullEpoch(
            _epochId,
            _marketId,
            VaultTVL(
                collateralVault.claimTVL(_epochId),
                collateralVault.finalTVL(_epochId),
                premiumVault.claimTVL(_epochId),
                premiumVault.finalTVL(_epochId)
            )
        );
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/
    function _checkGenericConditions(
        uint256 _marketId,
        uint256 _epochId
    ) private view returns (IVaultV2 premiumVault, IVaultV2 collateralVault) {
        address[2] memory vaults = vaultFactory.getVaults(_marketId);

        if (vaults[0] == address(0) || vaults[1] == address(0))
            revert MarketDoesNotExist(_marketId);

        premiumVault = IVaultV2(vaults[0]);
        collateralVault = IVaultV2(vaults[1]);

        if (
            !premiumVault.epochExists(_epochId) ||
            !collateralVault.epochExists(_epochId)
        ) revert EpochNotExist();

        //require this function cannot be called twice in the same epoch for the same vault
        if (premiumVault.epochResolved(_epochId)) revert EpochFinishedAlready();
        if (collateralVault.epochResolved(_epochId))
            revert EpochFinishedAlready();
    }

    function _checkLiquidationConditions(
        uint256 _marketId,
        uint256 _epochId,
        IVaultV2 premiumVault,
        IVaultV2 collateralVault
    ) internal view returns (int256 price) {
        (uint40 epochStart, uint40 epochEnd, ) = premiumVault.getEpochConfig(
            _epochId
        );

        if (uint256(epochStart) > block.timestamp) revert EpochNotStarted();

        if (block.timestamp > uint256(epochEnd)) revert EpochExpired();

        // check if epoch qualifies for null epoch
        if (
            premiumVault.totalAssets(_epochId) == 0 ||
            collateralVault.totalAssets(_epochId) == 0
        ) {
            revert VaultZeroTVL();
        }

        bool conditionMet;
        IConditionProvider conditionProvider = IConditionProvider(
            vaultFactory.marketToOracle(_marketId)
        );
        (conditionMet, price) = conditionProvider.conditionMet(
            premiumVault.strike(),
            _marketId
        );
        if (!conditionMet) revert ConditionNotMet();
    }

    function _checkEndEpochConditions(
        uint256 _epochId,
        IVaultV2 premiumVault
    ) internal view {
        (, uint40 epochEnd, ) = premiumVault.getEpochConfig(_epochId);

        if (block.timestamp <= uint256(epochEnd)) revert EpochNotExpired();
    }

    function _checkNullEpochConditions(
        uint256 _epochId,
        IVaultV2 premiumVault
    ) internal view {
        (uint40 epochStart, , ) = premiumVault.getEpochConfig(_epochId);

        if (block.timestamp < uint256(epochStart)) revert EpochNotStarted();
    }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/

    function canExecLiquidation(uint256 _marketId, uint256 _epochId)
        public
        view
        returns (bool)
    {
        address[2] memory vaults = vaultFactory.getVaults(_marketId);

        if (vaults[0] == address(0) || vaults[1] == address(0)) return false;

        IVaultV2 premiumVault = IVaultV2(vaults[0]);
        IVaultV2 collateralVault = IVaultV2(vaults[1]);

        if (premiumVault.epochExists(_epochId) == false) return false;

        (uint40 epochStart, uint40 epochEnd, ) = premiumVault.getEpochConfig(
            _epochId
        );

        if (uint256(epochStart) > block.timestamp) return false;

        if (block.timestamp > uint256(epochEnd)) return false;

        //require this function cannot be called twice in the same epoch for the same vault
        if (premiumVault.epochResolved(_epochId)) return false;
        if (collateralVault.epochResolved(_epochId)) return false;

        // check if epoch qualifies for null epoch
        if (
            premiumVault.totalAssets(_epochId) == 0 ||
            collateralVault.totalAssets(_epochId) == 0
        ) {
            return false;
        }

        bool conditionMet;
        IConditionProvider conditionProvider = IConditionProvider(
            vaultFactory.marketToOracle(_marketId)
        );
        (conditionMet,) = conditionProvider.conditionMet(
            premiumVault.strike(),
            _marketId
        );
        return conditionMet;
    }

    function canExecNullEpoch(uint256 _marketId, uint256 _epochId)
        public
        view
        returns (bool)
    {
        address[2] memory vaults = vaultFactory.getVaults(_marketId);

        if (vaults[0] == address(0) || vaults[1] == address(0)) return false;

        IVaultV2 premiumVault = IVaultV2(vaults[0]);
        IVaultV2 collateralVault = IVaultV2(vaults[1]);

        if (
            premiumVault.epochExists(_epochId) == false ||
            collateralVault.epochExists(_epochId) == false
        ) return false;

        (uint40 epochStart, , ) = premiumVault.getEpochConfig(_epochId);

        if (block.timestamp < uint256(epochStart)) return false;

        if (premiumVault.epochResolved(_epochId)) return false;
        if (collateralVault.epochResolved(_epochId)) return false;

        if (premiumVault.totalAssets(_epochId) == 0) {
            return true;
        } else if (collateralVault.totalAssets(_epochId) == 0) {
            return true;
        } else return false;
    }

    function canExecEnd(uint256 _marketId, uint256 _epochId)
        public
        view
        returns (bool)
    {
        address[2] memory vaults = vaultFactory.getVaults(_marketId);

        if (vaults[0] == address(0) || vaults[1] == address(0)) return false;

        IVaultV2 premiumVault = IVaultV2(vaults[0]);
        IVaultV2 collateralVault = IVaultV2(vaults[1]);

        if (
            premiumVault.epochExists(_epochId) == false ||
            collateralVault.epochExists(_epochId) == false
        ) return false;

        if (
            premiumVault.totalAssets(_epochId) == 0 ||
            collateralVault.totalAssets(_epochId) == 0
        ) return false;

        (, uint40 epochEnd, ) = premiumVault.getEpochConfig(_epochId);

        if (block.timestamp <= uint256(epochEnd)) return false;

        //require this function cannot be called twice in the same epoch for the same vault
        if (premiumVault.epochResolved(_epochId)) return false;
        if (collateralVault.epochResolved(_epochId)) return false;

        return true;
    }

    /** @notice Lookup target VaultFactory address
     * @dev need to find way to express typecasts in NatSpec
     */
    function getVaultFactory() external view returns (address) {
        return address(vaultFactory);
    }

    /** @notice Calculate amount to withdraw after subtracting protocol fee
     * @param amount Amount of tokens to withdraw
     * @param fee Fee to be applied
     */
    function calculateWithdrawalFeeValue(
        uint256 amount,
        uint256 fee
    ) public pure returns (uint256 feeValue) {
        // 0.5% = multiply by 10000 then divide by 50
        return amount.mulDivDown(fee, 10000);
    }

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error MarketDoesNotExist(uint256 marketId);
    error ZeroAddress();
    error EpochFinishedAlready();
    error EpochNotStarted();
    error EpochExpired();
    error EpochNotExist();
    error EpochNotExpired();
    error VaultNotZeroTVL();
    error VaultZeroTVL();
    error ConditionNotMet();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /** @notice Resolves epoch when event is emitted
     * @param epochId market epoch ID
     * @param marketId market ID
     * @param tvl TVL
     * @param strikeMet Flag if event isDisaster
     * @param depegPrice Price that triggered depeg
     */
    event EpochResolved(
        uint256 indexed epochId,
        uint256 indexed marketId,
        VaultTVL tvl,
        bool strikeMet,
        int256 depegPrice
    );

    /** @notice Sets epoch to null when event is emitted
     * @param epochId market epoch ID
     * @param marketId market ID
     * @param tvl TVL
     */
    event NullEpoch(
        uint256 indexed epochId,
        uint256 indexed marketId,
        VaultTVL tvl
    );

    struct VaultTVL {
        uint256 COLLAT_claimTVL;
        uint256 COLLAT_finalTVL;
        uint256 PREM_claimTVL;
        uint256 PREM_finalTVL;
    }



    /** @notice Indexes protocol fees collected
     * @param epochId market epoch ID
     * @param marketId market ID
     * @param premiumFee premium fee
     * @param collateralFee collateral fee
     */
    event ProtocolFeeCollected(
        uint256 indexed epochId,
        uint256 indexed marketId,
        uint256 premiumFee,
        uint256 collateralFee
    );
}
