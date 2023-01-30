// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "./MintableToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Helper is Test {
    address ADMIN = address(0x1);
    address WETH = address(0x888);
    address TREASURY = address(0x777);
    address UNDERLYING = address(0x123);
    address TOKEN = address(new MintableToken("Token", "tkn"));
    address NOTADMIN = address(0x99);
    uint256 STRIKE = 1000000000000000000;
    address USER = address(0xCCA23C05a9Cf7e78830F3fd55b1e8CfCCbc5E50F);
}
