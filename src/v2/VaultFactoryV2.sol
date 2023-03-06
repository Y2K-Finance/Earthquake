// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IVaultV2} from "./interfaces/IVaultV2.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {VaultV2Creator} from "./libraries/VaultV2Creator.sol";

/// @author Y2K Finance Team

contract VaultFactoryV2 is Ownable {
    address public immutable WETH;
    bytes internal constant COLLAT = "COLLATERAL";
    bytes internal constant PREMIUM = "PREMIUM";
    bytes internal constant CSYMBOL = "cY2K";
    bytes internal constant PSYMBOL = "pY2K";
    /*//////////////////////////////////////////////////////////////
                                Storage
    //////////////////////////////////////////////////////////////*/
    address public treasury;
    bool internal adminSetController;
    address public timelocker;

    mapping(uint256 => address[2]) public marketIdToVaults; //[0] premium and [1] collateral vault
    mapping(uint256 => uint256[]) public marketIdToEpochs; //all epochs in the market
    mapping(uint256 => uint16) public epochFee; // epochId to fee
    mapping(address => address) public tokenToOracle; //token address to respective oracle smart contract address
    mapping(address => bool) public controllers;

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /** @notice Contract constructor
     * @param _weth WETH address
     * @param _treasury Treasury address
    * @param _timelocker Timelocker address
     */
    constructor(
        address _weth,
        address _treasury,
        address _timelocker
    ) {
        if (_weth == address(0)) revert AddressZero();
        WETH = _weth;
        timelocker = _timelocker;
        treasury = _treasury;
    }

    /*//////////////////////////////////////////////////////////////
                                ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /**
    @notice Function to create two new vaults, premium and collateral, with the respective params, and storing the oracle for the token provided
    @param  _marketCalldata MarketConfigurationCalldata struct with the market params
    @return premium address of the premium vault
    @return collateral address of the collateral vault
    @return marketId uint256 of the marketId
     */
    function createNewMarket(bytes calldata _marketCalldata)
        external
        virtual
        onlyOwner
        returns (
            address premium,
            address collateral,
            uint256 marketId
        )
    {
        MarketConfigurationCalldata memory data = abi.decode(
            _marketCalldata,
            (MarketConfigurationCalldata)
        );
        if (!controllers[data.controller]) revert ControllerNotSet();
        if (data.token == address(0)) revert AddressZero();
        if (data.oracle == address(0)) revert AddressZero();
        if (data.underlyingAsset == address(0)) revert AddressZero();

        if (tokenToOracle[data.token] == address(0)) {
            tokenToOracle[data.token] = data.oracle;
        }

        marketId = getMarketId(data.token, data.strike);
        if (marketIdToVaults[marketId][0] != address(0))
            revert MarketAlreadyExists();

        //y2kUSDC_99*PREMIUM
        premium = VaultV2Creator.createVaultV2(
            VaultV2Creator.MarketConfiguration(
                data.underlyingAsset == WETH,
                data.underlyingAsset,
                string(abi.encodePacked(data.name, PREMIUM)),
                string(PSYMBOL),
                data.tokenURI,
                data.token,
                data.strike,
                data.controller,
                treasury
            )
        );

        // y2kUSDC_99*COLLATERAL
        collateral =  VaultV2Creator.createVaultV2(
            VaultV2Creator.MarketConfiguration(
                data.underlyingAsset == WETH,
                data.underlyingAsset,
                string(abi.encodePacked(data.name, COLLAT)),
                string(CSYMBOL),
                data.tokenURI,
                data.token,
                data.strike,
                data.controller,
                treasury
            )
        );

        //set counterparty vault
        IVaultV2(premium).setCounterPartyVault(collateral);
        IVaultV2(collateral).setCounterPartyVault(premium);

        marketIdToVaults[marketId] = [premium, collateral];

        emit MarketCreated(
            marketId,
            premium,
            collateral,
            data.underlyingAsset,
            data.token,
            data.name,
            data.strike,
            data.controller
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
    ) public onlyOwner returns (uint256 epochId, address[2] memory vaults) {
        vaults = marketIdToVaults[_marketId];

        if (vaults[0] == address(0) || vaults[1] == address(0)) {
            revert MarketDoesNotExist(_marketId);
        }

        if (_withdrawalFee == 0) revert FeeCannotBe0();

        if (!controllers[IVaultV2(vaults[0]).controller()])
            revert ControllerNotSet();
        if (!controllers[IVaultV2(vaults[1]).controller()])
            revert ControllerNotSet();

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
            _epochConfig.premium.token(),
            _epochConfig.premium.strike(),
            _epochConfig.withdrawalFee
        );
    }

    /**
    @notice Function to whitelist controller smart contract, only owner or timelocker can add more controllers. 
    owner can set controller once, all future controllers must be set by timelocker.
    @param  _controller Address of the controller smart contract
     */
    function whitelistController(address _controller) public {
        if (_controller == address(0)) revert AddressZero();
        if (msg.sender == owner() && !adminSetController) {
            controllers[_controller] = true;
            adminSetController = true;
            emit ControllerWhitelisted(_controller);
        } else if (msg.sender == timelocker) {
            controllers[_controller] = !controllers[_controller];
            if (!adminSetController) adminSetController = true;
            emit ControllerWhitelisted(_controller);
        } else {
            revert NotAuthorized();
        }
    }

    /**
    @notice Admin function, whitelists an address on vault for sendTokens function
    @param _treasury Treasury address
    @param  _marketId Target market index
     */
    function changeTreasury(uint256 _marketId, address _treasury)
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
        IVaultV2(vaults[0]).setTreasury(treasury);
        IVaultV2(vaults[1]).setTreasury(treasury);

        emit AddressWhitelisted(_treasury, _marketId);
    }

    /**
    @notice Admin function, whitelists an address on vault for sendTokens function
    @param  _marketId Target market index
    @param _wAddress Treasury address
     */
    function whitelistAddressOnMarket(uint256 _marketId, address _wAddress)
        public
        onlyTimeLocker
    {
        if (_wAddress == address(0)) revert AddressZero();

        address[2] memory vaults = marketIdToVaults[_marketId];

        if (vaults[0] == address(0) || vaults[1] == address(0)) {
            revert MarketDoesNotExist(_marketId);
        }

        IVaultV2(vaults[0]).whiteListAddress(_wAddress);
        IVaultV2(vaults[1]).whiteListAddress(_wAddress);

        emit AddressWhitelisted(_wAddress, _marketId);
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
        if (_controller == address(0)) revert AddressZero();

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
    @notice Function to retrieve the epochId for a given marketId
    @param marketId marketId
    @return epochIds uint256 array of epochIds
     */
    function getEpochsByMarketId(uint256 marketId)
        public
        view
        returns (uint256[] memory)
    {
        return marketIdToEpochs[marketId];
    }

    /**
    @notice Function to retrieve the fee for a given epoch
    @param epochId uint256 of the epoch
    @return fee uint16 of the fee
     */
    function getEpochFee(uint256 epochId) public view returns (uint16 fee) {
        return epochFee[epochId];
    }

    /**
    @notice Function to compute the marketId from a token and a strike price
    @param token Address of the token
    @param strikePrice uint256 of the strike price
    @return marketId uint256 of the marketId
     */
    function getMarketId(address token, uint256 strikePrice)
        public
        pure
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
    function getEpochId(
        uint256 marketId,
        uint40 epochBegin,
        uint40 epochEnd
    ) public pure returns (uint256 epochId) {
        return
            uint256(
                keccak256(abi.encodePacked(marketId, epochBegin, epochEnd))
            );
    }

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/
    struct MarketConfigurationCalldata {
        address token;
        uint256 strike;
        address oracle;
        address underlyingAsset;
        string name;
        string tokenURI;
        address controller;
    }

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
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /** @notice Modifier to check if the caller is the timelocker
     */
    modifier onlyTimeLocker() {
        if (msg.sender != timelocker) revert NotTimeLocker();
        _;
    }

    /** @notice Modifier to check if the controller is whitelisted on the factory
     */
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
    error ControllerNotSet();
    error NotTimeLocker();
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
     * @param strike Strike price
     * @param controller Controller address
     */
    event MarketCreated(
        uint256 indexed marketId,
        address premium,
        address collateral,
        address underlyingAsset,
        address token,
        string name,
        uint256 strike,
        address controller
    );

    /** @notice event is emitted when epoch is created
     * @param epochId epoch id derrived out of market id, start and end epoch
     * @param marketId Current market index
     * @param startEpoch Epoch start time
     * @param endEpoch Epoch end time
     * @param premium premium vault address
     * @param collateral collateral vault address
     * @param token Token address
     * @param strike Strike price
     * @param withdrawalFee Withdrawal fee
     */
    event EpochCreated(
        uint256 indexed epochId,
        uint256 indexed marketId,
        uint40 startEpoch,
        uint40 endEpoch,
        address premium,
        address collateral,
        address token,
        uint256 strike,
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

    /** @notice Address whitelisted is changed when event is emitted
     * @param _wAddress whitelisted address
     * @param _marketId Target market index
     */
    event AddressWhitelisted(address _wAddress, uint256 indexed _marketId);

    /** @notice Treasury is changed when event is emitted
     * @param _treasury Treasury address
     */
    event TreasurySet(address _treasury);

    /** @notice New Controller is whitelisted when event is emitted
     * @param _controller Controller address
     */
    event ControllerWhitelisted(address _controller);


    }
