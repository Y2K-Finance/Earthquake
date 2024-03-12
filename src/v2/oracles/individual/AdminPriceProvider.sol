// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {
    AggregatorV3Interface
} from "@chainlink/interfaces/AggregatorV3Interface.sol";
import {
    AggregatorV2V3Interface
} from "@chainlink/interfaces/AggregatorV2V3Interface.sol";
import {IVaultFactoryV2} from "../../interfaces/IVaultFactoryV2.sol";
import {IConditionProvider} from "../../interfaces/IConditionProvider.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract AdminPriceProvider is Ownable, IConditionProvider {
    uint16 private constant _GRACE_PERIOD_TIME = 3600;
    uint256 public immutable timeOut;
    IVaultFactoryV2 public immutable vaultFactory;
    uint256 public immutable decimals;
    string public description;
    uint256 public assetPrice;

    event AssetPriceSet(uint256 price);

    constructor(
        address _factory,
        uint256 _timeOut,
        uint256 _decimals,
        string memory _description
    ) {
        if (_factory == address(0)) revert ZeroAddress();
        if (_timeOut == 0) revert InvalidInput();
        vaultFactory = IVaultFactoryV2(_factory);
        timeOut = _timeOut;
        decimals = _decimals;
        description = _description;
    }

    /*//////////////////////////////////////////////////////////////
                                 ADMIN
    //////////////////////////////////////////////////////////////*/
    function setPrice(uint256 _price) external onlyOwner {
        if (_price == 0) revert InvalidInput();
        assetPrice = _price;
        emit AssetPriceSet(_price);
    }

    /*//////////////////////////////////////////////////////////////
                                 PUBLIC
    //////////////////////////////////////////////////////////////*/
    function latestRoundData()
        public
        view
        returns (
            uint80 roundId,
            int256 price,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        roundId = 0;
        price = int256(assetPrice);
        startedAt = block.timestamp;
        updatedAt = block.timestamp;
        answeredInRound = 0;
    }

    /** @notice Fetch token price from priceFeed (Chainlink oracle address)
     * @return int256 Current token price
     */
    function getLatestPrice() public view returns (int256) {
        (
            uint80 roundID,
            int256 price,
            ,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = latestRoundData();
        if (price <= 0) revert OraclePriceZero();
        if (answeredInRound < roundID) revert RoundIdOutdated();
        if ((block.timestamp - updatedAt) > timeOut) revert PriceTimedOut();

        if (decimals < 18) {
            uint256 calcDecimals = 10 ** (18 - (decimals));
            price = price * int256(calcDecimals);
        } else if (decimals > 18) {
            uint256 calcDecimals = 10 ** ((decimals - 18));
            price = price / int256(calcDecimals);
        }

        return price;
    }

    /** @notice Fetch price and return condition
     * @param _strike Strike price
     * @return boolean If condition is met i.e. strike > price
     * @return price Current price for token
     */
    function conditionMet(
        uint256 _strike,
        uint256 /* _marketId */
    ) public view virtual returns (bool, int256 price) {
        uint256 conditionType = _strike % 2 ** 1;

        price = getLatestPrice();
        if (conditionType == 1) return (int256(_strike) < price, price);
        else if (conditionType == 0) return (int256(_strike) > price, price);
        else revert ConditionTypeNotSet();
    }

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error OraclePriceZero();
    error RoundIdOutdated();
    error ZeroAddress();
    error PriceTimedOut();
    error InvalidInput();
    error ConditionTypeNotSet();
}
