// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IVaultFactoryV2} from "../../interfaces/IVaultFactoryV2.sol";
import {IConditionProvider} from "../../interfaces/IConditionProvider.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IOptimisticOracleV3} from "../../interfaces/IOptimisticOracleV3.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract UmaPriceProvider is Ownable, IConditionProvider {
    using SafeTransferLib for ERC20;
    struct MarketAnswer {
        uint128 updatedAt;
        uint128 answer;
        uint256 requiredBond;
        bool activeAssertion;
    }

    // Uma V3
    uint64 public constant assertionLiveness = 7200; // 2 hours.
    address immutable currency; // Currency used for all prediction markets
    bytes32 public immutable defaultIdentifier; // Identifier used for all prediction markets.
    IOptimisticOracleV3 public immutable umaV3;

    // Market info
    uint256 public immutable timeOut;
    IVaultFactoryV2 public immutable vaultFactory;
    uint256 public immutable decimals;
    string public description;

    string public outcome;
    string public assertedOutcome;
    bytes public assertionDescription;
    MarketAnswer public marketAnswer;

    mapping(uint256 => uint256) public marketIdToConditionType;

    event MarketAsserted(
        uint256 marketId,
        string assertedOutcome,
        bytes32 assertionId
    );
    event AnswerResolved(bytes32 assertionId, bool assertion);
    event MarketConditionSet(uint256 indexed marketId, uint256 conditionType);

    constructor(
        address _factory,
        uint256 _timeOut,
        address _umaV3,
        string memory _description,
        bytes32 _defaultIdentifier,
        uint256 _decimals,
        address _currency
    ) {
        if (_factory == address(0)) revert ZeroAddress();
        if (_timeOut == 0) revert InvalidInput();
        if (_umaV3 == address(0)) revert ZeroAddress();
        if (keccak256(bytes(_description)) == keccak256(bytes(string(""))))
            revert InvalidInput();
        if (
            keccak256(abi.encodePacked(_defaultIdentifier)) ==
            keccak256(bytes(""))
        ) revert InvalidInput();
        if (_decimals == 0) revert InvalidInput();
        if (_currency == address(0)) revert InvalidInput();

        vaultFactory = IVaultFactoryV2(_factory);
        timeOut = _timeOut;

        umaV3 = IOptimisticOracleV3(_umaV3);
        description = _description;
        decimals = _decimals;
        currency = _currency;
        defaultIdentifier = _defaultIdentifier;
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

    /*//////////////////////////////////////////////////////////////
                                 PUBLIC
    //////////////////////////////////////////////////////////////*/
    // Callback from settled assertion.
    // If the assertion was resolved true, then the asserter gets the reward and the market is marked as resolved.
    // Otherwise, assertedOutcomeId is reset and the market can be asserted again.
    function assertionResolvedCallback(
        bytes32 _assertionId,
        bool _assertedTruthfully
    ) public {
        if (msg.sender != address(umaV3)) revert InvalidCaller();

        marketAnswer.updatedAt = uint128(block.timestamp);
        marketAnswer.answer = _assertedTruthfully ? 1 : 0;
        marketAnswer.activeAssertion = false;

        emit AnswerResolved(_assertionId, _assertedTruthfully);
    }

    // Dispute callback does nothing.
    function assertionDisputedCallback(bytes32 assertionId) public {}

    function fetchAssertion(
        uint256 _marketId
    ) external returns (bytes32 assertionId) {
        if (marketAnswer.activeAssertion == true) revert AssertionActive();
        // Configure bond and claim information
        uint256 minimumBond = umaV3.getMinimumBond(address(currency));

        uint256 requiredBond = marketAnswer.requiredBond;
        uint256 bond = requiredBond > minimumBond ? requiredBond : minimumBond;
        bytes memory claim = _composeClaim();

        // Transfer bond from sender and request assertion
        ERC20(currency).safeTransferFrom(msg.sender, address(this), bond);
        ERC20(currency).safeApprove(address(umaV3), bond);
        assertionId = umaV3.assertTruth(
            claim,
            msg.sender, // Asserter
            address(this), // Receive callback to this contract
            address(0), // No sovereign security
            assertionLiveness,
            IERC20(currency),
            bond,
            defaultIdentifier,
            bytes32(0) // No domain
        );

        marketAnswer.activeAssertion = true;
        emit MarketAsserted(_marketId, assertedOutcome, assertionId);
    }

    /** @notice Fetch the assertion state of the market
     * @return bool If assertion is true or false for the market condition
     */
    function checkAssertion() public view virtual returns (bool) {
        MarketAnswer memory market = marketAnswer;

        if ((block.timestamp - market.updatedAt) > timeOut)
            revert PriceTimedOut();

        if (market.answer == 1) return true;
        else return true;
    }

    // NOTE: _marketId unused but receiving marketId makes Generic controller composabile for future
    /** @notice Fetch price and return condition
     * @param _strike Strike price
     * @return boolean If condition is met i.e. strike > price
     * @return price Current price for token
     */
    function conditionMet(
        uint256 _strike,
        uint256 _marketId
    ) public view virtual returns (bool, int256 price) {
        uint256 conditionType = marketIdToConditionType[_marketId];
        bool condition = checkAssertion();

        if (conditionType == 1) return (condition, price);
        else if (conditionType == 2) return (condition, price);
        else revert ConditionTypeNotSet();
    }

    // Unused
    function getLatestPrice() external view returns (int256) {}

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
    {}

    /*//////////////////////////////////////////////////////////////
                                 INTERNAL
    //////////////////////////////////////////////////////////////*/
    function _composeClaim() internal view returns (bytes memory) {
        return
            abi.encodePacked(
                "As of assertion timestamp ",
                _toUtf8BytesUint(block.timestamp),
                ", the described prediction market outcome is: ",
                outcome,
                ". The market description is: ",
                assertionDescription
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
    error ConditionNotMet();
    error RoundIdOutdated();
    error PriceTimedOut();
    error ConditionTypeNotSet();
    error ConditionTypeSet();
    error InvalidCaller();
    error AssertionActive();
}
