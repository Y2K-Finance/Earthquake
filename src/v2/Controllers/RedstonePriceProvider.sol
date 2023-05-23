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
    IPriceFeedAdapter public _priceFeedAdapter;

    mapping(uint256 => bytes32) public marketToSymbol;

    event MarketSymbolStored(address token, uint256 marketId, string symbol);

    constructor(address _factory, address _priceFeed) {
        if (_factory == address(0)) revert ZeroAddress();
        if (_priceFeed == address(0)) revert ZeroAddress();
        vaultFactory = IVaultFactoryV2(_factory);
        _priceFeedAdapter = IPriceFeedAdapter(_priceFeed);
    }

    // NOTE: This needs to be gated with an auth check
    // TODO: Do we need to check if the symbol is set? How likely is it to overwrite?
    function storeSymbol(address _token, uint256 _marketId) public {
        if (marketToSymbol[_marketId] != bytes32(0)) revert SymbolAlreadySet();
        if (_token == address(0)) revert ZeroAddress();

        string memory symbol = ERC20(_token).symbol();
        if (bytes(symbol).length == 0) revert InvalidInput();

        marketToSymbol[_marketId] = stringToBytes32(symbol);
        emit MarketSymbolStored(_token, _marketId, symbol);
    }

    // TODO: Core logic should be to query the getValueForDataFeed(bytes32(“VST”)) on RedStoneVSTPriceFeedAdapter
    function getLatestPrice(
        uint256 _marketId
    ) public view virtual returns (int256) {
        bytes32 symbol = marketToSymbol[_marketId];
        if (symbol == bytes32(0)) revert SymbolNotSet();

        // NOTE: The feed address will support a list of dataFeedIds - in theory if symbol exists then the admin confirms dataFeedId exists
        return int256(_priceFeedAdapter.getValueForDataFeed(symbol));
    }

    // TODO: What if want to check less than or equal to?
    function conditionMet(
        uint256 _strike,
        uint256 _marketId
    ) public view virtual returns (bool) {
        return int256(_strike) > getLatestPrice(_marketId);
    }

    function getLatestRawDecimals(
        address _token
    ) public view virtual returns (uint256) {
        return ERC20(_token).decimals();
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

    error MarketDoesNotExist(uint256 marketId);
    error SequencerDown();
    error GracePeriodNotOver();
    error ZeroAddress();
    error EpochFinishedAlready();
    error PriceNotAtStrikePrice(int256 price);
    error EpochNotStarted();
    error EpochExpired();
    error OraclePriceZero();
    error RoundIDOutdated();
    error EpochNotExist();
    error EpochNotExpired();
    error VaultNotZeroTVL();
    error InvalidInput();
    error SymbolNotSet();
    error SymbolAlreadySet();
    error VaultZeroTVL();
    error FeedAlreadySet();
}
