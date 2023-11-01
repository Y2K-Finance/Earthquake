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
        uint8 roundId;
        uint8 answeredInRound;
        int8 assertion;
        uint128 pendingRequestAt;
        uint256 updatedAt;
    }

    uint256 public constant REQUEST_TIMEOUT = 3600 * 3;
    uint256 public constant ORACLE_LIVENESS_TIME = 3600 * 2;
    bytes32 public constant PRICE_IDENTIFIER = "YES_OR_NO_QUERY";
    string public constant ANCILLARY_TAIL =
        ". P1: 0 for NO, P2: 1 for YES, P3: 2 for UNDETERMINED";

    uint256 public immutable assertionTimeOut;
    IUmaV2 public immutable oo;
    IFinder public immutable finder;
    IERC20 public immutable currency;

    AssertionAnswer public answer;
    uint128 public reward;
    uint128 public coverageStart;
    string public description;
    string public ancillaryData;

    mapping(uint256 => uint256) public marketIdToConditionType;

    event MarketConditionSet(uint256 indexed marketId, uint256 conditionType);
    event CoverageStartUpdated(uint256 startTime);
    event RewardUpdated(uint256 newReward);
    event PriceSettled(int256 price);
    event PriceRequested();

    constructor(
        uint256 _assertionTimeOut,
        string memory _description,
        address _finder,
        address _currency,
        string memory _ancillaryData,
        uint128 _reward
    ) {
        if (_assertionTimeOut == 0) revert InvalidInput();
        if (keccak256(bytes(_description)) == keccak256(""))
            revert InvalidInput();
        if (_finder == address(0)) revert ZeroAddress();
        if (_currency == address(0)) revert ZeroAddress();
        if (keccak256(bytes(_ancillaryData)) == keccak256(""))
            revert InvalidInput();
        if (_reward == 0) revert InvalidInput();

        assertionTimeOut = _assertionTimeOut;
        description = _description;

        finder = IFinder(_finder);
        oo = IUmaV2(finder.getImplementationAddress("OptimisticOracleV2"));
        currency = IERC20(_currency);
        ancillaryData = _ancillaryData;
        reward = _reward;
        coverageStart = uint128(block.timestamp);
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

    function updateCoverageStart(uint128 _coverageStart) external onlyOwner {
        if (_coverageStart < coverageStart) revert InvalidInput();
        coverageStart = _coverageStart;
        emit CoverageStartUpdated(_coverageStart);
    }

    function updateReward(uint128 newReward) external onlyOwner {
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

        AssertionAnswer memory _answer;
        _answer.updatedAt = uint128(_timestamp);
        _answer.assertion = int8(_price);
        _answer.roundId = answer.roundId + 1;
        _answer.answeredInRound = answer.answeredInRound + 1;
        _answer.pendingRequestAt = answer.pendingRequestAt;
        answer = _answer;

        emit PriceSettled(_price);
    }

    /*//////////////////////////////////////////////////////////////
                                 PUBLIC
    //////////////////////////////////////////////////////////////*/
    function requestLatestAssertion() external {
        if (answer.pendingRequestAt + REQUEST_TIMEOUT > block.timestamp)
            revert RequestInProgress();

        bytes memory _bytesAncillary = abi.encodePacked(
            ancillaryData,
            _toUtf8BytesUint(coverageStart),
            ANCILLARY_TAIL
        );
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

        answer.pendingRequestAt = uint128(block.timestamp);

        emit PriceRequested();
    }

    /** @notice Fetch the assertion state of the market
     * @return bool If assertion is true or false for the market condition
     */
    function checkAssertion() public view virtual returns (bool) {
        AssertionAnswer memory assertionAnswer = answer;

        if (assertionAnswer.updatedAt == 0) revert OraclePriceZero();
        if ((block.timestamp - assertionAnswer.updatedAt) > assertionTimeOut)
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
                                 INTERNAL
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice Converts a uint into a base-10, UTF-8 representation stored in a `string` type.
     * @dev This method is based off of this code: https://stackoverflow.com/a/65707309.
     * @dev Pulled from UMA protocol packages: https://github.com/UMAprotocol/protocol/blob/9bfbbe98bed0ac7d9c924115018bb0e26987e2b5/packages/core/contracts/common/implementation/AncillaryData.sol
     */
    function _toUtf8BytesUint(uint256 x) internal pure returns (bytes memory) {
        if (x == 0) {
            return "0";
        }
        uint256 j = x;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (x != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(x - (x / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            x /= 10;
        }
        return bstr;
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
