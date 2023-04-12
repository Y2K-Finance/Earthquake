pragma solidity 0.8.17;

interface IDepegCondition {
    function checkDepegCondition() external view returns (bool);
}
