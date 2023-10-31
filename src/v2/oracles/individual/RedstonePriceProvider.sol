// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IVaultFactoryV2} from "../../interfaces/IVaultFactoryV2.sol";
import {IConditionProvider} from "../../interfaces/IConditionProvider.sol";
import {IPriceFeedAdapter} from "../../interfaces/IPriceFeedAdapter.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract RedstonePriceProvider is Ownable, IConditionProvider {
    uint256 public immutable timeOut;
    IVaultFactoryV2 public immutable vaultFactory;
    IPriceFeedAdapter public priceFeedAdapter;
    bytes32 public immutable dataFeedId;
    uint256 public immutable decimals;
    string public description;

    event MarketConditionSet(uint256 indexed marketId, uint256 conditionType);

    constructor(
        address _factory,
        address _priceFeed,
        string memory _dataFeedSymbol,
        uint256 _timeOut
    ) {
        if (_factory == address(0)) revert ZeroAddress();
        if (_priceFeed == address(0)) revert ZeroAddress();
        if (keccak256(bytes(_dataFeedSymbol)) == keccak256(bytes(string(""))))
            revert InvalidInput();
        if (_timeOut == 0) revert InvalidInput();
        vaultFactory = IVaultFactoryV2(_factory);
        priceFeedAdapter = IPriceFeedAdapter(_priceFeed);
        description = _dataFeedSymbol;
        dataFeedId = stringToBytes32(_dataFeedSymbol);
        timeOut = _timeOut;
        decimals = priceFeedAdapter.decimals();
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
    function getLatestPrice() public view virtual returns (int256) {
        (
            uint80 roundId,
            int256 price,
            ,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = latestRoundData();
        if (price <= 0) revert OraclePriceZero();
        if (answeredInRound < roundId) revert RoundIdOutdated();
        // TODO: What is a suitable timeframe to set timeout as based on this info? Update at always timestamp?
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

    // NOTE: _marketId unused but receiving marketId makes Generic controller composabile for future
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
        if (conditionType == 1) _strike -= 1;

        price = getLatestPrice();
        if (conditionType == 1) return (int256(_strike) < price, price);
        else if (conditionType == 0) return (int256(_strike) > price, price);
        else revert ConditionTypeNotSet();
    }

    /** @notice Convert string to bytes32
     * @param _symbol Symbol for token
     * @return result Bytes32 representation of string
     */
    function stringToBytes32(
        string memory _symbol
    ) public pure returns (bytes32 result) {
        if (bytes(_symbol).length > 32) revert InvalidInput();
        assembly {
            result := mload(add(_symbol, 32))
        }
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
