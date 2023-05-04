// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../v2/interfaces/IPriceProvider.sol";


interface IVST {
    function getValueForDataFeed(bytes32) external view returns (uint256);
}

contract VstOracle is IPriceProvider {
    IVST public vstToken;
    uint8 decimals;
    
    constructor(address _vstAddress) {
        vstToken = IVST(_vstAddress);
        decimals= 18; //TODO Lookup decimals from contract
    }

    function getValue() public view returns (uint256) {
       /// Convert to decimals
        return vstToken.getValueForDataFeed(bytes32("VST"));
    }
    
    function getDecimals() public view returns (uint8) {
        return decimals;
    }
    
    function getLatestPrice() public view returns (int256) {
      return int256(getValue()); //TODO, careful conversion
    }    
    
}


