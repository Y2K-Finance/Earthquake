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
     * @param epochMarketID Current market epoch ID
     * @param tvl Current TVL
     * @param isDisaster Flag if event isDisaster
     * @param epoch Current epoch
     * @param time Current time
     * @param depegPrice Price that triggered depeg
     */
    event DepegInsurance(
        bytes32 epochMarketID,
        VaultTVL tvl,
        bool isDisaster,
        uint256 epoch,
        uint256 time,
        int256 depegPrice
    );

    event NullEpoch(
        bytes32 epochMarketID,
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
     * @param marketIndex Target market index
     * @param epochEnd End of epoch set for market
     */
    function triggerDepeg(uint256 marketIndex, uint256 epochEnd) public {
        address[2] memory vaultsAddress = vaultFactory.getVaults(marketIndex);
        IVaultOverhaul premiumVault = IVaultOverhaul(vaultsAddress[0]);
        IVaultOverhaul collateralVault = IVaultOverhaul(vaultsAddress[1]);

        if (vaultsAddress[0] == address(0) || vaultsAddress[1] == address(0))
            revert MarketDoesNotExist(marketIndex);

        if (premiumVault.idExists(epochEnd) == false) revert EpochNotExist();

        if (premiumVault.strikePrice() <= getLatestPrice(premiumVault.tokenInsured()))
            revert PriceNotAtStrikePrice(
                getLatestPrice(premiumVault.tokenInsured())
            );

        if (premiumVault.idEpochBegin(epochEnd) > block.timestamp)
            revert EpochNotStarted();

        if (block.timestamp > epochEnd) revert EpochExpired();

        //require this function cannot be called twice in the same epoch for the same vault
        if (premiumVault.idEpochEnded(epochEnd)) revert EpochFinishedAlready();
        if (collateralVault.idEpochEnded(epochEnd)) revert EpochFinishedAlready();

        premiumVault.endEpoch(epochEnd);
        collateralVault.endEpoch(epochEnd);
        
        uint256 epochFee = vaultFactory.getEpochFee(marketIndex, premiumVault.idEpochBegin(epochEnd) ,epochEnd);

        uint256 premiumTVL = premiumVault.idFinalTVL(epochEnd);
        uint256 collateralTVL = collateralVault.idFinalTVL(epochEnd);

        uint256 premiumFee = calculateWithdrawalFeeValue(premiumTVL, epochFee);
        uint256 collateralFee = calculateWithdrawalFeeValue(collateralTVL, epochFee);

        uint256 premiumTVLAfterFee = premiumTVL - premiumFee;
        uint256 collateralTVLAfterFee = collateralTVL - collateralFee;

        premiumVault.setClaimTVL(epochEnd, collateralTVLAfterFee);
        collateralVault.setClaimTVL(epochEnd, premiumTVLAfterFee);
        
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

        emit DepegInsurance(
            keccak256(
                abi.encodePacked(
                    marketIndex,
                    premiumVault.idEpochBegin(epochEnd),
                    epochEnd
                )
            ),
            tvl,
            true,
            epochEnd,
            block.timestamp,
            price
        );
    }

    /** @notice Trigger epoch end without depeg event
     * @param marketIndex Target market index
     * @param epochEnd End of epoch set for market
     */
    function triggerEndEpoch(uint256 marketIndex, uint256 epochEnd) public {
        if (block.timestamp <= epochEnd) revert EpochNotExpired();

        address[2] memory vaultsAddress = vaultFactory.getVaults(marketIndex);

        IVaultOverhaul premiumVault = IVaultOverhaul(vaultsAddress[0]);
        IVaultOverhaul collateralVault = IVaultOverhaul(vaultsAddress[1]);

        uint40 epochEndCasted = uint40(epochEnd);

        if (vaultsAddress[0] == address(0) || vaultsAddress[1] == address(0))
            revert MarketDoesNotExist(marketIndex);

        if (
            premiumVault.idExists(epochEndCasted) == false ||
            collateralVault.idExists(epochEndCasted) == false
        ) revert EpochNotExist();

        //require this function cannot be called twice in the same epoch for the same vault
        if (premiumVault.idEpochEnded(epochEndCasted)) revert EpochFinishedAlready();
        if (collateralVault.idEpochEnded(epochEndCasted)) revert EpochFinishedAlready();

        premiumVault.endEpoch(epochEndCasted);
        collateralVault.endEpoch(epochEndCasted);

        uint256 epochFee = vaultFactory.getEpochFee(marketIndex, premiumVault.idEpochBegin(epochEndCasted), epochEndCasted);

        uint256 premiumTVL = premiumVault.idFinalTVL(epochEndCasted);
        uint256 collateralTVL = collateralVault.idFinalTVL(epochEndCasted);

        uint256 premiumFee = calculateWithdrawalFeeValue(premiumTVL, epochFee);

        uint256 premiumTVLAfterFee = premiumTVL - premiumFee;
        uint256 collateralTVLAfterFee = collateralTVL + premiumTVLAfterFee;
        
        premiumVault.setClaimTVL(epochEndCasted, 0);
        collateralVault.setClaimTVL(
            epochEndCasted,
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

        emit DepegInsurance(
            keccak256(
                abi.encodePacked(
                    marketIndex,
                    premiumVault.idEpochBegin(epochEndCasted),
                    epochEndCasted
                )
            ),
            tvl,
            false,
            epochEnd,
            block.timestamp,
            getLatestPrice(premiumVault.tokenInsured())
        );
    }

    /** @notice Trigger epoch invalid when one vault has 0 TVL
     * @param marketIndex Target market index
     * @param epochEnd End of epoch set for market
     */
    function triggerNullEpoch(uint256 marketIndex, uint256 epochEnd) public {
        address[2] memory vaultsAddress = vaultFactory.getVaults(marketIndex);

        IVaultOverhaul premiumVault = IVaultOverhaul(vaultsAddress[0]);
        IVaultOverhaul collateralVault = IVaultOverhaul(vaultsAddress[1]);

        if (vaultsAddress[0] == address(0) || vaultsAddress[1] == address(0))
            revert MarketDoesNotExist(marketIndex);

        if (
            premiumVault.idExists(epochEnd) == false ||
            collateralVault.idExists(epochEnd) == false
        ) revert EpochNotExist();

        if (block.timestamp < premiumVault.idEpochBegin(epochEnd))
            revert EpochNotStarted();

        if (
            premiumVault.idExists(epochEnd) == false ||
            collateralVault.idExists(epochEnd) == false
        ) revert EpochNotExist();

        //require this function cannot be called twice in the same epoch for the same vault
        if (premiumVault.idEpochEnded(epochEnd)) revert EpochFinishedAlready();
        if (collateralVault.idEpochEnded(epochEnd)) revert EpochFinishedAlready();

        //set claim TVL to 0 if total assets are 0
        if (premiumVault.totalAssets(epochEnd) == 0) {
            premiumVault.endEpoch(epochEnd);
            collateralVault.endEpoch(epochEnd);

            premiumVault.setClaimTVL(epochEnd, 0);
            collateralVault.setClaimTVL(epochEnd, collateralVault.idFinalTVL(epochEnd));

            collateralVault.setEpochNull(epochEnd);
        } else if (collateralVault.totalAssets(epochEnd) == 0) {
            premiumVault.endEpoch(epochEnd);
            collateralVault.endEpoch(epochEnd);

            premiumVault.setClaimTVL(epochEnd, premiumVault.idFinalTVL(epochEnd));
            collateralVault.setClaimTVL(epochEnd, 0);

            premiumVault.setEpochNull(epochEnd);
        } else revert VaultNotZeroTVL();

        VaultTVL memory tvl = VaultTVL(
            collateralVault.idClaimTVL(epochEnd),
            collateralVault.idFinalTVL(epochEnd),
            premiumVault.idClaimTVL(epochEnd),
            premiumVault.idFinalTVL(epochEnd)
        );

        emit NullEpoch(
            keccak256(
                abi.encodePacked(
                    marketIndex,
                    premiumVault.idEpochBegin(epochEnd),
                    epochEnd
                )
            ),
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
