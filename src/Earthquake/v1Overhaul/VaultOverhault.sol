// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {SemiFungibleVault} from "./SemiFungibleVault.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "@solmate/utils/FixedPointMathLib.sol";
import {
    ReentrancyGuard
} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {FixedPointMathLib} from "@solmate/utils/FixedPointMathLib.sol";

import {
    ERC1155Supply
} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {IVaultOverhaul} from "./IVaultOverhaul.sol";

/// @author Y2K Finance Team

contract VaultOverhault is IVaultOverhaul, ERC1155(""), ERC1155Supply, ReentrancyGuard {   
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /*///////////////////////////////////////////////////////////////
                               IMMUTABLES AND STORAGE
    //////////////////////////////////////////////////////////////*/


    ERC20 public asset;
    string public name;
    string public symbol;
    bytes internal constant EMPTY = "";  
    address public immutable tokenInsured;
    int256 public immutable strikePrice;
    address public immutable factory;
    address public controller;
    uint256[] public epochs;
    bool internal _initialized;

    mapping(uint256 => uint256) public idFinalTVL;
    mapping(uint256 => uint256) public idClaimTVL;
    mapping(uint40 => uint40) public idEpochBegin;
    mapping(uint40 => bool) public idEpochEnded;
    mapping(uint40 => bool) public idExists;
    mapping(uint40 => bool) public epochNull;

    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /** @notice Deposit into vault when event is emitted
     * @param caller Address of deposit caller
     * @param owner receiver who will own of the tokens representing this deposit
     * @param id Vault id
     * @param assets Amount of owner assets to deposit into vault
     */
    event Deposit(
        address caller,
        address indexed owner,
        uint256 indexed id,
        uint256 assets
    );

    /** @notice Withdraw from vault when event is emitted
     * @param caller Address of withdraw caller
     * @param receiver Address of receiver of assets
     * @param owner Owner of shares
     * @param id Vault id
     * @param assets Amount of owner assets to withdraw from vault
     * @param shares Amount of owner shares to burn
     */
    event Withdraw(
        address caller,
        address receiver,
        address indexed owner,
        uint256 indexed id,
        uint256 assets,
        uint256 shares
    );

   
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error AddressZero();
    error AddressNotFactory(address _contract);
    error AddressNotController(address _contract);
    error MarketEpochDoesNotExist();
    error EpochAlreadyStarted();
    error EpochNotFinished();
    error FeeMoreThan150(uint256 _fee);
    error ZeroValue();
    error OwnerDidNotAuthorize(address _sender, address _owner);
    error EpochEndMustBeAfterBegin();
    error MarketEpochExists();
    error FeeCannotBe0();

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /** @notice Only factory addresses can call functions that use this modifier
     */
    modifier onlyFactory() {
        if (msg.sender != factory) revert AddressNotFactory(msg.sender);
        _;
    }

    /** @notice Only controller addresses can call functions that use this modifier
     */
    modifier onlyController() {
        if (msg.sender != controller) revert AddressNotController(msg.sender);
        _;
    }

    /** @notice Only market addresses can call functions that use this modifier
     */
    modifier marketExists(uint40 id) {
        if (idExists[id] != true) revert MarketEpochDoesNotExist();
        _;
    }

    /** @notice You can only call functions that use this modifier before the current epoch has started
     */
    modifier epochHasNotStarted(uint40 id) {
        if (block.timestamp > idEpochBegin[id]) revert EpochAlreadyStarted();
        _;
    }

    /** @notice You can only call functions that use this modifier after the current epoch has started
     */
    modifier epochHasEnded(uint40 id) {
        if (idEpochEnded[id] == false) revert EpochNotFinished();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                 initialize
    //////////////////////////////////////////////////////////////*/

    /**
        @notice initialize 
        @param  _assetAddress    token address representing your asset to be deposited;
        @param  _name   token name for the ERC1155 mints. Insert the name of your token; Example: Y2K_USDC_1.2$
        @param  _symbol token symbol for the ERC1155 mints. insert here if risk or hedge + Symbol. Example: HedgeY2K or riskY2K;
        @param  _token  address of the oracle to lookup the price in chainlink oracles;
        @param  _strikePrice    uint256 representing the price to trigger the depeg event;
        @param _controller  address of the controller contract, this contract can trigger the depeg events;
     */
    function initialize( 
        address _assetAddress,
        string memory _name,
        string memory _symbol,
        address _token,
        int256 _strikePrice,
        address _controller) external {
        if(_initialized) revert AlreadyInitialized();
        if (_controller == address(0)) revert AddressZero();
        if (_token == address(0)) revert AddressZero();
        if (_assetAddress == address(0)) revert AddressZero();
            tokenInsured = _token;
            strikePrice = _strikePrice;
            factory = msg.sender;
            controller = _controller;
            asset = ERC20(_assetAddress);
            name = _name;
            symbol = _symbol;
            _initialized = true;
        }

    /*///////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
        @param  id  uint256 in UNIX timestamp, representing the end date of the epoch. Example: Epoch ends in 30th June 2022 at 00h 00min 00sec: 1654038000;
        @param  assets  uint256 representing how many assets the user wants to deposit, a fee will be taken from this value;
        @param receiver  address of the receiver of the assets provided by this function, that represent the ownership of the deposited asset;
     */
    function deposit(
        uint256 id,
        uint256 assets,
        address receiver
    ) public override marketExists(id) epochHasNotStarted(id) nonReentrant {
        if (receiver == address(0)) revert AddressZero();
        assert(asset.safeTransferFrom(msg.sender, address(this), assets));

        _mint(receiver, id, assets, EMPTY);

        emit Deposit(msg.sender, receiver, id, assets);
    }

    /**
        @notice Deposit ETH function
        @param  id  uint256 in UNIX timestamp, representing the end date of the epoch. Example: Epoch ends in 30th June 2022 at 00h 00min 00sec: 1654038000;
        @param receiver  address of the receiver of the shares provided by this function, that represent the ownership of the deposited asset;
     */
    function depositETH(uint256 id, address receiver)
        external
        payable
        marketExists(id)
        epochHasNotStarted(id)
        nonReentrant
    {
        require(msg.value > 0, "ZeroValue");
        if (receiver == address(0)) revert AddressZero();

        IWETH(address(asset)).deposit{value: msg.value}();
        _mint(receiver, id, msg.value, EMPTY);

        emit Deposit(msg.sender, receiver, id, msg.value);
    }

    /**
    @notice Withdraw entitled deposited assets, checking if a depeg event
    @param  id uint256 in UNIX timestamp, representing the end date of the epoch. Example: Epoch ends in 30th June 2022 at 00h 00min 00sec: 1654038000;
    @param assets   uint256 of how many assets you want to withdraw, this value will be used to calculate how many assets you are entitle to according to the events;
    @param receiver  Address of the receiver of the assets provided by this function, that represent the ownership of the transfered asset;
    @param owner    Address of the owner of these said assets;
    @return shares How many shares the owner is entitled to, according to the conditions;
     */
    function withdraw(
        uint40 id,
        uint256 assets,
        address receiver,
        address owner
    )
        external
        override
        epochHasEnded(id)
        marketExists(id)
        returns (uint256 shares)
    {
        if (receiver == address(0)) revert AddressZero();

        if (msg.sender != owner && isApprovedForAll(owner, msg.sender) == false)
            revert OwnerDidNotAuthorize(msg.sender, owner);

        uint256 entitledShares;
        _burn(owner, id, assets);

        if (epochNull[id] == false) {
            entitledShares = previewWithdraw(id, assets);
        } else {
            entitledShares = assets;
        }
        if (entitledShares > 0) {
            assert(asset.safeTransfer(receiver, entitledShares));
        }

        emit Withdraw(msg.sender, receiver, owner, id, assets, entitledShares);

        return entitledShares;
    }

    /*///////////////////////////////////////////////////////////////
                           ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
        @notice returns total assets for the id of given epoch
        @param  _id uint256 in UNIX timestamp, representing the end date of the epoch. Example: Epoch ends in 30th June 2022 at 00h 00min 00sec: 1654038000;
     */
    function totalAssets(uint256 _id)
        public
        view
        override
        marketExists(_id)
        returns (uint256)
    {
        return totalSupply(_id);
    }

    /*///////////////////////////////////////////////////////////////
                           Factory FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
    @notice Factory function, changes controller address
    @param _controller New controller address
     */
    function changeController(address _controller) public onlyFactory {
        if (_controller == address(0)) revert AddressZero();
        controller = _controller;
    }

    /**
    @notice Function to deploy hedge assets for given epochs, after the creation of this vault
    @param  epochBegin uint256 in UNIX timestamp, representing the begin date of the epoch. Example: Epoch begins in 31/May/2022 at 00h 00min 00sec: 1654038000
    @param  epochEnd uint256 in UNIX timestamp, representing the end date of the epoch and also the ID for the minting functions. Example: Epoch ends in 30th June 2022 at 00h 00min 00sec: 1656630000
    @param _withdrawalFee uint256 of the fee value, multiply your % value by 10, Example: if you want fee of 0.5% , insert 5
     */
    function createAssets(
        uint40 epochBegin,
        uint40 epochEnd
    ) public onlyFactory {
        if (_withdrawalFee > 150) revert FeeMoreThan150(_withdrawalFee);

        if (_withdrawalFee == 0) revert FeeCannotBe0();

        if (idExists[epochEnd] == true) revert MarketEpochExists();

        if (epochBegin >= epochEnd) revert EpochEndMustBeAfterBegin();

        idExists[epochEnd] = true;
        idEpochBegin[epochEnd] = epochBegin;
        epochs.push(epochEnd);
    }

    /*///////////////////////////////////////////////////////////////
                         CONTROLLER LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
    @notice Controller can call this function to trigger the end of the epoch, storing the TVL of that epoch and if a depeg event occurred
    @param  id uint256 in UNIX timestamp, representing the end date of the epoch. Example: Epoch ends in 30th June 2022 at 00h 00min 00sec: 1654038000
     */
    function endEpoch(uint40 id) public onlyController marketExists(id) {
        idEpochEnded[id] = true;
        idFinalTVL[id] = totalAssets(id);
    }

    /**
    @notice Function to be called after endEpoch, by the Controller only, this function stores the TVL of the counterparty vault in a mapping to be used for later calculations of the entitled withdraw
    @param  id uint256 in UNIX timestamp, representing the end date of the epoch. Example: Epoch ends in 30th June 2022 at 00h 00min 00sec: 1654038000
    @param claimTVL uint256 representing the TVL the counterparty vault has, storing this value in a mapping
     */
    function setClaimTVL(uint40 id, uint256 claimTVL)
        public
        onlyController
        marketExists(id)
    {
        idClaimTVL[id] = claimTVL;
    }

    /**
    solhint-disable-next-line max-line-length
    @notice Function to be called after endEpoch and setClaimTVL functions, respecting the calls in order, after storing the TVL of the end of epoch and the TVL amount to claim, this function will allow the transfer of tokens to the counterparty vault
    @param  id uint256 in UNIX timestamp, representing the end date of the epoch. Example: Epoch ends in 30th June 2022 at 00h 00min 00sec: 1654038000
    @param _counterparty Address of the other vault, meaning address of the risk vault, if this is an hedge vault, and vice-versa
    */
    function sendTokens(uint256 _amount, uint40 _id, address _counterparty)
        public
        onlyController
        marketExists(_id)
    {
        assert(asset.safeTransfer(_counterparty, _amount));
    }

    function setEpochNull(uint40 id) public onlyController marketExists(id) {
        epochNull[id] = true;
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HOOKS LOGIC
    //////////////////////////////////////////////////////////////*/
    /**
        @notice Shows assets conversion output from withdrawing assets
        @param  id uint256 token id of token
        @param assets Total number of assets
     */
    function previewWithdraw(uint40 id, uint256 assets)
        public
        view
        override
        returns (uint256 entitledAmount)
    {
        // in case the risk wins aka no depeg event
        // risk users can withdraw the hedge (that is paid by the hedge buyers) and risk; withdraw = (risk + hedge)
        // hedge pay for each hedge seller = ( risk / tvl before the hedge payouts ) * tvl in hedge pool
        // in case there is a depeg event, the risk users can only withdraw the hedge
        entitledAmount = assets.mulDivUp(idClaimTVL[id], idFinalTVL[id]);
        // in case the hedge wins aka depegging
        // hedge users pay the hedge to risk users anyway,
        // hedge guy can withdraw risk (that is transfered from the risk pool),
        // withdraw = % tvl that hedge buyer owns
        // otherwise hedge users cannot withdraw any Eth
    }

    /** @notice Lookup total epochs length
     */
    function epochsLength() public view returns (uint256) {
        return epochs.length;
    }
}
