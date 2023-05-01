// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//    getValueForDataFeed(0x565354) on the following contract: https://goerli.arbiscan.io/address/0x86392aF1fB288f49b8b8fA2495ba201084C70A13#readContract. 

interface IVST {
    function getValueForDataFeed(bytes32) external view returns (uint256);
}

contract vstOracle{
    IVST public vstToken;

    constructor(address _vstAddress) {
        vstToken = IVST(_vstAddress);
    }

    function getValue() public view returns (uint256) {
        return vstToken.getValueForDataFeed(bytes32("VST"));
    }
}


