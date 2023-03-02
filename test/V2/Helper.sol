// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "./MintableToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Helper is Test {
    uint256 public constant STRIKE = 1000000000000000000;
    uint256 public constant COLLATERAL_MINUS_FEES = 21989999998407999999;
    uint256 public constant COLLATERAL_MINUS_FEES_DIV10 = 2198999999840799999;
    uint256 public constant NEXT_COLLATERAL_MINUS_FEES = 21827317001456829250;
    uint256 public constant USER1_EMISSIONS_AFTER_WITHDRAW = 1059999999991999999748;
    uint256 public constant USER2_EMISSIONS_AFTER_WITHDRAW = 59999999991999999748;
    uint256 public constant USER_AMOUNT_AFTER_WITHDRAW = 13112658495641799945;
    address public constant ADMIN = address(0x1);
    address public constant WETH = address(0x888);
    address public constant TREASURY = address(0x777);
    address public constant NOTADMIN = address(0x99);
    address public constant USER = address(0xCCA23C05a9Cf7e78830F3fd55b1e8CfCCbc5E50F);
    address public constant USER2 = address(0x12312);
    address public constant ARBITRUM_SEQUENCER = address(0xFdB631F5EE196F0ed6FAa767959853A9F217697D);
    address public constant USDC_CHAINLINK = address(0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3);
    address public constant USDC_TOKEN = address(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);
    address public constant RELAYER = address(0x55);
    address public UNDERLYING = address(0x123);
    address public TOKEN = address(new MintableToken("Token", "tkn"));
}
