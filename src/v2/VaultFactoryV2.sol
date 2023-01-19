// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IVaultV2} from "./interfaces/IVaultV2.sol";
import {VaultV2} from "./VaultV2.sol";
import {VaultV2WETH} from "./VaultV2WETH.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import { TimeLock } from "./TimeLock.sol";

/// @author Y2K Finance Team

contract VaultFactoryV2 is Ownable {

    address immutable WETH;
    /*//////////////////////////////////////////////////////////////
                                Storage
    //////////////////////////////////////////////////////////////*/
    address public treasury;
    bool internal adminSetController;
    TimeLock public timelocker;

    mapping(uint256 => address[2]) public marketIdToVaults; //[0] premium and [1] collateral vault
    mapping(uint256 => uint256[]) public marketIdToEpochs; //all epochs in the market
    mapping(uint256 => uint16) public epochFee; // epochId to fee
    mapping(address => address) public tokenToOracle; //token address to respective oracle smart contract address
    mapping(address => bool) public controllers;

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/
    struct EpochConfiguration {
        uint40 epochBegin;
        uint40 epochEnd;
        uint16 withdrawalFee;
        uint256 marketId;
        uint256 epochId;
        IVaultV2 premium;
        IVaultV2 collateral;
    }

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /** @notice Contract constructor
     * @param _policy Admin address address
     */
    constructor(
        address _policy,
        address _weth
    ) {
        if(_policy == address(0)) revert AddressZero();
        if(_weth == address(0)) revert AddressZero();
        WETH = _weth;
        timelocker = new TimeLock(_policy);
    }

    /*//////////////////////////////////////////////////////////////
                                ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /**
    @notice Function to create two new vaults, premium and collateral, with the respective params, and storing the oracle for the token provided
    @param _token Address of the oracle to lookup the price in chainlink oracles
    @param _strikePrice uint256 representing the price to trigger the depeg event, needs to be 18 decimals
    @param  _oracle Address representing the smart contract to lookup the price of the given _token param
    @return premium Address of the deployed premium vault
    @return collateral Address of the deployed collateral vault
     */
    function createNewMarket(
        address _token,
        int256 _strikePrice,
        address _oracle,
        address _underlyingAsset,
        string memory _name,
        string memory _tokenURI,
        address _controller
    ) public 
        onlyOwner
        controllerIsWhitelisted(_controller)
     returns (address premium, address collateral, uint256 marketId) {

        if(_token == address(0)) revert AddressZero();
        if(_oracle == address(0)) revert AddressZero();
        if(_underlyingAsset == address(0)) revert AddressZero();
        if(_controller == address(0)) revert AddressZero();

        if (tokenToOracle[_token] == address(0)) {
                tokenToOracle[_token] = _oracle;
        }

        uint256 marketId = getMarketId(_token, _strikePrice);
        if(marketIdToVaults[marketId][0] != address(0)) revert MarketAlreadyExists();

        //y2kUSDC_99*PREMIUM
        address premium = _deployVault(
            _underlyingAsset,
            string(abi.encodePacked(_name, "PREMIUM")),
            "pY2K",
            _tokenURI,
            _token,
            _strikePrice,
            _controller
        );

        // y2kUSDC_99*COLLATERAL
        address collateral = _deployVault(
             _underlyingAsset,
            string(abi.encodePacked(_name, "COLLATERAL")),
            "cY2K",
            _tokenURI,
            _token,
            _strikePrice,
            _controller
        );

        //set counterparty vault
        IVaultV2(premium).setCounterPartyVault(collateral);
        IVaultV2(collateral).setCounterPartyVault(premium);

        marketIdToVaults[marketId] = [premium, collateral];

        emit MarketCreated(
            marketId,
            premium,
            collateral,
            _underlyingAsset,
            _token,
            _name,
            _strikePrice,
            _controller
        );

        return (premium, collateral, marketId);
    }

    /**    
    @notice Function set epoch for market,
    @param  _marketId uint256 of the market index to create more assets in
    @param  _epochBegin uint40 in UNIX timestamp, representing the begin date of the epoch. Example: Epoch begins in 31/May/2022 at 00h 00min 00sec: 1654038000
    @param  _epochEnd uint40 in UNIX timestamp, representing the end date of the epoch and also the ID for the minting functions. Example: Epoch ends in 30th June 2022 at 00h 00min 00sec: 1656630000
    @param _withdrawalFee uint16 of the fee value, multiply your % value by 10, Example: if you want fee of 0.5% , insert 5
     */
    function createEpoch(
        uint256 _marketId,
        uint40 _epochBegin,
        uint40 _epochEnd,
        uint16 _withdrawalFee
    ) public onlyOwner returns (uint256 epochId) {

        address[2] memory vaults = marketIdToVaults[_marketId];
    
        if (vaults[0] == address(0) || vaults[1] == address(0)) {
            revert MarketDoesNotExist(_marketId);
        }

        if (_withdrawalFee == 0) revert FeeCannotBe0();

        if(IVaultV2(vaults[0]).controller() == address(0)) revert ControllerNotSet();
        if(IVaultV2(vaults[1]).controller() == address(0)) revert ControllerNotSet();
        
        epochId = getEpochId(_marketId, _epochBegin, _epochEnd);

        _setEpoch(
            EpochConfiguration(
                _epochBegin,
                _epochEnd,
                _withdrawalFee,
                _marketId,
                epochId,
                IVaultV2(vaults[0]),
                IVaultV2(vaults[1]) 
            )
        );
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function _deployVault(
        address _underlyingAsset,
        string memory _name,
        string memory _symbol,
        string memory _tokenURI,
        address _token,
        int256 _strikePrice,
        address _controller
    ) internal returns (address _out) {  

        if(_underlyingAsset == WETH) {
            return address(
                new VaultV2WETH(
                _underlyingAsset,
                _name,
                _symbol,
                _tokenURI,
                _token,
                _strikePrice,
                _controller,
                treasury
                )
            );
        }else {
         return address(
            new VaultV2(
                _underlyingAsset,
                _name,
                _symbol,
                _tokenURI,
                _token,
                _strikePrice,
                _controller,
                treasury
                )
            );
        }
    }


    function _setEpoch(EpochConfiguration memory _epochConfig) internal {
        _epochConfig.premium.setEpoch(
            _epochConfig.epochBegin,
            _epochConfig.epochEnd,
            _epochConfig.epochId
        );
        _epochConfig.collateral.setEpoch(
            _epochConfig.epochBegin,
            _epochConfig.epochEnd,
            _epochConfig.epochId
        );

        epochFee[_epochConfig.epochId] = _epochConfig.withdrawalFee;
        marketIdToEpochs[_epochConfig.marketId].push(_epochConfig.epochId);

        emit EpochCreated(
            _epochConfig.epochId,
            _epochConfig.marketId,
            _epochConfig.epochBegin,
            _epochConfig.epochEnd,
            address(_epochConfig.premium),
            address(_epochConfig.collateral),
            _epochConfig.premium.tokenInsured(),
            _epochConfig.premium.name(),
            _epochConfig.premium.strikePrice(),
            _epochConfig.withdrawalFee
        );
    }

    /**
    @notice Function to whiteliste controller smart contract, only owner or timelocker can add more controllers
    @notice owner can set controller once, all future controllers must be set by timelocker
    @param  _controller Address of the controller smart contract
     */
    function whitelistController(address _controller) public {
        if (_controller == address(0)) revert AddressZero();
        if(msg.sender == owner() && !adminSetController) {
            controllers[_controller] = controllers[_controller];
            adminSetController = true;
        }else if(msg.sender == address(timelocker)) {
             controllers[_controller] = !controllers[_controller];
             if(!adminSetController) adminSetController = true;
        } else {
            revert NotAuthorized();
        }
    }


    /**
    @notice Admin function, whitelists an address on vault for sendTokens function
    @param _treasury Treasury address
    @param  _marketId Target market index
     */
    function changeTreasury(address _treasury, uint256 _marketId)
        public
        onlyTimeLocker
    {
        if (_treasury == address(0)) revert AddressZero();

        address[2] memory vaults = marketIdToVaults[_marketId];
    
        if (vaults[0] == address(0) || vaults[1] == address(0)) {
            revert MarketDoesNotExist(_marketId);
        }

        IVaultV2(vaults[0]).whiteListAddress(_treasury);
        IVaultV2(vaults[1]).whiteListAddress(_treasury);

        emit ChangedTreasury(_treasury, _marketId);
    }

    /**
    @notice Admin function, sets treasury address
    @param _treasury Treasury address
     */
    function setTreasury(address _treasury) public onlyTimeLocker {
        if (_treasury == address(0)) revert AddressZero();
        treasury = _treasury;
        emit TreasurySet(_treasury);
    }

    /**
    @notice Timelocker function, changes controller address on vaults
    @param _marketId Target marketId
    @param  _controller Address of the controller smart contract
     */
    function changeController(uint256 _marketId, address _controller)
        public
        onlyTimeLocker
        controllerIsWhitelisted(_controller)
    {
        if(_controller == address(0)) revert AddressZero();

        address[2] memory vaults = marketIdToVaults[_marketId];
    
        if (vaults[0] == address(0) || vaults[1] == address(0)) {
            revert MarketDoesNotExist(_marketId);
        }

        IVaultV2(vaults[0]).changeController(_controller);
        IVaultV2(vaults[1]).changeController(_controller);

        emit ControllerChanged(_marketId, _controller, vaults[0], vaults[1]);
    }

    /**
    @notice Timelocker function, changes oracle address for a given token
    @param _token Target token address
    @param  _oracle Oracle address
     */
    function changeOracle(address _token, address _oracle)
        public
        onlyTimeLocker
    {
        if (_oracle == address(0)) revert AddressZero();
        if (_token == address(0)) revert AddressZero();

        tokenToOracle[_token] = _oracle;
        emit OracleChanged(_token, _oracle);
    }

    /**
    @notice Timelocker function, changes owner address
    @param _owner Address of the new _owner
     */
    function changeOwner(address _owner) public onlyTimeLocker {
        if (_owner == address(0)) revert AddressZero();
        _transferOwnership(_owner);
    }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/

    /**
    @notice Function the retrieve the addresses of the premium and collateral vaults, in an array, in the respective order
    @param index uint256 of the market index which to the vaults are associated to
    @return vaults Address array of two vaults addresses, [0] being the premium vault, [1] being the collateral vault
     */
    function getVaults(uint256 index)
        public
        view
        returns (address[2] memory vaults)
    {
        return marketIdToVaults[index];
    }


    /**
    @notice Function to retrieve the fee for a given epoch
    @param epochId uint256 of the epoch
    @return fee uint16 of the fee
     */
    function getEpochFee(uint256 epochId)
        public
        view
        returns (uint16 fee)
    {
        return epochFee[epochId];
    }

    /**
    @notice Function to compute the marketId from a token and a strike price
    @param token Address of the token
    @param strikePrice uint256 of the strike price
    @return marketId uint256 of the marketId
     */
    function getMarketId(address token, int256 strikePrice)
        public
        view
        returns (uint256 marketId)
    {
        return uint256(keccak256(abi.encodePacked(token, strikePrice)));
    }

    /**
    @notice Function to compute the epochId from a marketId, epochBegin and epochEnd
    @param marketId uint256 of the marketId
    @param epochBegin uint40 of the epoch begin
    @param epochEnd uint40 of the epoch end
    @return epochId uint256 of the epochId
     */
    function getEpochId(uint256 marketId, uint40 epochBegin, uint40 epochEnd)
        public
        view
        returns (uint256 epochId)
    {
        return uint256(keccak256(abi.encodePacked(marketId, epochBegin, epochEnd)));
    }

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyTimeLocker() {
        if (msg.sender != address(timelocker)) revert NotTimeLocker();
        _;
    }

    modifier onlyTimeLockerOrOwner() {
        if (msg.sender != address(timelocker) && msg.sender != owner()) revert NotTimeLockerOrOwner();
        _;
    }

    modifier controllerIsWhitelisted(address _controller) {
        if (!controllers[_controller]) revert ControllerNotSet();
        _;
    }


    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error MarketDoesNotExist(uint256 marketId);
    error MarketAlreadyExists();
    error AddressZero();
    error AddressNotController();
    error AddressFactoryNotInController();
    error ControllerNotSet();
    error NotTimeLocker();
    error NotTimeLockerOrOwner();
    error ControllerAlreadySet();
    error VaultImplNotSet();
    error VaultImplNotContract();
    error NotAuthorized();
    error FeeCannotBe0();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /** @notice Market is created when event is emitted
        * @param marketId market id
        * @param premium premium vault address
        * @param collateral collateral vault address
        * @param underlyingAsset underlying asset address
        * @param token Token address to monitor strike price
        * @param name Market name
        * @param strikePrice Strike price
        * @param controller Controller address
     */
    event MarketCreated(
        uint256 indexed marketId,
        address premium,
        address collateral,
        address underlyingAsset,
        address token,
        string name,
        int256 strikePrice,
        address controller
    );

    /** @notice event is emitted when epoch is created
     * @param mIndex Current market index
     * @param startEpoch Epoch start time
     * @param endEpoch Epoch end time
     * @param withdrawalFee Withdrawal fee
     * @param premium premium vault address
     * @param collateral collateral vault address
     * @param token Token address
     * @param epochId epoch id derrived out of market id, start and end epoch
     * @param name Market name
     * @param strikePrice Strike price
     */
    event EpochCreated(
        uint256 indexed epochId,
        uint256 indexed marketId,
        uint40 startEpoch,
        uint40 endEpoch,
        address premium,
        address collateral,
        address token,
        string name,
        int256 strikePrice,
        uint16 withdrawalFee
    );


    /** @notice Controller is changed when event is emitted
        * @param marketId Target market index
        * @param controller Target controller address
        * @param premium Target premium vault address
        * @param collateral Target collateral vault address
     */
    event ControllerChanged(
        uint256 indexed marketId,
        address indexed controller,
        address premium,
        address collateral
    );

    /** @notice Oracle is changed when event is emitted
     * @param _token Target token address
     * @param _oracle Target oracle address
     */
    event OracleChanged(address indexed _token, address _oracle);


    /** @notice Treasury is changed when event is emitted
     * @param _treasury Treasury address
     * @param _marketId Target market index
     */
    event ChangedTreasury(address _treasury, uint256 indexed _marketId);

    /** @notice Treasury is changed when event is emitted
     * @param _treasury Treasury address
     */
    event TreasurySet(address _treasury);

}