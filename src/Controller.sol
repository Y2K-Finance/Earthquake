// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {ERC20} from "@solmate/tokens/ERC20.sol";
import "./Vault.sol";
import "./VaultFactory.sol";
import "@chainlink/interfaces/AggregatorV3Interface.sol";
import "@chainlink/interfaces/AggregatorV2V3Interface.sol";

contract Controller {
    address public immutable admin;
    VaultFactory public immutable vaultFactory;
    AggregatorV2V3Interface internal sequencerUptimeFeed;

    uint256 private constant GRACE_PERIOD_TIME = 3600;
    uint256 public constant VAULTS_LENGTH = 2;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error MarketDoesNotExist(uint256 marketId);
    error SequencerDown();
    error GracePeriodNotOver();
    error ZeroAddress();
    error NotZeroTVL();
    error PriceNotAtStrikePrice(int256 price);
    error EpochNotStarted();
    error EpochExpired();
    error OraclePriceZero();
    error RoundIDOutdated();
    error TimestampZero();
    error AddressNotAdmin();
    error EpochNotExist();
    error EpochNotExpired();

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

    /* solhint-disable  var-name-mixedcase */
    struct VaultTVL {
        uint256 RISK_claimTVL;
        uint256 RISK_finalTVL;
        uint256 INSR_claimTVL;
        uint256 INSR_finalTVL;
    }
    /* solhint-enable  var-name-mixedcase */

    /*//////////////////////////////////////////////////////////////
                                 MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /** @notice Only admin addresses can call functions that use this modifier
      */
    modifier onlyAdmin() {
        if(msg.sender != admin)
            revert AddressNotAdmin();
        _;
    }

    /** @notice Modifier to ensure market exists, current market epoch time and price are valid 
      * @param marketIndex Target market index
      * @param epochEnd End of epoch set for market
      */
    modifier isDisaster(uint256 marketIndex, uint256 epochEnd) {
        address[] memory vaultsAddress = vaultFactory.getVaults(marketIndex);
        if(
            vaultsAddress.length != VAULTS_LENGTH
            )
            revert MarketDoesNotExist(marketIndex);

        address vaultAddress = vaultsAddress[0];
        Vault vault = Vault(vaultAddress);

        if(vault.idExists(epochEnd) == false)
            revert EpochNotExist();

        if(
            vault.strikePrice() < getLatestPrice(vault.tokenInsured())
            )
            revert PriceNotAtStrikePrice(getLatestPrice(vault.tokenInsured()));

        if(
            vault.idEpochBegin(epochEnd) > block.timestamp)
            revert EpochNotStarted();

        if(
            block.timestamp > epochEnd
            )
            revert EpochExpired();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /** @notice Contract constructor
      * @param _factory VaultFactory address
      * @param _admin Admin address
      * @param _l2Sequencer Arbitrum sequencer address
      */ 
    constructor(
        address _factory,
        address _admin,
        address _l2Sequencer
    ) {
        if(_admin == address(0))
            revert ZeroAddress();

        if(_factory == address(0)) 
            revert ZeroAddress();

        if(_l2Sequencer == address(0))
            revert ZeroAddress();
        
        admin = _admin;
        vaultFactory = VaultFactory(_factory);
        sequencerUptimeFeed = AggregatorV2V3Interface(_l2Sequencer);
    }

    /*//////////////////////////////////////////////////////////////
                                FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /** @notice Trigger depeg event
      * @param marketIndex Target market index
      * @param epochEnd End of epoch set for market
      */
    function triggerDepeg(uint256 marketIndex, uint256 epochEnd)
        public
        isDisaster(marketIndex, epochEnd)
    {
        address[] memory vaultsAddress = vaultFactory.getVaults(marketIndex);
        Vault insrVault = Vault(vaultsAddress[0]);
        Vault riskVault = Vault(vaultsAddress[1]);

        //require this function cannot be called twice in the same epoch for the same vault
        if(insrVault.idFinalTVL(epochEnd) != 0)
            revert NotZeroTVL();
        if(riskVault.idFinalTVL(epochEnd) != 0) 
            revert NotZeroTVL();

        insrVault.endEpoch(epochEnd, true);
        riskVault.endEpoch(epochEnd, true);

        insrVault.setClaimTVL(epochEnd, riskVault.idFinalTVL(epochEnd));
        riskVault.setClaimTVL(epochEnd, insrVault.idFinalTVL(epochEnd));

        insrVault.sendTokens(epochEnd, address(riskVault));
        riskVault.sendTokens(epochEnd, address(insrVault));

        VaultTVL memory tvl = VaultTVL(
            riskVault.idClaimTVL(epochEnd),
            insrVault.idClaimTVL(epochEnd),
            riskVault.idFinalTVL(epochEnd),
            insrVault.idFinalTVL(epochEnd)
        );

        emit DepegInsurance(
            keccak256(
                abi.encodePacked(
                    marketIndex,
                    insrVault.idEpochBegin(epochEnd),
                    epochEnd
                )
            ),
            tvl,
            true,
            epochEnd,
            block.timestamp,
            getLatestPrice(insrVault.tokenInsured())
        );
    }

    /** @notice Trigger epoch end without depeg event
      * @param marketIndex Target market index
      * @param epochEnd End of epoch set for market
      */
    function triggerEndEpoch(uint256 marketIndex, uint256 epochEnd) public {
        if(
            vaultFactory.getVaults(marketIndex).length != VAULTS_LENGTH)
                revert MarketDoesNotExist(marketIndex);
        if(
            block.timestamp < epochEnd)
            revert EpochNotExpired();

        address[] memory vaultsAddress = vaultFactory.getVaults(marketIndex);

        Vault insrVault = Vault(vaultsAddress[0]);
        Vault riskVault = Vault(vaultsAddress[1]);

        if(insrVault.idExists(epochEnd) == false || riskVault.idExists(epochEnd) == false)
            revert EpochNotExist();

        //require this function cannot be called twice in the same epoch for the same vault
        if(insrVault.idFinalTVL(epochEnd) != 0)
            revert NotZeroTVL();
        if(riskVault.idFinalTVL(epochEnd) != 0) 
            revert NotZeroTVL();

        insrVault.endEpoch(epochEnd, false);
        riskVault.endEpoch(epochEnd, false);

        insrVault.setClaimTVL(epochEnd, 0);
        riskVault.setClaimTVL(epochEnd, insrVault.idFinalTVL(epochEnd));
        insrVault.sendTokens(epochEnd, address(riskVault));

        VaultTVL memory tvl = VaultTVL(
            riskVault.idClaimTVL(epochEnd),
            insrVault.idClaimTVL(epochEnd),
            riskVault.idFinalTVL(epochEnd),
            insrVault.idFinalTVL(epochEnd)
        );

        emit DepegInsurance(
            keccak256(
                abi.encodePacked(
                    marketIndex,
                    insrVault.idEpochBegin(epochEnd),
                    epochEnd
                )
            ),
            tvl,
            false,
            epochEnd,
            block.timestamp,
            getLatestPrice(insrVault.tokenInsured())
        );
    }

    /*//////////////////////////////////////////////////////////////
                                ADMIN SETTINGS
    //////////////////////////////////////////////////////////////*/

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
        (
            uint80 roundID,
            int256 price,
            ,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();

        uint256 decimals = 10**(18-(priceFeed.decimals()));
        price = price * int256(decimals);

        if(price <= 0)
            revert OraclePriceZero();

        if(answeredInRound < roundID)
            revert RoundIDOutdated();

        if(timeStamp == 0)
            revert TimestampZero();

        return price;
    }

    /** @notice Lookup target VaultFactory address
      * @dev need to find way to express typecasts in NatSpec
      */
    function getVaultFactory() external view returns (address) {
        return address(vaultFactory);
    }
}
