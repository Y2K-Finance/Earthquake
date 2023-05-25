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

    mapping(uint256 => uint256) public marketToCondition;

    event MarketStored(uint256 marketId, uint256 condition);

    constructor(address _factory, address _priceFeed) {
        if (_factory == address(0)) revert ZeroAddress();
        if (_priceFeed == address(0)) revert ZeroAddress();
        vaultFactory = IVaultFactoryV2(_factory);
        priceFeedAdapter = IPriceFeedAdapter(_priceFeed);
    }

    // TODO: Add auth check for ... ?
    function storeMarket(uint256 _marketId, uint256 _condition) public {
        if (_condition == 0 || _condition > 3) revert InvalidInput();
        marketToCondition[_marketId] = _condition;
        emit MarketStored(_marketId, _condition);
    }

    // NOTE: Core logic is querying getValueForDataFeed(bytes32(“VST”)) on RedStoneVSTPriceFeedAdapter
    function getLatestPrice(
        uint256 _marketId
    ) public view virtual returns (int256) {
        (address token, , ) = vaultFactory.getMarketInfo(_marketId);
        // TODO: Need to ensure that the symbol linked to ERC20 works with the data feed
        bytes32 symbol = stringToBytes32(ERC20(token).symbol());
        return int256(priceFeedAdapter.getValueForDataFeed(symbol));
    }

    function conditionMet(
        uint256 _strike,
        uint256 _marketId
    ) public view virtual returns (bool, int256 price) {
        uint256 condition = marketToCondition[_marketId];
        if (condition == 1) {
            price = getLatestPrice(_marketId);
            return (int256(_strike) > price, price);
        } else if (condition == 2) {
            price = getLatestPrice(_marketId);
            return (int256(_strike) < price, price);
        } else if (condition == 3) {
            price = getLatestPrice(_marketId);
            return (int256(_strike) == price, price);
        } else revert ConditionNotSet();
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
}
