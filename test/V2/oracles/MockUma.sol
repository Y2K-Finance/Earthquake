// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IUmaPriceProvider {
    function assertionResolvedCallback(
        bytes32 _assertionId,
        bool _assertedTruthfully
    ) external;
}

contract MockUma {
    function assertionResolvedCallback(
        address _receiver,
        bytes32 _assertionId,
        bool _assertedTruthfully
    ) external {
        IUmaPriceProvider(_receiver).assertionResolvedCallback(
            _assertionId,
            _assertedTruthfully
        );
    }

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
    ) external payable returns (bytes32 assertionId) {
        assertionId = bytes32(abi.encode(0x12));
    }

    function getMinimumBond(address currency) external pure returns (uint256) {
        return 1e6;
    }
}
