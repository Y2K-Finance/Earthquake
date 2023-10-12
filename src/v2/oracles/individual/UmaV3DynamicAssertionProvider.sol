// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IConditionProvider} from "../../interfaces/IConditionProvider.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IOptimisticOracleV3} from "../../interfaces/IOptimisticOracleV3.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "forge-std/console.sol";

/// @notice Assertion provider where the condition can be checked without a required begin time e.g. 1 PEPE > $1000 or BTC market > 2x ETH market cap
/// @dev This provider would not work if you needed to check if x happened between time y and z
contract UmaV3DynamicAssertionProvider is Ownable {
    using SafeTransferLib for ERC20;
    struct MarketAnswer {
        bool activeAssertion;
        uint128 updatedAt;
        uint8 answer;
        bytes32 assertionId;
    }

    struct AssertionData {
        uint128 assertionData;
        uint128 updatedAt;
    }

    string public constant OUTCOME_1 = "true. ";
    string public constant OUTCOME_2 = "false. ";

    // Uma V3
    uint64 public constant ASSERTION_LIVENESS = 7200; // 2 hours.
    address public immutable currency; // Currency used for all prediction markets
    bytes32 public immutable defaultIdentifier; // Identifier used for all prediction markets.
    IOptimisticOracleV3 public immutable umaV3;

    // Market info
    uint256 public immutable timeOut;
    uint256 public immutable decimals;
    string public description;
    bytes public assertionDescription;
    AssertionData public assertionData; // The uint data value for the market
    uint256 public requiredBond; // Bond required to assert on a market

    mapping(uint256 => uint256) public marketIdToConditionType;
    mapping(uint256 => MarketAnswer) public marketIdToAnswer;
    mapping(bytes32 => uint256) public assertionIdToMarket;

    event MarketAsserted(uint256 marketId, bytes32 assertionId);
    event AssertionResolved(bytes32 assertionId, bool assertion);
    event MarketConditionSet(uint256 indexed marketId, uint256 conditionType);
    event BondUpdated(uint256 newBond);
    event AssertionDataUpdated(uint256 newData);

    /**
        @param _decimals is decimals for the provider maker if relevant
        @param _description is for the price provider market
        @param _timeOut is the max time between receiving callback and resolving market condition
        @param _umaV3 is the V3 Uma Optimistic Oracle
        @param _defaultIdentifier is UMA DVM identifier to use for price requests in the event of a dispute. Must be pre-approved.
        @param _currency is currency used to post the bond
        @param _assertionDescription is description used for the market
        @param _requiredBond is bond amount of currency to pull from the caller and hold in escrow until the assertion is resolved. This must be >= getMinimumBond(address(currency)). 
     */
    constructor(
        uint256 _decimals,
        string memory _description,
        uint256 _timeOut,
        address _umaV3,
        bytes32 _defaultIdentifier,
        address _currency,
        bytes memory _assertionDescription,
        uint256 _requiredBond
    ) {
        if (_decimals == 0) revert InvalidInput();
        if (keccak256(bytes(_description)) == keccak256(bytes(string(""))))
            revert InvalidInput();
        if (_timeOut == 0) revert InvalidInput();
        if (_umaV3 == address(0)) revert ZeroAddress();
        if (
            keccak256(abi.encodePacked(_defaultIdentifier)) ==
            keccak256(abi.encodePacked(bytes32("")))
        ) revert InvalidInput();
        if (_currency == address(0)) revert ZeroAddress();
        if (
            keccak256(abi.encodePacked(_assertionDescription)) ==
            keccak256(bytes(""))
        ) revert InvalidInput();
        if (_requiredBond == 0) revert InvalidInput();

        decimals = _decimals;
        description = _description;
        timeOut = _timeOut;
        umaV3 = IOptimisticOracleV3(_umaV3);
        defaultIdentifier = _defaultIdentifier;
        currency = _currency;
        assertionDescription = _assertionDescription;
        requiredBond = _requiredBond;
        assertionData.updatedAt = uint128(block.timestamp);
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

    function updateAssertionData(uint256 _newData) public onlyOwner {
        if (_newData == 0) revert InvalidInput();
        assertionData = AssertionData({
            assertionData: uint128(_newData),
            updatedAt: uint128(block.timestamp)
        });

        emit AssertionDataUpdated(_newData);
    }

    function updateAssertionDataAndFetch(
        uint256 _newData,
        uint256 _marketId
    ) external onlyOwner returns (bytes32) {
        updateAssertionData(_newData);
        return fetchAssertion(_marketId);
    }

    /*//////////////////////////////////////////////////////////////
                                 CALLBACK
    //////////////////////////////////////////////////////////////*/
    // Callback from settled assertion.
    // If the assertion was resolved true, then the asserter gets the reward and the market is marked as resolved.
    // Otherwise, assertedOutcomeId is reset and the market can be asserted again.
    function assertionResolvedCallback(
        bytes32 _assertionId,
        bool _assertedTruthfully
    ) external {
        if (msg.sender != address(umaV3)) revert InvalidCaller();

        uint256 marketId = assertionIdToMarket[_assertionId];
        MarketAnswer memory marketAnswer = marketIdToAnswer[marketId];
        if (marketAnswer.activeAssertion == false) revert AssertionInactive();

        marketAnswer.updatedAt = uint128(block.timestamp);
        marketAnswer.answer = _assertedTruthfully ? 1 : 0;
        marketAnswer.activeAssertion = false;
        marketIdToAnswer[marketId] = marketAnswer;

        emit AssertionResolved(_assertionId, _assertedTruthfully);
    }

    /*//////////////////////////////////////////////////////////////
                                 EXTERNAL
    //////////////////////////////////////////////////////////////*/

    function fetchAssertion(
        uint256 _marketId
    ) public returns (bytes32 assertionId) {
        MarketAnswer memory marketAnswer = marketIdToAnswer[_marketId];
        if (marketAnswer.activeAssertion == true) revert AssertionActive();
        if ((block.timestamp - assertionData.updatedAt) > timeOut)
            revert AssertionDataEmpty();

        // Configure bond and claim information
        uint256 minimumBond = umaV3.getMinimumBond(address(currency));
        uint256 reqBond = requiredBond;
        uint256 bond = reqBond > minimumBond ? reqBond : minimumBond;
        bytes memory claim = _composeClaim(marketIdToConditionType[_marketId]);

        // Transfer bond from sender and request assertion
        ERC20(currency).safeTransferFrom(msg.sender, address(this), bond);
        ERC20(currency).safeApprove(address(umaV3), bond);
        assertionId = umaV3.assertTruth(
            claim,
            msg.sender, // Asserter
            address(this), // Receive callback to this contract
            address(0), // No sovereign security
            ASSERTION_LIVENESS,
            IERC20(currency),
            bond,
            defaultIdentifier,
            bytes32(0) // No domain
        );

        assertionIdToMarket[assertionId] = _marketId;
        marketIdToAnswer[_marketId].activeAssertion = true;
        marketIdToAnswer[_marketId].assertionId = assertionId;

        emit MarketAsserted(_marketId, assertionId);
    }

    /** @notice Fetch the assertion state of the market
     * @return bool If assertion is true or false for the market condition
     */
    function checkAssertion(
        uint256 _marketId
    ) public view virtual returns (bool) {
        MarketAnswer memory marketAnswer = marketIdToAnswer[_marketId];

        if ((block.timestamp - marketAnswer.updatedAt) > timeOut)
            revert PriceTimedOut();

        if (marketAnswer.answer == 1) return true;
        else return false;
    }

    // NOTE: _marketId unused but receiving marketId makes Generic controller composabile for future
    /** @notice Fetch price and return condition
     * @param _marketId the marketId for the market
     * @return boolean If condition is met i.e. strike > price
     * @return price Current price for token
     */
    function conditionMet(
        uint256,
        uint256 _marketId
    ) public view virtual returns (bool, int256 price) {
        uint256 conditionType = marketIdToConditionType[_marketId];
        bool condition = checkAssertion(_marketId);

        if (conditionType == 1) return (condition, price);
        else if (conditionType == 2) return (condition, price);
        else revert ConditionTypeNotSet();
    }

    /*//////////////////////////////////////////////////////////////
                                 INTERNAL
    //////////////////////////////////////////////////////////////*/
    /**
        @param _conditionType is the condition type for the market
        @dev encode claim would look like: "As of assertion timestamp <timestamp>, <assertionDescription> <outcome> <assertionStrike>"
        Where inputs could be: "As of assertion timestamp 1625097600, <USDC/USD exchange rate is> <above> <0.997>"
        @return bytes for the claim
     */
    function _composeClaim(
        uint256 _conditionType
    ) internal view returns (bytes memory) {
        return
            abi.encodePacked(
                "As of assertion timestamp ",
                _toUtf8BytesUint(block.timestamp),
                ", the following statement is",
                _conditionType == 1 ? OUTCOME_1 : OUTCOME_2,
                assertionDescription,
                assertionData.assertionData
            );
    }

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
    error ZeroAddress();
    error InvalidInput();
    error PriceTimedOut();
    error ConditionTypeNotSet();
    error ConditionTypeSet();
    error InvalidCaller();
    error AssertionActive();
    error AssertionInactive();
    error InvalidCallback();
    error AssertionDataEmpty();
}
