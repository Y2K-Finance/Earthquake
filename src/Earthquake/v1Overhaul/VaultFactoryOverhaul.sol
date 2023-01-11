// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IVaultOverhaul} from "./IVaultOverhaul.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IController} from "./interfaces/IController.sol";
import { TimeLock } from "./TimeLock.sol";

/// @author Y2K Finance Team

contract VaultFactory is Ownable {

    /*//////////////////////////////////////////////////////////////
                                Storage
    //////////////////////////////////////////////////////////////*/

    uint32 public marketIndex;
    address public controller;
    address[] public vaultImpl;
    TimeLock public timelocker;

    mapping(uint32 => address[2]) public indexVaults; //[0] premium and [1] collateral vault
    mapping(uint32 => uint40[]) public indexEpochs; //all epochs in the market
    mapping(bytes32 => uint16) public epochFee; //token address to respective oracle smart contract address
    mapping(address => address) public tokenToOracle; //token address to respective oracle smart contract address


    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyTimeLocker() {
        if (msg.sender != address(timelocker)) revert NotTimeLocker();
        _;
    }


    modifier onlyTimeLockerOrOwner() {
        if (msg.sender != address(timelocker) || msg.sender != owner) revert NotTimeLockerOrOwner();
        _;
    }


    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error MarketDoesNotExist(uint32 marketIndex);
    error AddressZero();
    error AddressNotController();
    error AddressFactoryNotInController();
    error ControllerNotSet();
    error NotTimeLocker();
    error NotTimeLockerOrOwner();
    error ControllerAlreadySet();
    error VaultImplNotSet();
    error VaultImplNotContract();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /** @notice Market is created when event is emitted
     * @param mIndex Current market index
     * @param premium premium vault address
     * @param collateral collateral vault address
     * @param token Token address
     * @param name Market name
     */
    event MarketCreated(
        uint32 indexed mIndex,
        address premium,
        address collateral,
        address underlyingAsset,
        address token,
        string name,
        int256 strikePrice,
        address vaultImpl
    );

    /** @notice event is emitted when epoch is created
     * @param mIndex Current market index
     * @param startEpoch Epoch start time
     * @param endEpoch Epoch end time
     * @param withdrawalFee Withdrawal fee
     * @param premium premium vault address
     * @param collateral collateral vault address
     * @param token Token address
     * @param marketEpochId Market epoch id
     * @param name Market name
     * @param strikePrice Strike price
     */
    event EpochCreated(
        uint32 indexed mIndex,
        uint32 startEpoch,
        uint32 endEpoch,
        uint16 withdrawalFee,
        address premium,
        address collateral,
        address token,
        bytes32 indexed marketEpochId,
        string name,
        int256 strikePrice
    );

    /** @notice Controller is set when event is emitted
     * @param newController Address for new controller
     */
    event controllerSet(address indexed newController);

    /** @notice Vault fee is changed when event is emitted
     * @param _marketIndex Target market index
     * @param _feeRate Target fee rate
     */
    event changedVaultFee(uint32 indexed _marketIndex, uint256 _feeRate);

    /** @notice Controller is changed when event is emitted
     * @param _marketIndex Target market index
     * @param controller Target controller address
     */
    event changedController(
        uint32 indexed _marketIndex,
        address indexed controller
    );
    event changedOracle(address indexed _token, address _oracle);

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/


    struct MarketVault {
        uint32 marketIndex;
        uint40 epochBegin;
        uint40 epochEnd;
        uint16 withdrawalFee;
        IVaultOverhaul premium;
        IVaultOverhaul collateral;
    }

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /** @notice Contract constructor
     * @param _policy Admin address address
     */
    constructor(
        address _policy,
        address _vaultImpl,
        uint256 _marketIndex
    ) {
        if(_policy == address(0)) revert AddressZero();

        timelocker = new TimeLock(_policy);
        marketIndex = _marketIndex;
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        if (size == 0) revert VaultImplNotContract();
        // need to have multiple vault implementatoin stored, as if underlyingAsset is WETH depositETH is available and vice versa
        vaultImpl.push(_vaultImpl);
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
        address underlyingAsset,
        string memory _name,
        uint256 _vaultImplIndex
    ) public onlyOwner returns (address premium, address collateral) {
        if (controller == address(0)) revert ControllerNotSet();

        if (IController(controller).getVaultFactory() != address(this))
            revert AddressFactoryNotInController();

        marketIndex += 1;


        if (tokenToOracle[_token] == address(0)) {
                if(_oracle == address(0)) revert AddressZero();
                tokenToOracle[_token] = _oracle;
        }

        //y2kUSDC_99*COLLATERAL

        address premium = _cloneAndDeploy(
            underlyingAsset,
            string(abi.encodePacked(_name, "PREMIUM")),
            "pY2K",
            _token,
            _strikePrice,
            controller,
            _vaultImplIndex
        );

        // y2kUSDC_99*PREMIUM

        address collateral = _cloneAndDeploy(
            underlyingAsset,
            string(abi.encodePacked(_name, "COLLATERAL")),
            "cY2K",
            _token,
            _strikePrice,
            controller,
            _vaultImplIndex
        );

        indexVaults[marketIndex] = [premium, collateral];

        emit MarketCreated(
            marketIndex,
            premium,
            collateral,
            underlyingAsset,
            _token,
            _name,
            _strikePrice,
            vaultImpl[_vaultImplIndex]
        );

        return (premium, collateral);
    }

    function _cloneAndDeploy(
        address _underlyingAsset,
        string memory _name,
        string memory _symbol,
        address _token,
        int256 _strikePrice,
        address _controller,
        uint256 _vaultImplIndex
    ) internal returns (address _out) {
        if(vaultImpl[_vaultImplIndex] == address(0)) revert VaultImplNotSet();

        address _vaultImpl = vaultImpl[_vaultImplIndex];
        // clone bytecode from the vault implementation
        // deploy the bytecode with empty constructor
        assembly {
            // src https://github.com/drgorillamd/clone-deployed-contract
            // Retrieve target address
            let _targetAddress := sload(_vaultImpl.slot)
            
            // Get deployed code size
            let _codeSize := extcodesize(_targetAddress)

            // Get a bit of freemem to land the bytecode
            let _freeMem := mload(0x40)
            
            // Shift the length to the length placeholder
            let _mask := mul(_codeSize, 0x100000000000000000000000000000000000000000000000000000000)

            // I built the init by hand (and it was quite fun)
            let _initCode := or(_mask, 0x62000000600081600d8239f3fe00000000000000000000000000000000000000)

            mstore(_freeMem, _initCode)

            // Copy the bytecode (our initialise part is 13 bytes long)
            extcodecopy(_targetAddress, add(_freeMem, 13), 0, _codeSize)

            // Deploy the copied bytecode, including the constructor
            _out := create(0, _freeMem, add(_codeSize, 13))
        }

        VaultOverhaul(_out).initialize(
            _underlyingAsset,
            _name,
            _symbol,
            _token,
            _strikePrice,
            _controller);

    }

    /**    
    @notice Function to deploy epoch assets for market, zwhere the Index is the date of the end of epoch
    @param  index uint256 of the market index to create more assets in
    @param  epochBegin uint40 in UNIX timestamp, representing the begin date of the epoch. Example: Epoch begins in 31/May/2022 at 00h 00min 00sec: 1654038000
    @param  epochEnd uint40 in UNIX timestamp, representing the end date of the epoch and also the ID for the minting functions. Example: Epoch ends in 30th June 2022 at 00h 00min 00sec: 1656630000
    @param _withdrawalFee uint16 of the fee value, multiply your % value by 10, Example: if you want fee of 0.5% , insert 5
     */
    function deployEpoch(
        uint32 mIndex,
        uint40 epochBegin,
        uint40 epochEnd,
        uint16 _withdrawalFee
    ) public onlyOwner {
        if (controller == address(0)) revert ControllerNotSet();

        if (mIndex > marketIndex) {
            revert MarketDoesNotExist(mIndex);
        }
        address premium = indexVaults[mIndex][0];
        address collateral = indexVaults[mIndex][1];

        MarketVault memory marketVault = MarketVault(
            mIndex,
            epochBegin,
            epochEnd,
            IVaultOverhault(premium),
            IVaultOverhault(collateral),
            _withdrawalFee
        );

        _createEpoch(marketVault);
    }

    function _createEpoch(MarketVault memory _marketVault) internal {
        _marketVault.premium.createAssets(
            _marketVault.epochBegin,
            _marketVault.epochEnd,
            _marketVault.withdrawalFee
        );
        _marketVault.collateral.createAssets(
            _marketVault.epochBegin,
            _marketVault.epochEnd,
            _marketVault.withdrawalFee
        );

        indexEpochs[_marketVault.index].push(_marketVault.epochEnd);

        emit EpochCreated(
            keccak256(
                abi.encodePacked(
                    _marketVault.index,
                    _marketVault.epochBegin,
                    _marketVault.epochEnd
                )
            ),
            _marketVault.index,
            _marketVault.epochBegin,
            _marketVault.epochEnd,
            address(_marketVault.premium),
            address(_marketVault.collateral),
            _marketVault.premium.tokenInsured(),
            _marketVault.premium.name(),
            _marketVault.premium.strikePrice(),
            _marketVault.withdrawalFee
        );
    }

    /**
    @notice Admin function, sets the controller address one time use function only
    @param  _controller Address of the controller smart contract
     */
    function setController(address _controller) public onlyOwner {
        if (controller == address(0)) {
            if (_controller == address(0)) revert AddressZero();
            controller = _controller;

            emit controllerSet(_controller);
        } else {
            revert ControllerAlreadySet();
        }
    }

    /**
    @notice Admin function, changes controller address
    @param _marketIndex Target market index
    @param  _controller Address of the controller smart contract
     */
    function changeController(uint256 _marketIndex, address _controller)
        public
        onlyTimeLocker
    {
        if (_controller == address(0)) revert AddressZero();
        address[2] memory vaults = indexVaults[_marketIndex];
        IVaultOverhaul premium = IVaultOverhaul(vaults[0]);
        IVaultOverhaul collateral = IVaultOverhaul(vaults[1]);
        premium.changeController(_controller);
        collateral.changeController(_controller);

        emit changedController(_marketIndex, _controller);
    }

    /**
    @notice Admin function, changes oracle address for a given token
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
        emit changedOracle(_token, _oracle);
    }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/

    /**
    @notice Function the retrieve the addresses of the premium and collateral vaults, in an array, in the respective order
    @param index uint256 of the market index which to the vaults are associated to
    @return vaults Address array of two vaults addresses, [0] being the premium vault, [1] being the collateral vault
     */
    function getVaults(uint32 index)
        public
        view
        returns (address[2] memory vaults)
    {
        return indexVaults[index];
    }


    function getEpochFee(uint32 index, uint40 epochBegin, uint40 epochEnd)
        public
        view
        returns (uint16 fee)
    {
        return indexFees[ 
            keccak256(
                abi.encodePacked(
                    _marketVault.index,
                    _marketVault.epochBegin,
                    _marketVault.epochEnd
                )
            )];
    }

