// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IConditionProvider} from "../../interfaces/IConditionProvider.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IOptimisticOracleV3} from "../../interfaces/IOptimisticOracleV3.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "forge-std/console.sol";

/// @notice Assertion provider for one data point with differing description
/// @dev Example: (a) ETH vol is above <dataPoint>, and (b) ETH vol is below <dataPoint>
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

    // Uma V3
    uint64 public constant ASSERTION_LIVENESS = 7200; // 2 hours.
    uint256 public constant ASSERTION_COOLDOWN = 300; // 5 minutes.
    address public immutable currency; // Currency used for all prediction markets
    bytes32 public immutable defaultIdentifier; // Identifier used for all prediction markets.
    IOptimisticOracleV3 public immutable umaV3;

    // Market info
    uint256 public immutable timeOut;
    string public description;
    AssertionData public assertionData; // The uint data value for the market
    uint256 public requiredBond; // Bond required to assert on a market

    mapping(uint256 => string) public marketIdToAssertionDescription;
    mapping(uint256 => MarketAnswer) public marketIdToAnswer;
    mapping(bytes32 => uint256) public assertionIdToMarket;
    mapping(address => bool) public whitelistRelayer;

    event MarketAsserted(uint256 marketId, bytes32 assertionId);
    event AssertionResolved(bytes32 assertionId, bool assertion);
    event DescriptionSet(uint256 marketId, string description);
    event BondUpdated(uint256 newBond);
    event AssertionDataUpdated(uint256 newData);
    event RelayerUpdated(address relayer, bool state);
    event BondWithdrawn(uint256 amount);
    event AnswersReset(uint256[] marketIds);

    /**
        @param _description is for the price provider market
        @param _timeOut is the max time between receiving callback and resolving market condition
        @param _umaV3 is the V3 Uma Optimistic Oracle
        @param _currency is currency used to post the bond
        @param _requiredBond is bond amount of currency to pull from the caller and hold in escrow until the assertion is resolved. This must be >= getMinimumBond(address(currency)). 
     */
    constructor(
        string memory _description,
        uint256 _timeOut,
        address _umaV3,
        address _currency,
        uint256 _requiredBond
    ) {
        if (keccak256(bytes(_description)) == keccak256(bytes(string(""))))
            revert InvalidInput();
        if (_timeOut == 0) revert InvalidInput();
        if (_umaV3 == address(0)) revert ZeroAddress();
        if (_currency == address(0)) revert ZeroAddress();
        if (_requiredBond == 0) revert InvalidInput();

        description = _description;
        timeOut = _timeOut;
        umaV3 = IOptimisticOracleV3(_umaV3);
        defaultIdentifier = umaV3.defaultIdentifier();
        currency = _currency;
        requiredBond = _requiredBond;
        assertionData.updatedAt = uint128(block.timestamp);
    }

    /*//////////////////////////////////////////////////////////////
                                 ADMIN
    //////////////////////////////////////////////////////////////*/
    /**
        @notice Defines the assertion description for a market
        @dev Can only be set once and the assertionData is expected to be updated for assertions
     */
    function setAssertionDescription(
        uint256 _marketId,
        string calldata _description
    ) external onlyOwner {
        if (
            keccak256(
                abi.encodePacked(marketIdToAssertionDescription[_marketId])
            ) != keccak256(abi.encodePacked(""))
        ) revert DescriptionAlreadySet();
        marketIdToAssertionDescription[_marketId] = _description;
        emit DescriptionSet(_marketId, _description);
    }

    /**
        @notice Updates the default bond used by this contract when asserting on Uma
        @param newBond is the new bond amount
     */
    function updateRequiredBond(uint256 newBond) external onlyOwner {
        if (newBond == 0) revert InvalidInput();
        requiredBond = newBond;
        emit BondUpdated(newBond);
    }

    /**
        @notice Updates the data being used to assert in the uma assertion request
        @param _newData is the new data for the assertion
     */
    function updateAssertionData(uint256 _newData) external onlyOwner {
        _updateAssertionData(_newData);
    }

    /**
        @notice Updates the assertion data and makes a request to Uma V3 for a market
        @dev Updated data will be used for assertion then a callback will be received after LIVENESS_PERIOD
        @param _newData is the new data for the assertion
        @param _marketId is the marketId for the market
     */
    function updateAssertionDataAndFetch(
        uint256 _newData,
        uint256 _marketId
    ) external onlyOwner returns (bytes32) {
        _updateAssertionData(_newData);
        return _fetchAssertion(_marketId);
    }

    /**
        @notice Toggles relayer status for an address
        @param _relayer is the address to update
     */
    function updateRelayer(address _relayer) external onlyOwner {
        if (_relayer == address(0)) revert ZeroAddress();
        bool relayerState = whitelistRelayer[_relayer];
        whitelistRelayer[_relayer] = !relayerState;
        emit RelayerUpdated(_relayer, relayerState);
    }

    /**
        @notice Withdraws the balance of the currency in the contract 
        @dev This is likely to be the bond value remaining in the contract
     */
    function withdrawBond() external onlyOwner {
        ERC20 bondCurrency = ERC20(currency);
        uint256 balance = bondCurrency.balanceOf(address(this));
        bondCurrency.safeTransfer(msg.sender, balance);
        emit BondWithdrawn(balance);
    }

    /**
        @notice Resets answer to 0
        @dev If the answer has expired then it can be reset - allowing checks to default to false
        @param _marketId is the marketId for the market
     */
    function resetAnswerAfterTimeout(
        uint256[] memory _marketId
    ) external onlyOwner {
        for (uint i; i < _marketId.length; ) {
            uint256 currentId = _marketId[i];
            MarketAnswer memory marketAnswer = marketIdToAnswer[currentId];

            if (
                marketAnswer.answer == 1 &&
                (block.timestamp - marketAnswer.updatedAt) > timeOut
            ) marketIdToAnswer[currentId].answer = 0;

            unchecked {
                i++;
            }
        }
        emit AnswersReset(_marketId);
    }

    /*//////////////////////////////////////////////////////////////
                                 EXTERNAL
    //////////////////////////////////////////////////////////////*/
    /**
        @notice Fetches the assertion from the UMA V3 Optimistic Oracle
        @param _marketId is the marketId for the market
        @return assertionId is the id for the assertion
     */
    function fetchAssertion(uint256 _marketId) external returns (bytes32) {
        return _fetchAssertion(_marketId);
    }

    /** 
        @notice Fetch the assertion state of the market
        @dev If asserition is active then will revert
        @dev If assertion is true and timedOut then will revert
        @param _marketId is the marketId for the market
        @return bool If assertion is true or false for the market condition
     */
    function checkAssertion(
        uint256 _marketId
    ) public view virtual returns (bool) {
        MarketAnswer memory marketAnswer = marketIdToAnswer[_marketId];

        if (marketAnswer.activeAssertion == true) revert AssertionActive();
        if (
            marketAnswer.answer == 1 &&
            (block.timestamp - marketAnswer.updatedAt) > timeOut
        ) revert PriceTimedOut();

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
        bool _conditionMet = checkAssertion(_marketId);
        return (_conditionMet, price);
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
                                 INTERNAL
    //////////////////////////////////////////////////////////////*/
    /**
        @param _newData is the new data for the assertion
        @dev updates the assertion data
     */
    function _updateAssertionData(uint256 _newData) private {
        if (_newData == 0) revert InvalidInput();
        assertionData = AssertionData({
            assertionData: uint128(_newData),
            updatedAt: uint128(block.timestamp)
        });

        emit AssertionDataUpdated(_newData);
    }

    /**
        @dev AssertionDataOutdated check ensures the data being asserted is up to date
        @dev CooldownPending check ensures the cooldown period has passed since the last assertion
        @param _marketId is the marketId for the market
     */
    function _fetchAssertion(
        uint256 _marketId
    ) private returns (bytes32 assertionId) {
        if (whitelistRelayer[msg.sender] == false) revert InvalidCaller();

        MarketAnswer memory marketAnswer = marketIdToAnswer[_marketId];
        if (marketAnswer.activeAssertion == true) revert AssertionActive();
        if (block.timestamp - marketAnswer.updatedAt < ASSERTION_COOLDOWN)
            revert CooldownPending();
        if ((block.timestamp - assertionData.updatedAt) > timeOut)
            revert AssertionDataOutdated();

        // Configure bond and claim information
        uint256 minimumBond = umaV3.getMinimumBond(address(currency));
        uint256 reqBond = requiredBond;
        uint256 bond = reqBond > minimumBond ? reqBond : minimumBond;
        bytes memory claim = _composeClaim(
            marketIdToAssertionDescription[_marketId]
        );

        // Transfer bond from sender and request assertion
        ERC20 bondCurrency = ERC20(currency);
        if (bondCurrency.balanceOf(address(this)) < bond)
            bondCurrency.safeTransferFrom(msg.sender, address(this), bond);
        bondCurrency.safeApprove(address(umaV3), bond);

        // Request assertion from UMA V3
        assertionId = umaV3.assertTruth(
            claim,
            address(this), // Asserter
            address(this), // Receive callback to this contract
            address(0), // No sovereign security
            ASSERTION_LIVENESS,
            IERC20(currency),
            bond,
            defaultIdentifier,
            bytes32(0) // No domain
        );

        assertionIdToMarket[assertionId] = _marketId;
        marketAnswer.activeAssertion = true;
        marketAnswer.assertionId = assertionId;
        if (marketAnswer.answer == 1) marketAnswer.answer = 0;
        marketIdToAnswer[_marketId] = marketAnswer;

        emit MarketAsserted(_marketId, assertionId);
    }

    /**
        @param _assertionDescription assertion description fetched with the marketId
        @dev encode claim would look like: "As of assertion timestamp <timestamp>, <assertionDescription> <assertionStrike>"
        Where inputs could be: "As of assertion timestamp 1625097600, <USDC/USD exchange rate is> <above> <0.997>"
        @return bytes for the claim
     */
    function _composeClaim(
        string memory _assertionDescription
    ) internal view returns (bytes memory) {
        return
            abi.encodePacked(
                "As of assertion timestamp ",
                _toUtf8BytesUint(block.timestamp),
                _assertionDescription,
                _toUtf8BytesUint(assertionData.assertionData)
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
    error InvalidCaller();
    error AssertionActive();
    error AssertionInactive();
    error AssertionDataOutdated();
    error CooldownPending();
    error DescriptionAlreadySet();
}
