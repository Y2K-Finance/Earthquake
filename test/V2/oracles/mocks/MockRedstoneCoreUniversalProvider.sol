// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {
    RedstoneCoreUniversalProvider
} from "../../../../src/v2/oracles/universal/RedstoneCoreUniversalProvider.sol";

contract MockRedstoneCoreUniversalProvider is RedstoneCoreUniversalProvider {
    constructor(uint256 _timeOut) RedstoneCoreUniversalProvider(_timeOut) {}

    function getUniqueSignersThreshold()
        public
        view
        virtual
        override
        returns (uint8)
    {
        return 1;
    }

    function getAuthorisedSignerIndex(
        address
    ) public view virtual override returns (uint8) {
        // authorize everyone
        return 0;
    }

    function validateTimestamp(
        uint256 receivedTimestampMilliseconds
    ) public view override {
        // allow any timestamp
    }
}
