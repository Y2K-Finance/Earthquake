// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IOptimisticOracleV3 {
    function assertTruth(
        bytes calldata claim,
        address asserter,
        address callBackAddress,
        address sovereignSecurity,
        uint64 assertionLiveness,
        IERC20 currency,
        uint256 bond,
        bytes32 defaultIdentifier,
        bytes32 domain
    ) external payable returns (bytes32 assertionId);

    function getMinimumBond(address currency) external returns (uint256);

    function defaultIdentifier() external returns (bytes32);
}
