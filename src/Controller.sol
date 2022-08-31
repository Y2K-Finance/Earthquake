// SPDX-License-Identifier: AGPL-3.0-only
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

    error SequencerDown();
    error GracePeriodNotOver();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    
    /** @notice Triggers whenever insurance vault depegs (
      * @param epochMarketID Current market index
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
    /** @notice Admin permissions
      */
    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    /** @notice Modifier to ensure market exists, current market epoch time and price are valid 
      * @param marketIndex Target market index
      * @param epochEnd End of epoch set for market
      */
    modifier isDisaster(uint256 marketIndex, uint256 epochEnd) {
        address[] memory vaultsAddress = vaultFactory.getVaults(marketIndex);
        require(
            vaultsAddress.length == 2,
            "There is no market available for this market Index!"
        );
        address vaultAddress = vaultsAddress[0];
        Vault vault = Vault(vaultAddress);
        require(
            vault.strikePrice() >= getLatestPrice(vault.tokenInsured()),
            "Current price is not at the strike price target!"
        );
        require(
            vault.idEpochBegin(epochEnd) < block.timestamp,
            "Epoch has not started, cannot insure until epoch has started!"
        );
        require(
            block.timestamp < epochEnd,
            "Epoch for this insurance has expired!"
        );
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
        require(_admin != address(0), "admin cannot be the zero address");
        require(_factory != address(0), "factory cannot be the zero address");
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
        require(insrVault.idFinalTVL(epochEnd) == 0, "Error: TVLs must be 0");
        require(riskVault.idFinalTVL(epochEnd) == 0, "Error: TVLs must tbe 0");

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
            false,
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
        require(
            vaultFactory.getVaults(marketIndex).length == 2,
            "There is no market available for this market Index!"
        );
        require(
            block.timestamp >= epochEnd,
            "Epoch for this insurance has not expired!"
        );
        address[] memory vaultsAddress = vaultFactory.getVaults(marketIndex);

        Vault insrVault = Vault(vaultsAddress[0]);
        Vault riskVault = Vault(vaultsAddress[1]);

        //require this function cannot be called twice in the same epoch for the same vault
        require(insrVault.idFinalTVL(epochEnd) == 0, "Error: TVLs must be 0");
        require(riskVault.idFinalTVL(epochEnd) == 0, "Error: TVLs must be 0");

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

        int256 decimals = 10e18 / int256(10**priceFeed.decimals());
        price = price * decimals;

        require(price > 0, "Oracle price <= 0");
        require(answeredInRound >= roundID, "RoundID from Oracle is outdated!");
        require(timeStamp != 0, "Timestamp == 0 !");

        return price;
    }

    function getVaultFactory() external view returns (address) {
        return address(vaultFactory);
    }
}
