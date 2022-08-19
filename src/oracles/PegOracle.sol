// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

import "@chainlink/interfaces/AggregatorV3Interface.sol";

contract PegOracle {
    /***
    @dev  for example: oracle1 would be stETH / USD, while oracle2 would be ETH / USD oracle
    ***/
    address public oracle1;
    address public oracle2;

    constructor(address _oracle1, address _oracle2) {
        require(_oracle1 != address(0), "oracle1 cannot be the zero address");
        require(_oracle2 != address(0), "oracle2 cannot be the zero address");
        require(_oracle1 != _oracle2, "Cannot be same Oracle");
        // require(AggregatorV3Interface(_oracle1).decimals() == AggregatorV3Interface(_oracle2).decimals(), "Decimals must be same");

        oracle1 = _oracle1;
        oracle2 = _oracle2;
    }

    function latestRoundData()
        public
        view
        returns (
            uint80 roundID,
            int256 nowPrice,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        )
    {
        AggregatorV3Interface priceFeed1 = AggregatorV3Interface(oracle1);
        (
            uint80 roundID1,
            int256 price1,
            uint256 startedAt1,
            uint256 timeStamp1,
            uint80 answeredInRound1
        ) = priceFeed1.latestRoundData();
        // @audit require priceFeed1.decimals() <= 18

        //unifying decimals
        // @audit 10**(18 - priceFeed1.decimals())
        int256 decimals = 10e18 / int256(10**priceFeed1.decimals());

        return (
            roundID1,
            ((price1 * decimals) / (getOracle2_Price() * decimals)) / 10e18,
            startedAt1,
            timeStamp1,
            answeredInRound1
        );
    }

    function getOracle1_Price() public view returns (int256 price) {
        AggregatorV3Interface priceFeed1 = AggregatorV3Interface(oracle1);
        (
            uint80 roundID1,
            int256 price1,
            ,
            uint256 timeStamp1,
            uint80 answeredInRound1
        ) = priceFeed1.latestRoundData();

        require(price1 > 0, "Chainlink price <= 0");
        require(
            answeredInRound1 >= roundID1,
            "RoundID from Oracle is outdated!"
        );
        require(timeStamp1 != 0, "Timestamp == 0 !");

        return price1;
    }

    function getOracle2_Price() public view returns (int256 price) {
        AggregatorV3Interface priceFeed1 = AggregatorV3Interface(oracle2);
        (
            uint80 roundID1,
            int256 price1,
            ,
            uint256 timeStamp1,
            uint80 answeredInRound1
        ) = priceFeed1.latestRoundData();

        require(price1 > 0, "Chainlink price <= 0");
        require(
            answeredInRound1 >= roundID1,
            "RoundID from Oracle is outdated!"
        );
        require(timeStamp1 != 0, "Timestamp == 0 !");

        return price1;
    }
}
