// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {ERC20} from "@solmate/tokens/ERC20.sol";
import {IVaultOverhaul} from "./IVaultOverhaul.sol";
// import {IVaultOverhaulFactoryOverhauled} from "../../interfaces/IVaultOverhaulFactoryOverhauled.sol";
import "@chainlink/interfaces/AggregatorV3Interface.sol";
import "@chainlink/interfaces/AggregatorV2V3Interface.sol";

/// @author Y2K Finance Team

contract Controller {
    IVaultOverhaulFactoryOverhauled public immutable vaultFactory;
    AggregatorV2V3Interface internal sequencerUptimeFeed;

    uint16 private constant GRACE_PERIOD_TIME = 3600;
    address public treasury;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error MarketDoesNotExist(uint256 marketId);
    error SequencerDown();
    error GracePeriodNotOver();
    error ZeroAddress();
    error EpochFinishedAlready();
    error PriceNotAtStrikePrice(int256 price);
    error EpochNotStarted();
    error EpochExpired();
    error OraclePriceZero();
    error RoundIDOutdated();
    error EpochNotExist();
    error EpochNotExpired();
    error VaultNotZeroTVL();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /** @notice Depegs insurance vault when event is emitted
     * @param epochMarketID market epoch ID
     * @param tvl TVL
     * @param isDisaster Flag if event isDisaster
     * @param epoch epoch
     * @param time time
     * @param depegPrice Price that triggered depeg
     */
    event EpochEnded(
        uint256 epochMarketID,
        VaultTVL tvl,
        bool isDisaster,
        uint256 epoch,
        uint256 time,
        int256 depegPrice
    );

    event NullEpoch(
        uint256 epochMarketID,
        VaultTVL tvl,
        uint256 epoch,
        uint256 time
    );

    struct VaultTVL {
        uint256 RISK_claimTVL;
        uint256 RISK_finalTVL;
        uint256 INSR_claimTVL;
        uint256 INSR_finalTVL;
    }

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /** @notice Contract constructor
     * @param _factory VaultFactory address
     * @param _l2Sequencer Arbitrum sequencer address
     */
    constructor(address _factory, address _l2Sequencer, address _treasury) {
        if (_factory == address(0)) revert ZeroAddress();

        if (_l2Sequencer == address(0)) revert ZeroAddress();

        vaultFactory = IVaultOverhaulFactoryOverhauled(_factory);
        sequencerUptimeFeed = AggregatorV2V3Interface(_l2Sequencer);
        treasury = _treasury;
    }

    /*//////////////////////////////////////////////////////////////
                                FUNCTIONS
    //////////////////////////////////////////////////////////////*/

      /**
    @notice Factory function, changes treasury address
    @param _treasury New treasury address
     */
    function changeTreasury(address _treasury) public onlyFactory {
        if (_treasury == address(0)) revert AddressZero();
        treasury = _treasury;
    }


    /** @notice Trigger depeg event
     * @param _marketIndex Target market index
     * @param _epochId End of epoch set for market
     */
    function triggerDepeg(uint256 _marketIndex, uint256 _epochId) public {
        address[2] memory vaultsAddress = vaultFactory.getVaults(uint32(_marketIndex));
        IVaultOverhaul premiumVault = IVaultOverhaul(vaultsAddress[0]);
        IVaultOverhaul collateralVault = IVaultOverhaul(vaultsAddress[1]);

        if (vaultsAddress[0] == address(0) || vaultsAddress[1] == address(0))
            revert MarketDoesNotExist(_marketIndex);

        if (premiumVault.idExists(_epochId) == false) revert EpochNotExist();

        if (premiumVault.strikePrice() <= getLatestPrice(premiumVault.tokenInsured()))
            revert PriceNotAtStrikePrice(
                getLatestPrice(premiumVault.tokenInsured())
            );

        (uint40 epochStart, uint40 epochEnd) = premiumVault.getEpochTime(_epochId);

        if (uint256(epochStart) > block.timestamp)
            revert EpochNotStarted();

        if (block.timestamp > uint256(epochEnd)) revert EpochExpired();

        //require this function cannot be called twice in the same epoch for the same vault
        if (premiumVault.idEpochEnded(_epochId)) revert EpochFinishedAlready();
        if (collateralVault.idEpochEnded(_epochId)) revert EpochFinishedAlready();

        premiumVault.endEpoch(_epochId);
        collateralVault.endEpoch(_epochId);
        
        uint256 epochFee = vaultFactory.getEpochFee(_epochId);

        uint256 premiumTVL = premiumVault.idFinalTVL(_epochId);
        uint256 collateralTVL = collateralVault.idFinalTVL(_epochId);

        uint256 premiumFee = calculateWithdrawalFeeValue(premiumTVL, epochFee);
        uint256 collateralFee = calculateWithdrawalFeeValue(collateralTVL, epochFee);

        uint256 premiumTVLAfterFee = premiumTVL - premiumFee;
        uint256 collateralTVLAfterFee = collateralTVL - collateralFee;

        premiumVault.setClaimTVL(_epochId, collateralTVLAfterFee);
        collateralVault.setClaimTVL(_epochId, premiumTVLAfterFee);
        
        // send fees to treasury and remaining TVL to respective counterparty vault
        premiumVault.sendTokens(premiumFee, treasury);
        premiumVault.sendTokens(premiumTVLAfterFee, address(collateralVault));
        collateralVault.sendTokens(collateralFee, treasury);
        collateralVault.sendTokens(collateralTVLAfterFee, address(premiumVault));

        VaultTVL memory tvl = VaultTVL(
            premiumTVLAfterFee,
            collateralTVL,
            collateralTVLAfterFee,
            premiumTVL
        );

        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            vaultFactory.tokenToOracle(premiumVault.tokenInsured())
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();

        emit EpochEnded(
            _epochId,
            tvl,
            true,
            epochEnd,
            block.timestamp,
            price
        );
    }

    /** @notice Trigger epoch end without depeg event
     * @param _marketIndex Target market index
     * @param epochEnd End of epoch set for market
     */
    function triggerEndEpoch(uint256 _marketIndex, uint256 _epochId) public {

        address[2] memory vaultsAddress = vaultFactory.getVaults(uint32(_marketIndex));

        IVaultOverhaul premiumVault = IVaultOverhaul(vaultsAddress[0]);
        IVaultOverhaul collateralVault = IVaultOverhaul(vaultsAddress[1]);

        if (vaultsAddress[0] == address(0) || vaultsAddress[1] == address(0))
            revert MarketDoesNotExist(_marketIndex);

        if (
            premiumVault.idExists(_epochId) == false ||
            collateralVault.idExists(_epochId) == false
        ) revert EpochNotExist();

        (, uint40 epochEnd) = premiumVault.getEpochTime(_epochId);

        if (block.timestamp <= uint256(epochEnd)) revert EpochNotExpired();

        //require this function cannot be called twice in the same epoch for the same vault
        if (premiumVault.idEpochEnded(_epochId)) revert EpochFinishedAlready();
        if (collateralVault.idEpochEnded(_epochId)) revert EpochFinishedAlready();

        premiumVault.endEpoch(_epochId);
        collateralVault.endEpoch(_epochId);

        uint256 epochFee = vaultFactory.getEpochFee(_epochId);

        uint256 premiumTVL = premiumVault.idFinalTVL(_epochId);
        uint256 collateralTVL = collateralVault.idFinalTVL(_epochId);

        uint256 premiumFee = calculateWithdrawalFeeValue(premiumTVL, epochFee);

        uint256 premiumTVLAfterFee = premiumTVL - premiumFee;
        uint256 collateralTVLAfterFee = collateralTVL + premiumTVLAfterFee;
        
        premiumVault.setClaimTVL(_epochId, 0);
        collateralVault.setClaimTVL(
            _epochId,
           collateralTVLAfterFee
        );

        premiumVault.sendTokens(premiumFee, treasury);
        premiumVault.sendTokens(premiumTVLAfterFee, address(collateralVault));

        VaultTVL memory tvl = VaultTVL(
            collateralTVLAfterFee,
            collateralTVL,
            0,
            premiumTVL
        );

        emit EpochEnded(
            _epochId,
            tvl,
            false,
            epochEnd,
            block.timestamp,
            getLatestPrice(premiumVault.tokenInsured())
        );
    }

    /** @notice Trigger epoch invalid when one vault has 0 TVL
     * @param _marketIndex Target market index
     * @param _epochId End of epoch set for market
     */
    function triggerNullEpoch(uint256 _marketIndex, uint256 _epochId) public {
        address[2] memory vaultsAddress = vaultFactory.getVaults(uint32(_marketIndex));

        IVaultOverhaul premiumVault = IVaultOverhaul(vaultsAddress[0]);
        IVaultOverhaul collateralVault = IVaultOverhaul(vaultsAddress[1]);

        if (vaultsAddress[0] == address(0) || vaultsAddress[1] == address(0))
            revert MarketDoesNotExist(_marketIndex);

        if (
            premiumVault.idExists(_epochId) == false ||
            collateralVault.idExists(_epochId) == false
        ) revert EpochNotExist();

        (uint40 epochStart,) = premiumVault.getEpochTime(_epochId);

        if (block.timestamp < uint256(epochStart)) revert EpochNotStarted();

        //require this function cannot be called twice in the same epoch for the same vault
        if (premiumVault.idEpochEnded(_epochId)) revert EpochFinishedAlready();
        if (collateralVault.idEpochEnded(_epochId)) revert EpochFinishedAlready();

        //set claim TVL to 0 if total assets are 0
        if (premiumVault.totalAssets(_epochId) == 0) {
            premiumVault.endEpoch(_epochId);
            collateralVault.endEpoch(_epochId);

            premiumVault.setClaimTVL(_epochId, 0);
            collateralVault.setClaimTVL(_epochId, collateralVault.idFinalTVL(_epochId));

            collateralVault.setEpochNull(_epochId);
        } else if (collateralVault.totalAssets(_epochId) == 0) {
            premiumVault.endEpoch(_epochId);
            collateralVault.endEpoch(_epochId);

            premiumVault.setClaimTVL(_epochId, premiumVault.idFinalTVL(_epochId));
            collateralVault.setClaimTVL(_epochId, 0);

            premiumVault.setEpochNull(_epochId);
        } else revert VaultNotZeroTVL();

        VaultTVL memory tvl = VaultTVL(
            collateralVault.idClaimTVL(_epochId),
            collateralVault.idFinalTVL(_epochId),
            premiumVault.idClaimTVL(_epochId),
            premiumVault.idFinalTVL(_epochId)
        );

        emit NullEpoch(
            _epochId,
            tvl,
            epochEnd,
            block.timestamp
        );
    }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/
    /** @notice Lookup token price
     * @param _token Target token address
     * @return nowPrice Current token price
     */
    function getLatestPrice(address _token)
        public
        view
        returns (int256 nowPrice)
    {
        (
            ,
            /*uint80 roundId*/
            int256 answer,
            uint256 startedAt, /*uint256 updatedAt*/ /*uint80 answeredInRound*/
            ,

        ) = sequencerUptimeFeed.latestRoundData();

        // Answer == 0: Sequencer is up
        // Answer == 1: Sequencer is down
        bool isSequencerUp = answer == 0;
        if (!isSequencerUp) {
            revert SequencerDown();
        }

        // Make sure the grace period has passed after the sequencer is back up.
        uint256 timeSinceUp = block.timestamp - startedAt;
        if (timeSinceUp <= GRACE_PERIOD_TIME) {
            revert GracePeriodNotOver();
        }

        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            vaultFactory.tokenToOracle(_token)
        );
        (uint80 roundID, int256 price, , , uint80 answeredInRound) = priceFeed
            .latestRoundData();

        if (priceFeed.decimals() < 18) {
            uint256 decimals = 10**(18 - (priceFeed.decimals()));
            price = price * int256(decimals);
        } else if (priceFeed.decimals() == 18) {
            price = price;
        } else {
            uint256 decimals = 10**((priceFeed.decimals() - 18));
            price = price / int256(decimals);
        }

        if (price <= 0) revert OraclePriceZero();

        if (answeredInRound < roundID) revert RoundIDOutdated();

        return price;
    }

    /** @notice Lookup target VaultFactory address
     * @dev need to find way to express typecasts in NatSpec
     */
    function getVaultFactory() external view returns (address) {
        return address(vaultFactory);
    }


   function calculateWithdrawalFeeValue(uint256 amount, uint256 fee)
        public
        pure
        returns (uint256 feeValue)
    {
        // 0.5% = multiply by 1000 then divide by 5
        return amount.mulDivUp(fee, 1000);
    }

}
