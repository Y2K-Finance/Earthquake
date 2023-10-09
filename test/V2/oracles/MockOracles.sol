// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {PythStructs} from "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockOracleAnswerZero {
    uint256 public decimals = 0;
    string public description = "MOCK";

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        roundId = 1;
        answer = 0;
        startedAt = 1;
        updatedAt = block.timestamp;
        answeredInRound = 1;
    }
}

contract MockOracleAnswerOne {
    uint256 public decimals = 0;
    string public description = "MOCK";

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        roundId = 1;
        answer = 1;
        startedAt = 1;
        updatedAt = block.timestamp;
        answeredInRound = 1;
    }
}

contract MockOracleRoundOutdated {
    uint256 public decimals = 0;
    string public description = "MOCK";

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        roundId = 2;
        answer = 1;
        startedAt = 1;
        updatedAt = block.timestamp;
        answeredInRound = 1;
    }
}

contract MockOracleGracePeriod {
    uint256 public decimals = 0;
    string public description = "MOCK";

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        roundId = 2;
        answer = 0;
        startedAt = block.timestamp;
        updatedAt = block.timestamp;
        answeredInRound = 1;
    }
}

contract MockOracleConditionNotMet {
    uint256 public decimals = 0;
    string public description = "MOCK";
    int256 public strike;

    constructor(int256 _strike) {
        strike = _strike + 1;
    }

    function latestRoundData()
        public
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        roundId = 2;
        answer = strike;
        startedAt = block.timestamp;
        updatedAt = block.timestamp;
        answeredInRound = 2;
    }

    function conditionMet(
        uint256 _strike,
        uint256 _marketId
    ) external view returns (bool, int256 price) {
        (, price, , , ) = latestRoundData();
        return (int256(_strike) > price, price);
    }
}

contract MockOracleTimeOut {
    uint256 public decimals = 0;
    string public description = "MOCK";
    uint256 public updateTime;

    // NOTE: This would return a time that is more than timeout
    // @param warptime equals block.timestamp
    // @param timeout equals timeout set for price provider
    constructor(uint256 _warpTime, uint256 _timeout) {
        updateTime = _warpTime - _timeout - 1;
    }

    function latestRoundData()
        public
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        roundId = 2;
        answer = 1 ether;
        startedAt = block.timestamp;
        updatedAt = updateTime;
        answeredInRound = 2;
    }

    function conditionMet(
        uint256 _strike
    ) external view returns (bool, int256 price) {
        (, price, , , ) = latestRoundData();
        return (int256(_strike) > price, price);
    }
}

contract MockOracleConditionMet {
    uint256 public decimals = 0;
    string public description = "MOCK";
    uint256 public updateTime;

    // NOTE: This would return a time that is within timeout range
    // @param warptime equals block.timestamp
    // @param timeout equals timeout set for price provider
    constructor(uint256 _warpTime) {
        updateTime = _warpTime - 1;
    }

    function latestRoundData()
        public
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        roundId = 2;
        answer = 1 ether;
        startedAt = block.timestamp;
        updatedAt = updateTime;
        answeredInRound = 2;
    }

    function conditionMet(
        uint256 _strike,
        uint256 _marketId
    ) external view returns (bool, int256 price) {
        (, price, , , ) = latestRoundData();
        return (int256(_strike) > price, price);
    }
}

////////////////// CVI Implementation //////////////////
contract MockOracleAnswerZeroCVI {
    function getCVILatestRoundData()
        external
        view
        returns (uint32 answer, uint80 roundId, uint256 updatedAt)
    {
        roundId = 1;
        answer = 0;
        updatedAt = block.timestamp;
    }
}

contract MockOracleAnswerOneCVI {
    function getCVILatestRoundData()
        external
        view
        returns (uint32 answer, uint80 roundId, uint256 updatedAt)
    {
        roundId = 1;
        answer = 1;
        updatedAt = block.timestamp;
    }
}

contract MockOracleRoundOutdatedCVI {
    function getCVILatestRoundData()
        external
        view
        returns (uint32 answer, uint80 roundId, uint256 updatedAt)
    {
        roundId = 2;
        answer = 1;
        updatedAt = block.timestamp;
    }
}

contract MockOracleGracePeriodCVI {
    function getCVILatestRoundData()
        external
        view
        returns (uint32 answer, uint80 roundId, uint256 updatedAt)
    {
        roundId = 2;
        answer = 0;
        updatedAt = block.timestamp;
    }
}

contract MockOracleConditionNotMetCVI {
    uint32 public strike;

    constructor(uint32 _strike) {
        strike = _strike + 1;
    }

    function getCVILatestRoundData()
        public
        view
        returns (uint32 answer, uint80 roundId, uint256 updatedAt)
    {
        roundId = 2;
        answer = strike;
        updatedAt = block.timestamp;
    }

    function conditionMet(
        uint256 _strike
    ) external view returns (bool, int256) {
        (uint256 price, , ) = getCVILatestRoundData();
        return (int256(_strike) > int256(price), int256(price));
    }
}

contract MockOracleTimeOutCVI {
    uint256 public updateTime;

    // NOTE: This would return a time that is more than timeout
    // @param warptime equals block.timestamp
    // @param timeout equals timeout set for price provider
    constructor(uint256 _warpTime, uint256 _timeout) {
        updateTime = _warpTime - _timeout - 1;
    }

    function getCVILatestRoundData()
        public
        view
        returns (uint32 answer, uint80 roundId, uint256 updatedAt)
    {
        roundId = 2;
        answer = uint32(1);
        updatedAt = updateTime;
    }

    function conditionMet(
        uint256 _strike
    ) external view returns (bool, int256) {
        (uint256 price, , ) = getCVILatestRoundData();
        return (int256(_strike) > int256(price), int256(price));
    }
}

contract MockOracleConditionMetCVI {
    uint256 public updateTime;

    // NOTE: This would return a time that is within timeout range
    // @param warptime equals block.timestamp
    // @param timeout equals timeout set for price provider
    constructor(uint256 _warpTime) {
        updateTime = _warpTime - 1;
    }

    function getCVILatestRoundData()
        public
        view
        returns (uint32 answer, uint80 roundId, uint256 updatedAt)
    {
        roundId = 2;
        answer = uint32(1);
        updatedAt = updateTime;
    }

    function conditionMet(
        uint256 _strike
    ) external view returns (bool, int256) {
        (uint256 price, , ) = getCVILatestRoundData();
        return (int256(_strike) > int256(price), int256(price));
    }
}

////////////////// Pyth Implementation //////////////////
contract MockOracleAnswerNegativePyth {
    function getPriceUnsafe(
        bytes32
    ) external view returns (PythStructs.Price memory price) {
        price = PythStructs.Price(-1, 0, -8, block.timestamp);
    }

    function getPriceNoOlderThan(
        bytes32,
        uint
    ) external view returns (PythStructs.Price memory price) {
        price = PythStructs.Price(-1, 0, -8, block.timestamp);
    }
}

contract MockOracleExponentTooSmallPyth {
    function getPriceUnsafe(
        bytes32
    ) external view returns (PythStructs.Price memory price) {
        price = PythStructs.Price(-899898, 0, -19, block.timestamp);
    }

    function getPriceNoOlderThan(
        bytes32,
        uint
    ) external view returns (PythStructs.Price memory price) {
        price = PythStructs.Price(899898, 0, -19, block.timestamp);
    }
}

contract MockUmaV2 {
    function requestPrice(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        IERC20 currency,
        uint256 reward
    ) external returns (uint256 totalBond) {}

    function setBond(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        uint256 bond
    ) external returns (uint256 totalBond) {}

    function setCustomLiveness(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        uint256 customLiveness
    ) external {}

    function setCallbacks(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        bool callbackOnPriceProposed,
        bool callbackOnPriceDisputed,
        bool callbackOnPriceSettled
    ) external {}
}

contract MockUmaFinder {
    address public mockUmaV2;

    constructor(address _mockUmaV2) {
        mockUmaV2 = _mockUmaV2;
    }

    function getImplementationAddress(bytes32) external view returns (address) {
        return mockUmaV2;
    }
}
