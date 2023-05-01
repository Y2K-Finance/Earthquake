pragma solidity ^0.8.17;

interface IRedstoneCore {
    function getOracleNumericValueFromTxMsg(bytes32 dataFeedId) external view returns (uint256);
}
