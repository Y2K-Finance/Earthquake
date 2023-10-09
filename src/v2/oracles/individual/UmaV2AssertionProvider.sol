// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IVaultFactoryV2} from "../../interfaces/IVaultFactoryV2.sol";
import {IUmaV2} from "../../interfaces/IUmaV2.sol";
import {IFinder} from "../../interfaces/IFinder.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract UmaV2AssertionProvider is Ownable {
    struct AssertionAnswer {
        uint80 roundId;
        int256 assertion;
        uint256 startedAt;
        uint256 updatedAt;
        uint80 answeredInRound;
    }

    uint256 public constant ORACLE_LIVENESS_TIME = 3600 * 2;
    bytes32 public constant PRICE_IDENTIFIER = "YES_OR_NO_QUERY";
    string public constant ANCILLARY_TAIL = "A:1 for YES, B:2 for NO";

    uint256 public immutable timeOut;
    IVaultFactoryV2 public immutable vaultFactory;
    IUmaV2 public immutable oo;
    IFinder public immutable finder;
    IERC20 public immutable currency;

    string public description;
    string public ancillaryData;
    AssertionAnswer public answer;
    AssertionAnswer public pendingAnswer;
    uint256 public requiredBond;
    uint256 public coverageStart;

    mapping(uint256 => uint256) public marketIdToConditionType;

    event MarketConditionSet(uint256 indexed marketId, uint256 conditionType);
    event CoverageStartUpdated(uint256 startTime);
    event BondUpdated(uint256 newBond);
    event PriceSettled(int256 price);
    event PriceRequested();

    constructor(
        address _factory,
        uint256 _timeOut,
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
        description = _description;

        finder = IFinder(_finder);
        oo = IUmaV2(finder.getImplementationAddress("OptimisticOracleV2"));
        currency = IERC20(_currency);
        ancillaryData = _ancillaryData;
        requiredBond = _requiredBond;
        coverageStart = block.timestamp;
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

    function updateCoverageStart(uint256 _coverageStart) external onlyOwner {
        if (_coverageStart < coverageStart) revert InvalidInput();
        coverageStart = _coverageStart;
        emit CoverageStartUpdated(_coverageStart);
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

        AssertionAnswer memory _pendingAnswer = pendingAnswer;
        AssertionAnswer memory _answer = answer;

        _answer.startedAt = _pendingAnswer.startedAt;
        _answer.updatedAt = _timestamp;
        _answer.assertion = _price;
        _answer.roundId = 1;
        _answer.answeredInRound = 1;
        answer = _answer;

        emit PriceSettled(_price);
    }

    /*//////////////////////////////////////////////////////////////
                                 PUBLIC
    //////////////////////////////////////////////////////////////*/
    function requestLatestAssertion() external {
        if (pendingAnswer.startedAt != 0) revert RequestInProgress();

        bytes memory _bytesAncillary = abi.encodePacked(
            ancillaryData,
            coverageStart,
            ANCILLARY_TAIL
        );
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

        AssertionAnswer memory _pendingAnswer;
        _pendingAnswer.startedAt = block.timestamp;
        pendingAnswer = _pendingAnswer;

        emit PriceRequested();
    }

    /** @notice Fetch the assertion state of the market
     * @return bool If assertion is true or false for the market condition
     */
    function checkAssertion() public view virtual returns (bool) {
        AssertionAnswer memory assertionAnswer = answer;

        if (assertionAnswer.updatedAt == 0) revert OraclePriceZero();
        if ((block.timestamp - assertionAnswer.updatedAt) > timeOut)
            revert PriceTimedOut();

        if (assertionAnswer.assertion == 1) return true;
        else return false;
    }

    /** @notice Fetch price and return condition
     * @param _marketId Market id
     * @return boolean If condition is met i.e. strike > price
     * @return price Current price for token
     */
    function conditionMet(
        uint256,
        uint256 _marketId
    ) public view virtual returns (bool, int256 price) {
        uint256 conditionType = marketIdToConditionType[_marketId];
        bool condition = checkAssertion();

        if (conditionType == 1) return (condition, price);
        else if (conditionType == 2) return (condition, price);
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
