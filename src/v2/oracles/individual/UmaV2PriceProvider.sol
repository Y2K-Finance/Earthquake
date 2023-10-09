// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IVaultFactoryV2} from "../../interfaces/IVaultFactoryV2.sol";
import {IUmaV2} from "../../interfaces/IUmaV2.sol";
import {IFinder} from "../../interfaces/IFinder.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract UmaV2PriceProvider is Ownable {
    struct PriceAnswer {
        uint80 roundId;
        int256 price;
        uint256 startedAt;
        uint256 updatedAt;
        uint80 answeredInRound;
    }

    uint256 public constant ORACLE_LIVENESS_TIME = 3600 * 2;
    bytes32 public constant PRICE_IDENTIFIER = "TOKEN_PRICE";

    uint256 public immutable timeOut;
    IVaultFactoryV2 public immutable vaultFactory;
    IUmaV2 public immutable oo;
    IFinder public immutable finder;
    uint256 public immutable decimals;
    IERC20 public immutable currency;

    string public description;
    string public ancillaryData;
    PriceAnswer public answer;
    PriceAnswer public pendingAnswer;
    uint256 public requiredBond;

    mapping(uint256 => uint256) public marketIdToConditionType;

    event MarketConditionSet(uint256 indexed marketId, uint256 conditionType);
    event BondUpdated(uint256 newBond);
    event PriceSettled(int256 price);
    event PriceRequested();

    constructor(
        address _factory,
        uint256 _timeOut,
        uint256 _decimals,
        string memory _description,
        address _finder,
        address _currency,
        string memory _ancillaryData,
        uint256 _requiredBond
    ) {
        if (_factory == address(0)) revert ZeroAddress();
        if (_timeOut == 0) revert InvalidInput();
        if (keccak256(bytes(_description)) == keccak256(""))
            revert InvalidInput();
        if (_finder == address(0)) revert ZeroAddress();
        if (_currency == address(0)) revert ZeroAddress();
        if (keccak256(bytes(_ancillaryData)) == keccak256(""))
            revert InvalidInput();
        if (_requiredBond == 0) revert InvalidInput();

        vaultFactory = IVaultFactoryV2(_factory);
        timeOut = _timeOut;
        decimals = _decimals;
        description = _description;

        finder = IFinder(_finder);
        oo = IUmaV2(finder.getImplementationAddress("OptimisticOracleV2"));
        currency = IERC20(_currency);
        ancillaryData = _ancillaryData;
        requiredBond = _requiredBond;
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

    function updateRequiredBond(uint256 newBond) external onlyOwner {
        if (newBond == 0) revert InvalidInput();
        requiredBond = newBond;
        emit BondUpdated(newBond);
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

        PriceAnswer memory _pendingAnswer = pendingAnswer;
        PriceAnswer memory _answer = answer;

        _answer.startedAt = _pendingAnswer.startedAt;
        _answer.updatedAt = _timestamp;
        _answer.price = _price;
        _answer.roundId = 1;
        _answer.answeredInRound = 1;
        answer = _answer;

        emit PriceSettled(_price);
    }

    /*//////////////////////////////////////////////////////////////
                                 PUBLIC
    //////////////////////////////////////////////////////////////*/
    function requestLatestPrice() external {
        if (pendingAnswer.startedAt != 0) revert RequestInProgress();

        bytes memory _bytesAncillary = abi.encodePacked(ancillaryData);
        oo.requestPrice(
            PRICE_IDENTIFIER,
            block.timestamp,
            _bytesAncillary,
            currency,
            0
        );
        oo.setBond(
            PRICE_IDENTIFIER,
            block.timestamp,
            _bytesAncillary,
            requiredBond
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

        PriceAnswer memory _pendingAnswer;
        _pendingAnswer.startedAt = block.timestamp;
        pendingAnswer = _pendingAnswer;

        emit PriceRequested();
    }

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
        PriceAnswer memory _answer = answer;
        price = _answer.price;
        updatedAt = _answer.updatedAt;
        roundId = _answer.roundId;
        startedAt = _answer.startedAt;
        answeredInRound = _answer.answeredInRound;
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
