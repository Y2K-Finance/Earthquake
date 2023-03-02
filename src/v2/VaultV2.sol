// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {
    ReentrancyGuard
} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./SemiFungibleVault.sol";
import {IVaultV2} from "./interfaces/IVaultV2.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {FixedPointMathLib} from "@solmate/utils/FixedPointMathLib.sol";

/// @author Y2K Finance Team

contract VaultV2 is IVaultV2, SemiFungibleVault, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using FixedPointMathLib for uint256;

    /*///////////////////////////////////////////////////////////////
                               IMMUTABLES AND STORAGE
    //////////////////////////////////////////////////////////////*/

    // Earthquake parameters
    address public token;
    uint256 public strike;
    uint256 public marketId;
    // Earthquake bussiness logic
    address public treasury;
    address public counterPartyVault;
    address public factory;
    address public controller;
    uint256[] public epochs;

    mapping(uint256 => uint256) public finalTVL;
    mapping(uint256 => uint256) public claimTVL;
    mapping(uint256 => uint256) public epochAccounting;
    mapping(uint256 => EpochConfig) public epochConfig;
    mapping(uint256 => bool) public epochResolved;
    mapping(uint256 => bool) public epochExists;
    mapping(uint256 => bool) public epochNull;
    mapping(address => bool) public whitelistedAddresses;

    /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /** @notice constructor
        @param _assetAddress  address of the asset that will be used as collateral;
        @param _name  string representing the name of the vault;
        @param _symbol  string representing the symbol of the vault;
        @param _tokenURI  string representing the tokenURI of the vault;
        @param _token  address of the token that will be used as collateral;
        @param _strike  uint256 representing the strike price of the vault;
        @param _controller  address of the controller of the vault;
        @param _treasury  address of the treasury of the vault;
     */
    constructor(
        address _assetAddress,
        string memory _name,
        string memory _symbol,
        string memory _tokenURI,
        address _token,
        uint256 _strike,
        address _controller,
        address _treasury
    ) SemiFungibleVault(IERC20(_assetAddress), _name, _symbol, _tokenURI) {
        if (_controller == address(0)) revert AddressZero();
        if (_token == address(0)) revert AddressZero();
        if (_assetAddress == address(0)) revert AddressZero();
        if (_treasury == address(0)) revert AddressZero();
        token = _token;
        strike = _strike;
        factory = msg.sender;
        controller = _controller;
        treasury = _treasury;
        whitelistedAddresses[_treasury] = true;
    }

    /*///////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
        @param  _id  uint256 in UNIX timestamp, representing the end date of the epoch. Example: Epoch ends in 30th June 2022 at 00h 00min 00sec: 1654038000;
        @param  _assets  uint256 representing how many assets the user wants to deposit, a fee will be taken from this value;
        @param _receiver  address of the receiver of the assets provided by this function, that represent the ownership of the deposited asset;
     */
    function deposit(
        uint256 _id,
        uint256 _assets,
        address _receiver
    )
        public
        virtual
        override(SemiFungibleVault)
        epochIdExists(_id)
        epochHasNotStarted(_id)
        nonReentrant
    {
        if (_receiver == address(0)) revert AddressZero();
        SemiFungibleVault.asset.safeTransferFrom(
            msg.sender,
            address(this),
            _assets
        );

        _mint(_receiver, _id, _assets, EMPTY);

        emit Deposit(msg.sender, _receiver, _id, _assets);
    }

    /**
    @notice Withdraw entitled deposited assets, checking if a depeg event
    @param  _id uint256 identifier of the epoch you want to withdraw from;
    @param _assets   uint256 of how many assets you want to withdraw, this value will be used to calculate how many assets you are entitle to according the vaults claimTVL;
    @param _receiver  Address of the receiver of the assets provided by this function, that represent the ownership of the transfered asset;
    @param _owner    Address of the owner of these said assets;
    @return shares How many shares the owner is entitled to, according to the conditions;
     */
    function withdraw(
        uint256 _id,
        uint256 _assets,
        address _receiver,
        address _owner
    )
        external
        virtual
        override(SemiFungibleVault)
        epochIdExists(_id)
        epochHasEnded(_id)
        nonReentrant
        returns (uint256 shares)
    {
        if (_receiver == address(0)) revert AddressZero();

        if (
            msg.sender != _owner &&
            isApprovedForAll(_owner, msg.sender) == false
        ) revert OwnerDidNotAuthorize(msg.sender, _owner);

        _burn(_owner, _id, _assets);

        uint256 entitledShares;

        if (epochNull[_id] == false) {
            entitledShares = previewWithdraw(_id, _assets);
        } else {
            entitledShares = _assets;
        }
        if (entitledShares > 0) {
            SemiFungibleVault.asset.safeTransfer(_receiver, entitledShares);
        }

        emit Withdraw(
            msg.sender,
            _receiver,
            _owner,
            _id,
            _assets,
            entitledShares
        );

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
        override(SemiFungibleVault, IVaultV2)
        returns (uint256)
    {
        // epochIdExists(_id)
        return totalSupply(_id);
    }

    /*///////////////////////////////////////////////////////////////
                           FACTORY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
    @notice Function to set the epoch, only the factory can call this function
    @param  _epochBegin uint40 in UNIX timestamp, representing the begin date of the epoch
    @param  _epochEnd uint40 in UNIX timestamp, representing the end date of the epoch
    @param  _epochId uint256 id representing the epoch
     */
    function setEpoch(
        uint40 _epochBegin,
        uint40 _epochEnd,
        uint256 _epochId
    ) external onlyFactory {
        if (_epochId == 0 || _epochBegin == 0 || _epochEnd == 0)
            revert InvalidEpoch();
        if (epochExists[_epochId] == true) revert EpochAlreadyExists();

        if (_epochBegin >= _epochEnd) revert EpochEndMustBeAfterBegin();

        epochExists[_epochId] = true;

        epochConfig[_epochId] = EpochConfig({
            epochBegin: _epochBegin,
            epochEnd: _epochEnd,
            epochCreation: uint40(block.timestamp)
        });
        epochs.push(_epochId);
    }

    /**
    @notice Factory function, changes controller address
    @param _controller New controller address
     */
    function changeController(address _controller) public onlyFactory {
        if (_controller == address(0)) revert AddressZero();
        controller = _controller;
    }

    /**
    @notice Factory function, whitelist address
    @param _wAddress New treasury address
     */
    function whiteListAddress(address _wAddress) public onlyFactory {
        if (_wAddress == address(0)) revert AddressZero();
        whitelistedAddresses[_wAddress] = !whitelistedAddresses[_wAddress];
    }

    /**
    @notice Factory function, changes treasury address
    @param _treasury New treasury address
     */
    function setTreasury(address _treasury) public onlyFactory {
        if (_treasury == address(0)) revert AddressZero();
        treasury = _treasury;
    }

    /**
    @notice Factory function, changes _counterPartyVault address
    @param _counterPartyVault New _counterPartyVault address
     */
    function setCounterPartyVault(address _counterPartyVault)
        external
        onlyFactory
    {
        if (_counterPartyVault == address(0)) revert AddressZero();
        counterPartyVault = _counterPartyVault;
    }

    /*///////////////////////////////////////////////////////////////
                         CONTROLLER LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
    @notice Controller can call this function to resolve the epoch, this function will set the epoch as ended and store the deposited TVL of the epoch
    @param  _id identifier of the epoch
     */
    function resolveEpoch(uint256 _id)
        external
        onlyController
        epochIdExists(_id)
        epochHasStarted(_id)
    {
        if (epochResolved[_id]) revert EpochAlreadyEnded();
        epochResolved[_id] = true;
        finalTVL[_id] = totalAssets(_id);
    }

    /**
    solhint-disable-next-line max-line-length
    @notice Controller can call after the epoch has ended, this function allows the transfer of tokens to the counterparty vault or treasury. Controller is trusted to do correct accounting. 
    @param  _id uint256 identifier of the epoch
    @param _amount amount that is send to destination
    @param _receiver address of counterparty vault or treasury
    */
    function sendTokens(
        uint256 _id,
        uint256 _amount,
        address _receiver
    ) external onlyController epochIdExists(_id) epochHasEnded(_id) {
        if (_amount > finalTVL[_id]) revert AmountExceedsTVL();
        if (epochAccounting[_id] + _amount > finalTVL[_id])
            revert AmountExceedsTVL();
        if (!whitelistedAddresses[_receiver] && _receiver != counterPartyVault)
            revert DestinationNotAuthorized(_receiver);
        epochAccounting[_id] += _amount;
        SemiFungibleVault.asset.safeTransfer(_receiver, _amount);
    }

    /**
    @notice Controller can call after the epoch has ended, this function stores the value that the holders of the epoch are entiteld to. The value is determined on the controller side
    @param  _id uint256 identifier of the epoch
    @param _claimTVL uint256 representing the TVL the vault has, storing this value in a mapping
     */
    function setClaimTVL(uint256 _id, uint256 _claimTVL)
        external
        onlyController
        epochIdExists(_id)
        epochHasEnded(_id)
    {

        claimTVL[_id] = _claimTVL;
    }

    /**
    @notice This function is called by the controller if the epoch has started, but the counterparty vault has no value. In this case the users can withdraw their deposit.
    @param  _id uint256 identifier of the epoch
     */
    function setEpochNull(uint256 _id)
        public
        onlyController
        epochIdExists(_id)
        epochHasEnded(_id)
    {
        epochNull[_id] = true;
    }

    /*///////////////////////////////////////////////////////////////
                         LOOKUP FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /**
        @notice Shows assets conversion output from withdrawing assets
        @param  _id uint256 epoch identifier
        @param _assets amount of user shares to withdraw
     */
    function previewWithdraw(uint256 _id, uint256 _assets)
        public
        view
        override(SemiFungibleVault)
        returns (uint256 entitledAmount)
    {
        // entitledAmount amount is derived from the claimTVL and the finalTVL
        // if user deposited 1000 assets and the claimTVL is 50% lower than finalTVL, the user is entitled to 500 assets
        // if user deposited 1000 assets and the claimTVL is 50% higher than finalTVL, the user is entitled to 1500 assets
        entitledAmount = _assets.mulDivDown(claimTVL[_id], finalTVL[_id]);
    }

    /** @notice Lookup total epochs length
     */
    function getEpochsLength() public view returns (uint256) {
        return epochs.length;
    }

    /** @notice Lookup all set epochs
     */
    function getAllEpochs() public view returns (uint256[] memory) {
        return epochs;
    }

    /** @notice Lookup epoch begin and end
        @param _id id hashed from marketIndex, epoch begin and end and casted to uint256;
     */
    function getEpochConfig(uint256 _id)
        public
        view
        returns (uint40 epochBegin, uint40 epochEnd, uint40 epochCreation)
    {
        epochBegin = epochConfig[_id].epochBegin;
        epochEnd = epochConfig[_id].epochEnd;
        epochCreation = epochConfig[_id].epochCreation;
    }

    function _asset() internal view returns (IERC20) {
        return asset;
    }

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct EpochConfig {
        uint40 epochBegin;
        uint40 epochEnd;
        uint40 epochCreation;
    }

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

    /** @notice You can only call functions that use this modifier before the epoch has started
     */
    modifier epochHasNotStarted(uint256 _id) {
        if (block.timestamp > epochConfig[_id].epochBegin)
            revert EpochAlreadyStarted();
        _;
    }

    /** @notice You can only call functions that use this modifier after the epoch has started
     */
    modifier epochHasStarted(uint256 _id) {
        if (block.timestamp < epochConfig[_id].epochBegin)
            revert EpochNotStarted();
        _;
    }

    /** @notice Check if epoch exists
     */
    modifier epochIdExists(uint256 id) {
        if (!epochExists[id]) revert EpochDoesNotExist();
        _;
    }

    /** @notice You can only call functions that use this modifier after the epoch has ended
     */
    modifier epochHasEnded(uint256 id) {
        if (!epochResolved[id]) revert EpochNotResolved();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error AddressZero();
    error AddressNotFactory(address _contract);
    error AddressNotController(address _contract);
    error EpochDoesNotExist();
    error EpochAlreadyStarted();
    error EpochNotResolved();
    error EpochAlreadyEnded();
    error EpochNotStarted();
    error ZeroValue();
    error OwnerDidNotAuthorize(address _sender, address _owner);
    error EpochEndMustBeAfterBegin();
    error EpochAlreadyExists();
    error DestinationNotAuthorized(address _counterparty);
    error AmountExceedsTVL();
    error AlreadyInitialized();
    error InvalidEpoch();
}
