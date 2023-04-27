pragma solidity ^0.8.17;

interface IPriceProvider {
    function getLatestPrice() external view returns (int256);
}
