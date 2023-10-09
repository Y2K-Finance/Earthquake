// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IFinder {
    /**
     * @notice Gets the address of the contract that implements the given `interfaceName`.
     * @param interfaceName queried interface.
     * @return implementationAddress address of the deployed contract that implements the interface.
     */
    function getImplementationAddress(
        bytes32 interfaceName
    ) external view returns (address);
}
