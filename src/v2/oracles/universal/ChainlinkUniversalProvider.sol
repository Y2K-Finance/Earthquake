// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {
    AggregatorV3Interface
} from "@chainlink/interfaces/AggregatorV3Interface.sol";
import {
    AggregatorV2V3Interface
} from "@chainlink/interfaces/AggregatorV2V3Interface.sol";
import {IVaultFactoryV2} from "../../interfaces/IVaultFactoryV2.sol";
import {IUniversalProvider} from "../../interfaces/IUniversalProvider.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ChainlinkUniversalProvider is Ownable, IUniversalProvider {
    uint16 private constant _GRACE_PERIOD_TIME = 3600;
    uint256 public immutable timeOut;
    IVaultFactoryV2 public immutable vaultFactory;
    AggregatorV2V3Interface public immutable sequencerUptimeFeed;

    mapping(uint256 => uint256) public marketIdToConditionType;
    mapping(uint256 => AggregatorV3Interface) public marketIdToPriceFeed;

    event MarketConditionSet(
        uint256 indexed marketId,
        uint256 indexed conditionType
    );
    event PriceFeedSet(uint256 indexed marketId, address indexed priceFeed);

    constructor(address _sequencer, address _factory, uint256 _timeOut) {
        if (_factory == address(0)) revert ZeroAddress();
        if (_sequencer == address(0)) revert ZeroAddress();
        if (_timeOut == 0) revert InvalidInput();
        vaultFactory = IVaultFactoryV2(_factory);
        sequencerUptimeFeed = AggregatorV2V3Interface(_sequencer);
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
        if (priceFeed == address(0)) revert ZeroAddress();
        marketIdToPriceFeed[_marketId] = AggregatorV3Interface(priceFeed);
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
        return marketIdToPriceFeed[_marketId].description();
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
        AggregatorV3Interface priceFeed = marketIdToPriceFeed[_marketId];
        if (address(priceFeed) == address(0)) revert ZeroAddress();
        (roundId, price, startedAt, updatedAt, answeredInRound) = priceFeed
            .latestRoundData();
    }

    /** @notice Fetch token price from priceFeed (Chainlink oracle address)
     * @return int256 Current token price
     */
    function getLatestPrice(uint256 _marketId) public view returns (int256) {
        (, int256 answer, uint256 startedAt, , ) = sequencerUptimeFeed
            .latestRoundData();

        // Answer == 0: Sequencer is up || Answer == 1: Sequencer is down
        if (!(answer == 0)) {
            revert SequencerDown();
        }

        // Make sure the grace period has passed after the sequencer is back up - timeSinceUp <= PERIOD
        if ((block.timestamp - startedAt) <= _GRACE_PERIOD_TIME) {
            revert GracePeriodNotOver();
        }

        (
            uint80 roundID,
            int256 price,
            ,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = latestRoundData(_marketId);
        if (price <= 0) revert OraclePriceZero();
        if (answeredInRound < roundID) revert RoundIdOutdated();
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

    /** @notice Fetch price and return condition
     * @param _strike Strike price
     * @param _marketId Market id
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
    error SequencerDown();
    error GracePeriodNotOver();
    error OraclePriceZero();
    error RoundIdOutdated();
    error ZeroAddress();
    error PriceTimedOut();
    error InvalidInput();
    error ConditionTypeNotSet();
    error ConditionTypeSet();
}
