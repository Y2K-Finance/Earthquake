// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

import "@chainlink/interfaces/AggregatorV3Interface.sol";

contract PegOracle {
    /***
    @dev  for example: oracle1 would be stETH / USD, while oracle2 would be ETH / USD oracle
    ***/
    address public oracle1;
    address public oracle2;

    uint8 public decimals;

    AggregatorV3Interface internal priceFeed1;
    AggregatorV3Interface internal priceFeed2;

    /** @notice Contract constructor
      * @param _oracle1 First oracle address
      * @param _oracle2 Second oracle address
      */
    constructor(address _oracle1, address _oracle2) {
        require(_oracle1 != address(0), "oracle1 cannot be the zero address");
        require(_oracle2 != address(0), "oracle2 cannot be the zero address");
        require(_oracle1 != _oracle2, "Cannot be same Oracle");
        priceFeed1 = AggregatorV3Interface(_oracle1);
        priceFeed2 = AggregatorV3Interface(_oracle2);
        require(
            (priceFeed1.decimals() == priceFeed2.decimals()),
            "Decimals must be the same"
        );

        oracle1 = _oracle1;
        oracle2 = _oracle2;

        decimals = priceFeed1.decimals();
    }

    /** @notice Returns oracle-fed data from the latest round
      * @return roundID Current round id 
      * @return nowPrice Current price
      * @return startedAt Starting timestamp
      * @return timeStamp Current timestamp
      * @return answeredInRound Round id for which answer was computed 
      */ 
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
        (
            uint80 roundID1,
            int256 price1,
            uint256 startedAt1,
            uint256 timeStamp1,
            uint80 answeredInRound1
        ) = priceFeed1.latestRoundData();

        int256 price2 = getOracle2_Price();

        if (price1 > price2) {
            nowPrice = (price2 * 10000) / price1;
        } else {
            nowPrice = (price1 * 10000) / price2;
        }

        int256 decimals10 = int256(10**(18 - priceFeed1.decimals()));
        nowPrice = nowPrice * decimals10;

        return (
            roundID1,
            nowPrice / 1000000,
            startedAt1,
            timeStamp1,
            answeredInRound1
        );
    }

    /* solhint-disbable-next-line func-name-mixedcase */
    /** @notice Lookup first oracle price
      * @return price Current first oracle price
      */ 
    function getOracle1_Price() public view returns (int256 price) {
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

    /* solhint-disbable-next-line func-name-mixedcase */
    /** @notice Lookup second oracle price
      * @return price Current second oracle price
      */ 
    function getOracle2_Price() public view returns (int256 price) {
        (
            uint80 roundID2,
            int256 price2,
            ,
            uint256 timeStamp2,
            uint80 answeredInRound2
        ) = priceFeed2.latestRoundData();

        require(price2 > 0, "Chainlink price <= 0");
        require(
            answeredInRound2 >= roundID2,
            "RoundID from Oracle is outdated!"
        );
        require(timeStamp2 != 0, "Timestamp == 0 !");

        return price2;
    }
}
