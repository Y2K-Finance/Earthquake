// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IVaultFactoryV2} from "../interfaces/IVaultFactoryV2.sol";
import {IVaultV2} from "../interfaces/IVaultV2.sol";
import "@chainlink/interfaces/AggregatorV3Interface.sol";
import "@chainlink/interfaces/AggregatorV2V3Interface.sol";
import {FixedPointMathLib} from "@solmate/utils/FixedPointMathLib.sol";

/// @author Y2K Finance Team

contract ControllerPeggedAssetV2 {
    using FixedPointMathLib for uint256;
    IVaultFactoryV2 public immutable vaultFactory;
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
     * @param epochId market epoch ID
     * @param marketId market ID
     * @param tvl TVL
     * @param strikeMet Flag if event isDisaster
     * @param time time
     * @param depegPrice Price that triggered depeg
     */
    event EpochResolved(
        uint256 epochId,
        uint256 marketId,
        VaultTVL tvl,
        bool strikeMet,
        uint256 time,
        int256 depegPrice
    );

    event NullEpoch(
        uint256 epochId,
        uint256 marketId,
        VaultTVL tvl,
        uint256 time
    );

    struct VaultTVL {
        uint256 COLLAT_claimTVL;
        uint256 COLLAT_finalTVL;
        uint256 PREM_claimTVL;
        uint256 PREM_finalTVL;
    }

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /** @notice Contract constructor
     * @param _factory VaultFactory address
     * @param _l2Sequencer Arbitrum sequencer address
     * @param _treasury Treasury address
     */
    constructor(
        address _factory,
        address _l2Sequencer,
        address _treasury
    ) {
        if (_factory == address(0)) revert ZeroAddress();

        if (_l2Sequencer == address(0)) revert ZeroAddress();

        vaultFactory = IVaultFactoryV2(_factory);
        sequencerUptimeFeed = AggregatorV2V3Interface(_l2Sequencer);
        treasury = _treasury;
    }

    /*//////////////////////////////////////////////////////////////
                                FUNCTIONS
    //////////////////////////////////////////////////////////////*/

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

        if (premiumVault.idExists(_epochId) == false) revert EpochNotExist();

        int256 price = getLatestPrice(premiumVault.token());

        if (int256(premiumVault.strike()) <= price)
            revert PriceNotAtStrikePrice(price);

        (uint40 epochStart, uint40 epochEnd) = premiumVault.getEpochConfig(
            _epochId
        );

        if (uint256(epochStart) > block.timestamp) revert EpochNotStarted();

        if (block.timestamp > uint256(epochEnd)) revert EpochExpired();

        //require this function cannot be called twice in the same epoch for the same vault
        if (premiumVault.idEpochEnded(_epochId)) revert EpochFinishedAlready();
        if (collateralVault.idEpochEnded(_epochId))
            revert EpochFinishedAlready();

        premiumVault.endEpoch(_epochId);
        collateralVault.endEpoch(_epochId);

        uint256 epochFee = vaultFactory.getEpochFee(_epochId);

        uint256 premiumTVL = premiumVault.idFinalTVL(_epochId);
        uint256 collateralTVL = collateralVault.idFinalTVL(_epochId);

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
            premiumVault.idExists(_epochId) == false ||
            collateralVault.idExists(_epochId) == false
        ) revert EpochNotExist();

        (, uint40 epochEnd) = premiumVault.getEpochConfig(_epochId);

        if (block.timestamp <= uint256(epochEnd)) revert EpochNotExpired();

        //require this function cannot be called twice in the same epoch for the same vault
        if (premiumVault.idEpochEnded(_epochId)) revert EpochFinishedAlready();
        if (collateralVault.idEpochEnded(_epochId))
            revert EpochFinishedAlready();

        premiumVault.endEpoch(_epochId);
        collateralVault.endEpoch(_epochId);

        uint256 epochFee = vaultFactory.getEpochFee(_epochId);

        uint256 premiumTVL = premiumVault.idFinalTVL(_epochId);
        uint256 collateralTVL = collateralVault.idFinalTVL(_epochId);

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
            premiumVault.idExists(_epochId) == false ||
            collateralVault.idExists(_epochId) == false
        ) revert EpochNotExist();

        (uint40 epochStart, ) = premiumVault.getEpochConfig(_epochId);

        if (block.timestamp < uint256(epochStart)) revert EpochNotStarted();

        //require this function cannot be called twice in the same epoch for the same vault
        if (premiumVault.idEpochEnded(_epochId)) revert EpochFinishedAlready();
        if (collateralVault.idEpochEnded(_epochId))
            revert EpochFinishedAlready();

        //set claim TVL to 0 if total assets are 0
        if (premiumVault.totalAssets(_epochId) == 0) {
            premiumVault.endEpoch(_epochId);
            collateralVault.endEpoch(_epochId);

            premiumVault.setClaimTVL(_epochId, 0);
            collateralVault.setClaimTVL(
                _epochId,
                collateralVault.idFinalTVL(_epochId)
            );

            collateralVault.setEpochNull(_epochId);
        } else if (collateralVault.totalAssets(_epochId) == 0) {
            premiumVault.endEpoch(_epochId);
            collateralVault.endEpoch(_epochId);

            premiumVault.setClaimTVL(
                _epochId,
                premiumVault.idFinalTVL(_epochId)
            );
            collateralVault.setClaimTVL(_epochId, 0);

            premiumVault.setEpochNull(_epochId);
        } else revert VaultNotZeroTVL();

        emit NullEpoch(
            _epochId,
            _marketId,
            VaultTVL(
                collateralVault.idClaimTVL(_epochId),
                collateralVault.idFinalTVL(_epochId),
                premiumVault.idClaimTVL(_epochId),
                premiumVault.idFinalTVL(_epochId)
            ),
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
