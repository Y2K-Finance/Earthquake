// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

import "@chainlink/interfaces/AggregatorV3Interface.sol";

/// @author MiguelBits
/// @author NexusFlip

contract DepegOracle {

    address public oracle;
    AggregatorV3Interface public priceFeed;

    uint8 public decimals = 18;
    int256 public priceSimulation;
    address public admin;

    constructor (address _oracle, address _admin) {
        require(_oracle != address(0), "oracle cannot be the zero address");

        oracle = _oracle;
        priceFeed = AggregatorV3Interface(_oracle);
        admin = _admin;
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

        if(priceSimulation == 0)
            return (roundID, nowPrice1, 0, timeStamp, answeredInRound);
        else
            return (roundID, priceSimulation, 0, timeStamp, answeredInRound);
    }

    function setPriceSimulation(int256 _priceSimulation) public {
        require(msg.sender == admin, "only admin can set price simulation");
        priceSimulation = _priceSimulation;
    }
}
