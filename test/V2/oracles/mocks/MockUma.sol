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

    function defaultIdentifier() external pure returns (bytes32) {
        return
            bytes32(
                abi.encode(
                    0x4153534552545f54525554480000000000000000000000000000000000000000
                )
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
        bytes32 _defaultIdentifier,
        bytes32 domain
    ) external payable returns (bytes32 assertionId) {
        currency.transferFrom(msg.sender, address(this), bond);
        assertionId = bytes32(abi.encode(0x12));

        removeUnusedWarning(
            claim,
            asserter,
            callBackAddress,
            sovereignSecurity,
            assertionLiveness,
            _defaultIdentifier,
            domain
        );
    }

    function removeUnusedWarning(
        bytes calldata claim,
        address asserter,
        address callBackAddress,
        address sovereignSecurity,
        uint64 assertionLiveness,
        bytes32 _defaultIdentifier,
        bytes32 domain
    ) internal pure {
        asserter = callBackAddress;
        sovereignSecurity = callBackAddress;
        assertionLiveness += 1;
        _defaultIdentifier = domain;
        domain = keccak256(claim);
    }

    function getMinimumBond(address addr) external pure returns (uint256) {
        address muteWarning = addr;
        addr = muteWarning;
        return 1e6;
    }
}
