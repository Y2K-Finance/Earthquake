// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IVaultFactoryV2} from "../interfaces/IVaultFactoryV2.sol";
import {IVaultV2} from "../interfaces/IVaultV2.sol";
import "@chainlink/interfaces/AggregatorV3Interface.sol";
import "@chainlink/interfaces/AggregatorV2V3Interface.sol";
import {FixedPointMathLib} from "@solmate/utils/FixedPointMathLib.sol";
import "./IDepegCondition.sol";
import "./IPriceProvider.sol";
import "forge-std/console.sol";


/// @author Y2K Finance Team

contract ControllerGenericV2 {

    using FixedPointMathLib for uint256;
    IVaultFactoryV2 public immutable vaultFactory;
    address public immutable treasury;
    bool public locked = false;
    address public admin;
    
    IDepegCondition[] public depegConditions;
    IPriceProvider public priceProvider;
    
    modifier onlyAdmin {
        require(msg.sender == admin, "Only the admin can perform this action");
        _;
    }

    modifier notLocked {
        require(!locked, "The system is locked, no new depeg conditions can be added");
        _;
    }

    constructor(
        address _factory,
        address _sequencer,
        address _treasury,
        address _priceProvider
    ) {
        if (_priceProvider == address(0)) revert ZeroAddress();
        priceProvider = IPriceProvider(_priceProvider);
        
        if (_factory == address(0)) revert ZeroAddress();
        vaultFactory = IVaultFactoryV2(_factory);
        admin = msg.sender; 
        // So we can add depegs, (which could have circular dependencies, i.e., may need to read ControllerGenericV2 in their constructor) 
        
        treasury = _treasury;        
    }
    /*//////////////////////////////////////////////////////////////
                                FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /** @notice Add a Depeg Condition
     * @param _condition The Condition that must be true to trigger liquidation
     */    
    function addDepegCondition(IDepegCondition _condition) external onlyAdmin notLocked {
        if (address(_condition) == address(0)) revert ZeroAddress();
        depegConditions.push(_condition);
    }

    /** @notice Lockdown the system so no more conditions can be added 
    */
    function lockdownSystem() external onlyAdmin {
        locked = true;
    }
    /** @notice Trigger depeg event
     * @param _marketId Target market index
     * @param _epochId End of epoch set for market
    */
    function triggerDepeg(uint256 _marketId, uint256 _epochId) public {
        address[2] memory vaults = vaultFactory.getVaults(_marketId);

        if (vaults[0] == address(0) || vaults[1] == address(0))
            revert MarketDoesNotExist(_marketId);

        IVaultV2 premiumVault = IVaultV2(vaults[0]);
        IVaultV2 collateralVault = IVaultV2(vaults[1]);

        if (premiumVault.epochExists(_epochId) == false) revert EpochNotExist();

        int256 price = priceProvider.getLatestPrice();
        console.log("premiumVault");
        console.log(address(premiumVault));
        console.log(uint256(premiumVault.strike()));
        console.log(uint256(price));
        
        
        for (uint256 i = 0; i < depegConditions.length; i++) {
            if (!depegConditions[i].checkDepegCondition( _marketId, _epochId)) {
                revert NotMetDepegConditions(address(depegConditions[i]));
            }
        }
        
        
        if (int256(premiumVault.strike()) <= price) ////x 
            revert PriceNotAtStrikePrice(price); ////x 

        (uint40 epochStart, uint40 epochEnd, ) = premiumVault.getEpochConfig(
            _epochId
        );

        if (uint256(epochStart) > block.timestamp) revert EpochNotStarted();

        if (block.timestamp > uint256(epochEnd)) revert EpochExpired();

        //require this function cannot be called twice in the same epoch for the same vault
        if (premiumVault.epochResolved(_epochId)) revert EpochFinishedAlready();
        if (collateralVault.epochResolved(_epochId))
            revert EpochFinishedAlready();

        // check if epoch qualifies for null epoch
        if (
            premiumVault.totalAssets(_epochId) == 0 ||
            collateralVault.totalAssets(_epochId) == 0
        ) {
            revert VaultZeroTVL();
        }

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

        // avoid stack too deep error by avoiding local variables
        // uint256 premiumTVLAfterFee = premiumTVL - premiumFee;
        // uint256 collateralTVLAfterFee = collateralTVL - collateralFee;

        premiumVault.setClaimTVL(_epochId, collateralTVL - collateralFee);
        collateralVault.setClaimTVL(_epochId, premiumTVL - premiumFee);

        // send fees to treasury and remaining TVL to respective counterparty vault
        // strike price reached so premium is entitled to collateralTVL - collateralFee
        premiumVault.sendTokens(_epochId, premiumFee, treasury);
        premiumVault.sendTokens(
            _epochId,
            premiumTVL - premiumFee,
            address(collateralVault)
        );
        // strike price is reached so collateral is still entitled to premiumTVL - premiumFee but looses collateralTVL
        collateralVault.sendTokens(_epochId, collateralFee, treasury);
        collateralVault.sendTokens(
            _epochId,
            collateralTVL - collateralFee,
            address(premiumVault)
        );

        emit EpochResolved(
            _epochId,
            _marketId,
            VaultTVL(
                premiumTVL - premiumFee,
                collateralTVL,
                collateralTVL - collateralFee,
                premiumTVL
            ),
            true,
            block.timestamp,
            price
        );
    }

    /** @notice Trigger epoch end without depeg event
     * @param _marketId Target market index
     * @param _epochId End of epoch set for market
     */
    function triggerEndEpoch(uint256 _marketId, uint256 _epochId) public {
        address[2] memory vaults = vaultFactory.getVaults(_marketId);

        if (vaults[0] == address(0) || vaults[1] == address(0))
            revert MarketDoesNotExist(_marketId);

        IVaultV2 premiumVault = IVaultV2(vaults[0]);
        IVaultV2 collateralVault = IVaultV2(vaults[1]);

        if (
            premiumVault.epochExists(_epochId) == false ||
            collateralVault.epochExists(_epochId) == false
        ) revert EpochNotExist();

        (, uint40 epochEnd, ) = premiumVault.getEpochConfig(_epochId);

        if (block.timestamp <= uint256(epochEnd)) revert EpochNotExpired();

        //require this function cannot be called twice in the same epoch for the same vault
        if (premiumVault.epochResolved(_epochId)) revert EpochFinishedAlready();
        if (collateralVault.epochResolved(_epochId))
            revert EpochFinishedAlready();

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
            block.timestamp,
            0
        );
    }

    /** @notice Trigger epoch invalid when one vault has 0 TVL
     * @param _marketId Target market index
     * @param _epochId End of epoch set for market
     */
    function triggerNullEpoch(uint256 _marketId, uint256 _epochId) public {
        address[2] memory vaults = vaultFactory.getVaults(_marketId);

        if (vaults[0] == address(0) || vaults[1] == address(0))
            revert MarketDoesNotExist(_marketId);

        IVaultV2 premiumVault = IVaultV2(vaults[0]);
        IVaultV2 collateralVault = IVaultV2(vaults[1]);

        if (
            premiumVault.epochExists(_epochId) == false ||
            collateralVault.epochExists(_epochId) == false
        ) revert EpochNotExist();

        (uint40 epochStart, , ) = premiumVault.getEpochConfig(_epochId);

        if (block.timestamp < uint256(epochStart)) revert EpochNotStarted();

        //require this function cannot be called twice in the same epoch for the same vault
        if (premiumVault.epochResolved(_epochId)) revert EpochFinishedAlready();
        if (collateralVault.epochResolved(_epochId))
            revert EpochFinishedAlready();

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
            ),
            block.timestamp
        );
    }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/


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
    function calculateWithdrawalFeeValue(uint256 amount, uint256 fee)
        public
        pure
        returns (uint256 feeValue)
    {
        // 0.5% = multiply by 10000 then divide by 50
        return amount.mulDivDown(fee, 10000);
    }

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error MarketDoesNotExist(uint256 marketId);
    error SequencerDown();
    error GracePeriodNotOver();
    error ZeroAddress();
    error EpochFinishedAlready();
    error PriceNotAtStrikePrice(int256 price);
    error NotMetDepegConditions(address cond);
    error EpochNotStarted();
    error EpochExpired();
    error OraclePriceZero();
    error RoundIDOutdated();
    error EpochNotExist();
    error EpochNotExpired();
    error VaultNotZeroTVL();
    error VaultZeroTVL();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /** @notice Resolves epoch when event is emitted
     * @param epochId market epoch ID
     * @param marketId market ID
     * @param tvl TVL
     * @param strikeMet Flag if event isDisaster
     * @param time time
     * @param depegPrice Price that triggered depeg
     */
    event EpochResolved(
        uint256 indexed epochId,
        uint256 indexed marketId,
        VaultTVL tvl,
        bool strikeMet,
        uint256 time,
        int256 depegPrice
    );

    /** @notice Sets epoch to null when event is emitted
     * @param epochId market epoch ID
     * @param marketId market ID
     * @param tvl TVL
     * @param time timestamp
     */
    event NullEpoch(
        uint256 indexed epochId,
        uint256 indexed marketId,
        VaultTVL tvl,
        uint256 time
    );

    struct VaultTVL {
        uint256 COLLAT_claimTVL;
        uint256 COLLAT_finalTVL;
        uint256 PREM_claimTVL;
        uint256 PREM_finalTVL;
    }
}
