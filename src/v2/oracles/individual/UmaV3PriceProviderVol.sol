// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IConditionProvider} from "../../interfaces/IConditionProvider.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IOptimisticOracleV3} from "../../interfaces/IOptimisticOracleV3.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Price provider where Uma is used to check the price of a token or a custom script
/// @dev This provider would work with any price or script compared with a timestamp and roundId
contract UmaV3PriceProviderVol is Ownable {
    using SafeTransferLib for ERC20;
    struct MarketAnswer {
        bool activeAssertion;
        uint128 updatedAt;
        uint256 answer;
        bytes32 assertionId;
    }

    struct AssertionData {
        uint128 assertionData;
        uint128 assertionTimestamp;
        uint256 updatedAt;
    }

    // Uma V3
    uint64 public constant ASSERTION_LIVENESS = 7200; // 2 hours. // TODO: 1 hour
    uint256 public constant ASSERTION_COOLDOWN = 600; // 10 minutes.
    address public immutable currency; // Currency used for all prediction markets
    bytes32 public immutable defaultIdentifier; // Identifier used for all prediction markets.
    IOptimisticOracleV3 public immutable umaV3;

    // Market info
    uint256 public immutable timeOut;
    uint256 public immutable decimals;
    string public description;
    string public assertionDescription;
    MarketAnswer public globalAnswer; // The answer for the market
    AssertionData public assertionData; // The uint data value for the market
    uint256 public requiredBond; // Bond required to assert on a market

    mapping(address => bool) public whitelistRelayer;

    event MarketAsserted(bytes32 assertionId);
    event AssertionResolved(bytes32 assertionId, bool assertion);
    event BondUpdated(uint256 newBond);
    event AssertionDataUpdated(uint256 newData);
    event RelayerUpdated(address relayer, bool state);
    event BondWithdrawn(uint256 amount);

    /**
        @param _decimals is decimals for the provider maker if relevant
        @param _description is for the price provider market
        @param _timeOut is the max time between receiving callback and resolving market condition
        @param _umaV3 is the V3 Uma Optimistic Oracle
        @param _currency is currency used to post the bond
        @param _requiredBond is bond amount of currency to pull from the caller and hold in escrow until the assertion is resolved. This must be >= getMinimumBond(address(currency)). 
     */
    constructor(
        uint256 _decimals,
        string memory _description,
        string memory _assertionDescription,
        uint256 _timeOut,
        address _umaV3,
        address _currency,
        uint256 _requiredBond
    ) {
        if (_decimals == 0) revert InvalidInput();
        if (keccak256(bytes(_description)) == keccak256(bytes(string(""))))
            revert InvalidInput();
        if (
            keccak256(bytes(_assertionDescription)) ==
            keccak256(bytes(string("")))
        ) revert InvalidInput();
        if (_timeOut == 0) revert InvalidInput();
        if (_umaV3 == address(0)) revert ZeroAddress();
        if (_currency == address(0)) revert ZeroAddress();
        // if (_requiredBond == 0) revert InvalidInput();

        description = _description;
        decimals = _decimals;
        assertionDescription = _assertionDescription;
        timeOut = _timeOut;
        umaV3 = IOptimisticOracleV3(_umaV3);
        defaultIdentifier = umaV3.defaultIdentifier();
        currency = _currency;
        requiredBond = _requiredBond;
    }

    /*//////////////////////////////////////////////////////////////
                                 ADMIN
    //////////////////////////////////////////////////////////////*/
    function updateRequiredBond(uint256 newBond) external onlyOwner {
        if (newBond == 0) revert InvalidInput();
        requiredBond = newBond;
        emit BondUpdated(newBond);
    }

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

        MarketAnswer memory marketAnswer = globalAnswer;
        if (marketAnswer.activeAssertion == false) revert AssertionInactive();

        marketAnswer.updatedAt = uint128(block.timestamp);
        marketAnswer.answer = _assertedTruthfully
            ? assertionData.assertionData
            : 0;
        marketAnswer.activeAssertion = false;
        globalAnswer = marketAnswer;

        emit AssertionResolved(_assertionId, _assertedTruthfully);
    }

    /*//////////////////////////////////////////////////////////////
                                 EXTERNAL
    //////////////////////////////////////////////////////////////*/
    /**
        @notice Updates the assertion data and makes a request to Uma V3 for a market
        @dev Updated data will be used for assertion then a callback will be received after LIVENESS_PERIOD
        @param _newData is the new data for the assertion
     */
    function updateAssertionDataAndFetch(
        uint256 _newData,
        uint256 _assertionTimestamp
    ) external returns (bytes32) {
        if (_newData == 0) revert InvalidInput();
        if (whitelistRelayer[msg.sender] == false) revert InvalidCaller();
        _updateAssertionData(_newData, _assertionTimestamp);
        return _fetchAssertion();
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
        roundId = 0;
        price = int256(globalAnswer.answer);
        startedAt = assertionData.updatedAt;
        updatedAt = globalAnswer.updatedAt;
        answeredInRound = 0;
    }

    /** @notice Fetch the assertion state of the market
     * @return bool If assertion is true or false for the market condition
     */
    function getLatestPrice() public view virtual returns (int256) {
        MarketAnswer memory marketAnswer = globalAnswer;

        if (marketAnswer.activeAssertion == true) revert AssertionActive();
        if ((block.timestamp - marketAnswer.updatedAt) > timeOut)
            revert PriceTimedOut();

        return int256(marketAnswer.answer);
    }

    /** @notice Fetch price and return condition
     * @param _strike is the strike price for the market
     * @return boolean If condition is met i.e. strike > price
     * @return price Current price for token
     */
    function conditionMet(
        uint256 _strike,
        uint256
    ) public view virtual returns (bool /** conditionMet */, int256 price) {
        uint256 conditionType = _strike % 2 ** 1;
        price = getLatestPrice();

        if (conditionType == 1) return (int256(_strike) < price, price);
        else return (int256(_strike) > price, price);
    }

    /*//////////////////////////////////////////////////////////////
                                 INTERNAL
    //////////////////////////////////////////////////////////////*/
    /**
        @param _newData is the new data for the assertion
        @dev updates the assertion data
     */
    function _updateAssertionData(
        uint256 _newData,
        uint256 _assertionTimestamp
    ) internal {
        assertionData = AssertionData({
            assertionData: uint128(_newData),
            assertionTimestamp: uint128(_assertionTimestamp),
            updatedAt: block.timestamp
        });

        emit AssertionDataUpdated(_newData);
    }

    /**
        @dev AssertionDataOutdated check ensures the data being asserted is up to date
        @dev CooldownPending check ensures the cooldown period has passed since the last assertion
     */
    function _fetchAssertion() internal returns (bytes32 assertionId) {
        MarketAnswer memory marketAnswer = globalAnswer;
        if (marketAnswer.activeAssertion == true) revert AssertionActive();
        if (block.timestamp - marketAnswer.updatedAt < ASSERTION_COOLDOWN)
            revert CooldownPending();

        // Configure bond and claim information
        uint256 minimumBond = umaV3.getMinimumBond(address(currency));
        uint256 reqBond = requiredBond;
        uint256 bond = reqBond > minimumBond ? reqBond : minimumBond;
        bytes memory claim = _composeClaim();

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

        marketAnswer.activeAssertion = true;
        marketAnswer.assertionId = assertionId;
        globalAnswer = marketAnswer;

        emit MarketAsserted(assertionId);
    }

    /**
        @dev encode claim would look like: "As of assertion timestamp <timestamp>, <assertionDescription> <assertionStrike>"
        Where inputs could be: "As of assertion timestamp 1625097600, <USDC/USD exchange rate is><0.997>"
        @return bytes for the claim
     */
    function _composeClaim() internal view returns (bytes memory) {
        return
            abi.encodePacked(
                "As of assertion timestamp ",
                _toUtf8BytesUint(assertionData.assertionTimestamp),
                assertionDescription,
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
    error CooldownPending();
}
