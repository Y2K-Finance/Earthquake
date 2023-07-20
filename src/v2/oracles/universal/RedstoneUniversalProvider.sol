// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IVaultFactoryV2} from "../../interfaces/IVaultFactoryV2.sol";
import {IUniversalProvider} from "../../interfaces/IUniversalProvider.sol";
import {IPriceFeedAdapter} from "../../interfaces/IPriceFeedAdapter.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract RedstoneUniversalProvider is Ownable, IUniversalProvider {
    uint256 public immutable timeOut;
    IVaultFactoryV2 public immutable vaultFactory;

    mapping(uint256 => uint256) public marketIdToConditionType;
    mapping(uint256 => IPriceFeedAdapter) public marketIdToPriceFeed;

    event MarketConditionSet(
        uint256 indexed marketId,
        uint256 indexed conditionType
    );
    event PriceFeedSet(uint256 indexed marketId, address indexed priceFeed);

    constructor(address _factory, uint256 _timeOut) {
        if (_factory == address(0)) revert ZeroAddress();
        if (_timeOut == 0) revert InvalidInput();
        vaultFactory = IVaultFactoryV2(_factory);
        timeOut = _timeOut;
    }

    /*//////////////////////////////////////////////////////////////
                                 ADMIN
    //////////////////////////////////////////////////////////////*/
    function setConditionType(
        uint256 _marketId,
        uint256 _condition
    ) external onlyOwner {
        if (marketIdToConditionType[_marketId] != 0) revert ConditionTypeSet();
        if (_condition != 1 && _condition != 2) revert InvalidInput();
        marketIdToConditionType[_marketId] = _condition;
        emit MarketConditionSet(_marketId, _condition);
    }

    function setPriceFeed(
        uint256 _marketId,
        address priceFeed
    ) external onlyOwner {
        if (priceFeed == address(0)) revert InvalidInput();
        marketIdToPriceFeed[_marketId] = IPriceFeedAdapter(priceFeed);
        emit PriceFeedSet(_marketId, priceFeed);
    }

    /*//////////////////////////////////////////////////////////////
                                 PUBLIC
    //////////////////////////////////////////////////////////////*/
    function decimals(uint256 _marketId) public view returns (uint256) {
        return marketIdToPriceFeed[_marketId].decimals();
    }

    function description(
        uint256 _marketId
    ) public view returns (string memory) {
        return
            string(
                abi.encodePacked(marketIdToPriceFeed[_marketId].getDataFeedId())
            );
    }

    function latestRoundData(
        uint256 _marketId
    )
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
        IPriceFeedAdapter priceFeedAdapter = IPriceFeedAdapter(
            marketIdToPriceFeed[_marketId]
        );
        if (address(priceFeedAdapter) == address(0)) revert ZeroAddress();
        (
            roundId,
            price,
            startedAt,
            updatedAt,
            answeredInRound
        ) = priceFeedAdapter.latestRoundData();
    }

    /** @notice Fetch token price from priceFeedAdapter (Redston oracle address)
     * @return int256 Current token price
     */
    function getLatestPrice(
        uint256 _marketId
    ) public view virtual returns (int256) {
        (
            uint80 roundId,
            int256 price,
            ,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = latestRoundData(_marketId);
        if (price <= 0) revert OraclePriceZero();
        if (answeredInRound < roundId) revert RoundIdOutdated();
        if ((block.timestamp - updatedAt) > timeOut) revert PriceTimedOut();

        uint256 feedDecimals = decimals(_marketId);
        if (feedDecimals < 18) {
            uint256 calcDecimals = 10 ** (18 - (feedDecimals));
            price = price * int256(calcDecimals);
        } else if (feedDecimals > 18) {
            uint256 calcDecimals = 10 ** ((feedDecimals - 18));
            price = price / int256(calcDecimals);
        }

        return price;
    }

    // NOTE: _marketId unused but receiving marketId makes Generic controller composabile for future
    /** @notice Fetch price and return condition
     * @param _strike Strike price
     * @return boolean If condition is met i.e. strike > price
     * @return price Current price for token
     */
    function conditionMet(
        uint256 _strike,
        uint256 _marketId
    ) public view virtual returns (bool, int256 price) {
        uint256 conditionType = marketIdToConditionType[_marketId];
        price = getLatestPrice(_marketId);

        if (conditionType == 1) return (int256(_strike) < price, price);
        else if (conditionType == 2) return (int256(_strike) > price, price);
        else revert ConditionTypeNotSet();
    }

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error ZeroAddress();
    error InvalidInput();
    error OraclePriceZero();
    error RoundIdOutdated();
    error PriceTimedOut();
    error ConditionTypeNotSet();
    error ConditionTypeSet();
}
