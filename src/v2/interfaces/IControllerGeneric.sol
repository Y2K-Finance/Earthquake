// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

interface IControllerGeneric {
    function getVaultFactory() external view returns (address);

    function triggerLiquidation(uint256 marketIndex, uint256 epochId) external;

    function triggerEndEpoch(uint256 marketIndex, uint256 epochId) external;

    function triggerNullEpoch(uint256 marketIndex, uint256 epochId) external;

    function canExecLiquidation(uint256 marketIndex, uint256 epochId)
        external
        view
        returns (bool);

    function canExecNullEpoch(uint256 marketIndex, uint256 epochId)
        external
        view
        returns (bool);

    function canExecEnd(uint256 marketIndex, uint256 epochId)
        external
        view
        returns (bool);
}
