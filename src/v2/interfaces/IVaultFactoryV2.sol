pragma solidity 0.8.17;

interface IVaultFactoryV2 {
    function createNewMarket(
        uint256 fee,
        address token,
        address depeg,
        uint256 beginEpoch,
        uint256 endEpoch,
        address oracle,
        string memory name
    ) external returns (address);

    function getVaults(uint256) external view returns (address[2] memory);

    function getEpochFee(uint256) external view returns (uint16);

    function tokenToOracle(address token) external view returns (address);
}
