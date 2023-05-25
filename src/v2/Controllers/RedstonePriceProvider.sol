/******************************************************* 
NOTE: Development in progress by JG. Reached functional milestone; Live VST data is accessible. 
***/
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {
    AggregatorV3Interface
} from "@chainlink/interfaces/AggregatorV3Interface.sol";
import {
    AggregatorV2V3Interface
} from "@chainlink/interfaces/AggregatorV2V3Interface.sol";
import {
    RapidDemoConsumerBase
} from "@redstone-finance/evm-connector/contracts/data-services/RapidDemoConsumerBase.sol";

import {IVaultFactoryV2} from "../interfaces/IVaultFactoryV2.sol";
import {IVaultV2} from "../interfaces/IVaultV2.sol";
import {IConditionProvider} from "./IConditionProvider.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IPriceFeedAdapter} from "../interfaces/IPriceFeedAdapter.sol";

contract RedstonePriceProvider is IConditionProvider {
    IVaultFactoryV2 public immutable vaultFactory;
    IPriceFeedAdapter public priceFeedAdapter;
    bytes32 public immutable dataFeedId;
    string public symbol;

    constructor(
        address _factory,
        address _priceFeed,
        string memory _dataFeedSymbol
    ) {
        if (_factory == address(0)) revert ZeroAddress();
        if (_priceFeed == address(0)) revert ZeroAddress();
        // TODO: compare gas of abi.encodePacked vs. bytes32
        if (
            keccak256(abi.encodePacked(_dataFeedSymbol)) ==
            keccak256(abi.encodePacked(string("")))
        ) revert InvalidInput();
        vaultFactory = IVaultFactoryV2(_factory);
        priceFeedAdapter = IPriceFeedAdapter(_priceFeed);
        symbol = _dataFeedSymbol;
        dataFeedId = stringToBytes32(_dataFeedSymbol);
    }

    // NOTE: Core logic is querying getValueForDataFeed(bytes32(“VST”)) on RedStoneVSTPriceFeedAdapter
    function getLatestPrice(
        uint256 marketId
    ) public view virtual returns (int256) {
        (
            uint80 roundId,
            int256 price,
            ,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = priceFeedAdapter.latestRoundData();
        if (price <= 0) revert OraclePriceZero();
        // TODO: What instances are there where the Id doesn't match?
        if (answeredInRound < roundId) revert RoundIdOutdated();
        // TODO: How should we check the update for the timestamp

        return price;
    }

    // NOTE: The _marketId isn't used but using this in controller would allow composability in future contracts
    function conditionMet(
        uint256 _strike,
        uint256 _marketId
    ) public view virtual returns (bool, int256 price) {
        price = getLatestPrice(_marketId);
        return (int256(_strike) > price, price);
    }

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
    error SymbolNotSet();
    error SymbolAlreadySet();
    error ConditionNotSet();
    error ConditionAlreadySet();
    error FeedAlreadySet();
    error OraclePriceZero();
    error RoundIdOutdated();
}
