/******************************************************* 
NOTE: Development in progress by JG. Reached functional milestone; Live VST data is accessible. 
***/
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IUniversalProvider} from "../../interfaces/IUniversalProvider.sol";
import {IDIAPriceFeed} from "../../interfaces/IDIAPriceFeed.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract DIAUniversalProvider is Ownable, IUniversalProvider {
    IDIAPriceFeed public diaPriceFeed;

    mapping(uint256 => uint256) public marketIdToConditionType;
    mapping(uint256 => string) public marketIdToDescription;
    mapping(uint256 => uint256) public marketIdToDecimals;

    event MarketConditionSet(
        uint256 indexed marketId,
        uint256 indexed conditionType
    );
    event PriceFeedSet(
        uint256 indexed marketId,
        string indexed priceFeed,
        uint256 indexed decimals
    );

    constructor(address _priceFeed) {
        if (_priceFeed == address(0)) revert ZeroAddress();
        diaPriceFeed = IDIAPriceFeed(_priceFeed);
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
        string memory _description,
        uint256 _decimals
    ) external onlyOwner {
        if (marketIdToDecimals[_marketId] != 0) revert FeedAlreadySet();
        if (keccak256(abi.encode(_description)) == keccak256(abi.encode("")))
            revert InvalidInput();

        marketIdToDescription[_marketId] = _description;
        marketIdToDecimals[_marketId] = _decimals;
        emit PriceFeedSet(_marketId, _description, _decimals);
    }

    /*//////////////////////////////////////////////////////////////
                                 PUBLIC
    //////////////////////////////////////////////////////////////*/
    function decimals(uint256 _marketId) public view returns (uint256) {
        return marketIdToDecimals[_marketId];
    }

    function description(
        uint256 _marketId
    ) public view returns (string memory) {
        return marketIdToDescription[_marketId];
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
        (price, updatedAt) = _getLatestPrice(_marketId);
        startedAt = 1;
        roundId = 1;
        answeredInRound = 1;
    }

    /** @notice Fetch token price from priceFeedAdapter (Using string name)
     * @return price Current token price
     */
    function getLatestPrice(
        uint256 _marketId
    ) public view override returns (int256 price) {
        (price, ) = _getLatestPrice(_marketId);
    }

    /** @notice Fetch price and return condition
     * @dev The strike is hashed as an int256 to enable comparison vs. price for earthquake
        and conditional check vs. strike to ensure vaidity
     * @param _strike Strike price
     * @param _marketId Market ID
     * @return condition boolean If condition is met i.e. strike > price
     * @return price current price for token
     */
    function conditionMet(
        uint256 _strike,
        uint256 _marketId
    ) public view virtual returns (bool condition, int256 price) {
        uint256 conditionType = marketIdToConditionType[_marketId];
        (price, ) = _getLatestPrice(_marketId);

        if (conditionType == 1) return (int256(_strike) < price, price);
        else if (conditionType == 2) return (int256(_strike) > price, price);
        else revert ConditionTypeNotSet();
    }

    /*//////////////////////////////////////////////////////////////
                                 INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _getLatestPrice(
        uint256 _marketId
    ) private view returns (int256 price, uint256 timestamp) {
        uint256 uintPrice;
        string memory feedDescription = marketIdToDescription[_marketId];
        if (keccak256(abi.encodePacked(feedDescription)) == keccak256(""))
            revert DescriptionNotSet();
        (uintPrice, timestamp) = diaPriceFeed.getValue(feedDescription);
        price = int256(uintPrice);
        if (price == 0) revert OraclePriceZero();

        uint256 feedDecimals = decimals(_marketId);
        if (feedDecimals < 18) {
            uint256 calcDecimals = 10 ** (18 - (feedDecimals));
            price = price * int256(calcDecimals);
        } else if (feedDecimals > 18) {
            uint256 calcDecimals = 10 ** ((feedDecimals - 18));
            price = price / int256(calcDecimals);
        }
    }

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error ZeroAddress();
    error InvalidInput();
    error ConditionTypeNotSet();
    error ConditionTypeSet();
    error FeedAlreadySet();
    error DescriptionNotSet();
    error OraclePriceZero();
}
