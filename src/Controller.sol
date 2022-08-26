// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

import {ERC20} from "@solmate/tokens/ERC20.sol";
import "./Vault.sol";
import "./VaultFactory.sol";
import "@chainlink/interfaces/AggregatorV3Interface.sol";

contract Controller {
    address public immutable admin;
    VaultFactory immutable vaultFactory;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event DepegInsurance(
        VaultTVL tvl,
        uint256 index,
        uint256 epoch,
        string name,
        uint256 time,
        int256 depegPrice
    );

    struct VaultTVL{
        uint256 RISK_claimTVL;
        uint256 RISK_finalTVL;
        uint256 INSR_claimTVL;
        uint256 INSR_finalTVL;
    }

    /*//////////////////////////////////////////////////////////////
                                 MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

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

    constructor(address _factory, address _admin) {
        require(_admin != address(0), "admin cannot be the zero address");
        require(_factory != address(0), "factory cannot be the zero address");
        admin = _admin;
        vaultFactory = VaultFactory(_factory);
    }

    /*//////////////////////////////////////////////////////////////
                                FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
    @notice trigger depeg event
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
            tvl,
            marketIndex,
            epochEnd,
            insrVault.name(),
            block.timestamp,
            getLatestPrice(insrVault.tokenInsured())
        );
    }

    /**
    @notice no depeg event, and epoch is over
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
            tvl,
            marketIndex,
            epochEnd,
            insrVault.name(),
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

    function getLatestPrice(address _token)
        public
        view
        returns (int256 nowPrice)
    {
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
