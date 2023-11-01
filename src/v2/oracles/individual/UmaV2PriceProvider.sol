// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IUmaV2} from "../../interfaces/IUmaV2.sol";
import {IFinder} from "../../interfaces/IFinder.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
    @notice The definition information the Uma TOKEN_PRICE is as follows.
        Price returned and the params required are:
            base: collateral token symbol to be priced
            baseAddress: base token deployment address on Ethereum or other chain if provided
            baseChain (optional): chainId
            quote: quote token symbol to be priced
            rounding: defines how many digits should remain to the right of decimals
            fallback: data endpoint to user as fallback either for the whole base/quote or part of it
            configuration: price feed config formatted as JSON that can be used to construct price feed
 */
contract UmaV2PriceProvider is Ownable {
    struct PriceAnswer {
        uint128 roundId;
        uint128 answeredInRound;
        int128 price;
        uint128 updatedAt;
        uint256 pendingRequestAt;
    }

    uint256 public constant ORACLE_LIVENESS_TIME = 3600 * 2;
    bytes32 public constant PRICE_IDENTIFIER = "TOKEN_PRICE";
    uint256 public constant REQUEST_TIMEOUT = 3600 * 3;

    uint256 public immutable timeOut;
    IUmaV2 public immutable oo;
    IFinder public immutable finder;
    uint256 public immutable decimals;
    IERC20 public immutable currency;

    PriceAnswer public answer;
    uint256 public reward;
    string public description;
    string public ancillaryData;

    mapping(uint256 => uint256) public marketIdToConditionType;

    event MarketConditionSet(uint256 indexed marketId, uint256 conditionType);
    event RewardUpdated(uint256 newReward);
    event PriceSettled(int256 price);
    event PriceRequested();

    constructor(
        uint256 _timeOut,
        uint256 _decimals,
        string memory _description,
        address _finder,
        address _currency,
        string memory _ancillaryData,
        uint256 _reward
    ) {
        if (_timeOut == 0) revert InvalidInput();
        if (keccak256(bytes(_description)) == keccak256(""))
            revert InvalidInput();
        if (_finder == address(0)) revert ZeroAddress();
        if (_currency == address(0)) revert ZeroAddress();
        if (keccak256(bytes(_ancillaryData)) == keccak256(""))
            revert InvalidInput();
        if (_reward == 0) revert InvalidInput();

        timeOut = _timeOut;
        decimals = _decimals;
        description = _description;

        finder = IFinder(_finder);
        oo = IUmaV2(finder.getImplementationAddress("OptimisticOracleV2"));
        currency = IERC20(_currency);
        ancillaryData = _ancillaryData;
        reward = _reward;
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

    function updateReward(uint256 newReward) external onlyOwner {
        if (newReward == 0) revert InvalidInput();
        reward = newReward;
        emit RewardUpdated(newReward);
    }

    /*//////////////////////////////////////////////////////////////
                                 CALLBACK
    //////////////////////////////////////////////////////////////*/
    function priceSettled(
        bytes32,
        uint256 _timestamp,
        bytes memory,
        int256 _price
    ) external {
        if (msg.sender != address(oo)) revert InvalidCaller();

        PriceAnswer memory _answer;
        _answer.updatedAt = uint128(_timestamp);
        _answer.price = int128(_price);
        _answer.roundId = answer.roundId + 1;
        _answer.answeredInRound = answer.answeredInRound + 1;
        _answer.pendingRequestAt = answer.pendingRequestAt;
        answer = _answer;

        emit PriceSettled(_price);
    }

    /*//////////////////////////////////////////////////////////////
                                 PUBLIC
    //////////////////////////////////////////////////////////////*/
    function requestLatestPrice() external {
        if (answer.pendingRequestAt + REQUEST_TIMEOUT > block.timestamp)
            revert RequestInProgress();

        bytes memory _bytesAncillary = abi.encodePacked(ancillaryData);
        currency.transferFrom(msg.sender, address(this), reward);
        currency.approve(address(oo), reward);
        oo.requestPrice(
            PRICE_IDENTIFIER,
            block.timestamp,
            _bytesAncillary,
            currency,
            reward
        );
        oo.setCustomLiveness(
            PRICE_IDENTIFIER,
            block.timestamp,
            _bytesAncillary,
            ORACLE_LIVENESS_TIME
        );
        oo.setCallbacks(
            PRICE_IDENTIFIER,
            block.timestamp,
            _bytesAncillary,
            false,
            false,
            true
        );

        answer.pendingRequestAt = block.timestamp;

        emit PriceRequested();
    }

    function latestRoundData()
        public
        view
        returns (
            uint80 roundId,
            int256 price,
            uint256 pendingRequestAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        PriceAnswer memory _answer = answer;
        roundId = uint80(_answer.roundId);
        price = _answer.price;
        updatedAt = _answer.updatedAt;
        pendingRequestAt = _answer.pendingRequestAt;
        answeredInRound = uint80(_answer.answeredInRound);
    }

    /** @notice Fetch token price from priceFeed (Chainlink oracle address)
     * @return int256 Current token price
     */
    function getLatestPrice() public view returns (int256) {
        (, int256 price, , uint256 updatedAt, ) = latestRoundData();
        if (price <= 0) revert OraclePriceZero();
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
     * @param _marketId Market id
     * @return boolean If condition is met i.e. strike > price
     * @return price Current price for token
     */
    function conditionMet(
        uint256 _strike,
        uint256 _marketId
    ) public view virtual returns (bool, int256 price) {
        uint256 conditionType = marketIdToConditionType[_marketId];
        price = getLatestPrice();
        if (conditionType == 1) return (int256(_strike) < price, price);
        else if (conditionType == 2) return (int256(_strike) > price, price);
        else revert ConditionTypeNotSet();
    }

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error OraclePriceZero();
    error ZeroAddress();
    error PriceTimedOut();
    error InvalidInput();
    error ConditionTypeNotSet();
    error ConditionTypeSet();
    error InvalidCaller();
    error RequestInProgress();
}
