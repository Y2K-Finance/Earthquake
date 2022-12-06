pragma solidity ^0.8.15;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function mint(address account) external;
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}