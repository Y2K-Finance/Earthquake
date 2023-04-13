pragma solidity 0.8.17;

interface IDepegCondition {
    function checkDepegCondition(uint256 _marketId, uint256 _epochId) external view returns (bool);
}
