// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IGNS {
    function tvl() external view returns (uint256);
}

contract gdaiOracle {
    IGNS public gnsToken;

    constructor(address _gnsTokenAddress) {
        gnsToken = IGNS(_gnsTokenAddress);
    }

    function getValue() public view returns (uint256) {
        return gnsToken.tvl();
    }
}
