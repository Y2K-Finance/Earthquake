// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

import "@chainlink/interfaces/AggregatorV3Interface.sol";

contract DepegOracle {

    address public oracle;
    AggregatorV3Interface public priceFeed;

    uint8 public decimals = 18;
    int256 public priceSimulation;

    constructor (address _oracle, int256 _priceSimulation) {
        require(_oracle != address(0), "oracle cannot be the zero address");
        require(AggregatorV3Interface(_oracle).decimals() <= 18, "Decimals must be less or equal to 18");
        require(_priceSimulation < 100, "_priceSimulation must be less than 100");
        require(_priceSimulation > 10, "_priceSimulation must be greater than 10");
        oracle = _oracle;
        priceFeed = AggregatorV3Interface(_oracle);
        priceSimulation = _priceSimulation;
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
            ,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();

        nowPrice1 = priceSimulation * int256(10e16);

        return (roundID, nowPrice1, 0, timeStamp, answeredInRound);
    }
}