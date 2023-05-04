pragma solidity 0.8.17;

import "../v2/interfaces/IDepegCondition.sol";
import "../v2/interfaces/IPriceProvider.sol";
import {IVaultV2} from "../v2/interfaces/IVaultV2.sol";



contract PriceBasedDepegCondition is IDepegCondition {
    IPriceProvider public priceProvider;
    IVaultV2 public premiumVault;
    uint256 public epochId;

    constructor(address _priceProvider, address _premiumVault) {
        priceProvider = IPriceProvider(_priceProvider);
        premiumVault = IVaultV2(_premiumVault);
    }

    function checkDepegCondition(uint256 _marketId, uint256 _epochId) external view override returns (bool) {
        if (!premiumVault.epochExists(_epochId)) {
            revert EpochNotExist();
            //return false;  //TODO -- decide between reverts and bools here (benifits / drawbacks)
        }

        int256 price = priceProvider.getLatestPrice();
        if (int256(premiumVault.strike()) <= price) {
            revert PriceNotAtStrikePrice(price);
            //return false; //TODO -- decide between reverts and bools here
        }

        return true;
    }

    
    // Custom errors
    error PriceNotAtStrikePrice(int256 price);
    error EpochNotExist();
}
