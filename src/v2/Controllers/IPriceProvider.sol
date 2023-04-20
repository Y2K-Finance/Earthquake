pragma solidity ^0.8.17;

interface IPriceProvider {
    function getLatestPrice(address _token) external view returns (int256);
}
