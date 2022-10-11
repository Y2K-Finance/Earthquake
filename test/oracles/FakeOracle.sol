// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

import "@chainlink/interfaces/AggregatorV3Interface.sol";

/// @author MiguelBits
/// @author NexusFlip

contract FakeOracle {

    address public oracle;
    AggregatorV3Interface public priceFeed;

    uint8 public decimals;
    int256 public priceSimulation;

    constructor (address _oracle, int256 _priceSimulation) {
        require(_oracle != address(0), "oracle cannot be the zero address");
        oracle = _oracle;
        priceFeed = AggregatorV3Interface(_oracle);

        priceSimulation = _priceSimulation;
        decimals = priceFeed.decimals();

    }

    function latestRoundData()
        public
        view
        returns (
            uint80 roundID1,
            int256 nowPrice1,
            uint256 startedAt1,
            uint256 timeStamp1,
            uint80 answeredInRound1
        )
    {
        (
            uint80 roundID,
            ,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();

        return (roundID, priceSimulation, startedAt, timeStamp, answeredInRound);
    }
}