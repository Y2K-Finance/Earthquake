pragma solidity 0.8.17;

import "./IDepegCondition.sol";
import "./IConditionProvider.sol";
import {IVaultV2} from "../interfaces/IVaultV2.sol";
import "forge-std/console.sol";

contract PriceBasedDepegCondition is IDepegCondition {
    IConditionProvider public priceProvider;
    IVaultV2 public premiumVault;
    uint256 public epochId;

    constructor(address _priceProvider, address _premiumVault) {
        priceProvider = IConditionProvider(_priceProvider);
        premiumVault = IVaultV2(_premiumVault);
    }

    function checkDepegCondition(
        uint256 _marketId,
        uint256 _epochId
    ) external view override returns (bool) {
        console.log(_epochId);
        if (!premiumVault.epochExists(_epochId)) {
            revert EpochNotExist();
            //return false;  //TODO -- decide between reverts and bools here (benifits / drawbacks)
        }

        int256 price = priceProvider.getLatestPrice(_marketId);
        console.log("premiumVault 2");
        console.log(address(premiumVault));
        console.log(uint256(premiumVault.strike()));
        console.log(uint256(price));
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
