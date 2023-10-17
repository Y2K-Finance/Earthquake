// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IUmaV2} from "../../interfaces/IUmaV2.sol";
import {IFinder} from "../../interfaces/IFinder.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
    @notice The defintion information the Uma YER_OR_NO_QUERY is as follows.
        Points to remember: (1) No possible defintion for data sources, (2) Sources entirely up to voters, (3) No price feeds providable
        Custom return values can be defined for four return types: 
        - P1 --> for no (default return 0 if not set)
        - P2 --> for yes (default return 1 if not set)
        - P3 --> for undetermined (default return 2 if not set)
        - P4 --> undetermined and there's an early expiration of a specific last possible timestamp listed (default return of mint int256 if not set)
 */
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
    string public constant ANCILLARY_TAIL =
        ". P1: 0 for NO, P2: 1 for YES, P3: 2 for UNDETERMINED";

    uint256 public immutable timeOut;
    IUmaV2 public immutable oo;
    IFinder public immutable finder;
    IERC20 public immutable currency;

    string public description;
    string public ancillaryData;
    AssertionAnswer public answer;
    AssertionAnswer public pendingAnswer;
    uint256 public reward;
    uint256 public coverageStart;

    mapping(uint256 => uint256) public marketIdToConditionType;

    event MarketConditionSet(uint256 indexed marketId, uint256 conditionType);
    event CoverageStartUpdated(uint256 startTime);
    event RewardUpdated(uint256 newReward);
    event PriceSettled(int256 price);
    event PriceRequested();

    constructor(
        uint256 _timeOut,
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
        description = _description;

        finder = IFinder(_finder);
        oo = IUmaV2(finder.getImplementationAddress("OptimisticOracleV2"));
        currency = IERC20(_currency);
        ancillaryData = _ancillaryData;
        reward = _reward;
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
