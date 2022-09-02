// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vault} from "./Vault.sol";

interface IController {
    function getVaultFactory() external view returns (address);
}

contract VaultFactory {
    // solhint-disable var-name-mixedcase
    address public immutable Admin;
    address public immutable WETH;
    // solhint-enable var-name-mixedcase
    address public treasury;
    address public controller;
    uint256 public marketIndex;

    struct MarketVault{
        uint256 index;
        uint256 epochBegin;
        uint256 epochEnd;
        Vault hedge;
        Vault risk;
        uint256 withdrawalFee;
    }

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error MarketDoesNotExist(uint256 marketIndex);
    error AddressNotAdmin(address addr);
    error AddressZero();
    error AddressNotController();
    error AddressFactoryNotInController();
    error StrikePriceGreaterThan1000(int256 strikePrice);
    error StrikePriceLesserThan100(int256 strikePrice);
    error ControllerNotSet();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    
    /** @notice Market is created when event is emitted
      * @param mIndex Current market index
      * @param hedge Hedge vault address
      * @param risk Risk vault address
      * @param token Token address
      * @param name Market name
      */ 
    event MarketCreated(
        uint256 indexed mIndex,
        address hedge,
        address risk,
        address token,
        string name,
        int256 strikePrice
    );

    /** @notice Epoch is created when event is emitted
      * @param marketEpochId Current market epoch id
      * @param mIndex Current market index
      * @param startEpoch Epoch start time
      * @param endEpoch Epoch end time
      * @param hedge Hedge vault address
      * @param risk Risk vault address
      * @param token Token address
      * @param name Market name
      * @param strikePrice Vault strike price
      */
    event EpochCreated(
        bytes32 indexed marketEpochId,
        uint256 indexed mIndex,
        uint256 startEpoch,
        uint256 endEpoch,
        address hedge,
        address risk,
        address token,
        string name,
        int256 strikePrice,
        uint256 withdrawalFee
    );

    /** @notice Controller is set when event is emitted
      * @param newController Address for new controller
      */ 
    event controllerSet(address indexed newController);

    /** @notice Treasury is changed when event is emitted
      * @param _treasury Treasury address
      * @param _marketIndex Target market index
      */ 
    event changedTreasury(address _treasury, uint256 indexed _marketIndex);

    /** @notice Vault fee is changed when event is emitted
      * @param _marketIndex Target market index
      * @param _feeRate Target fee rate
      */ 
    event changedVaultFee(uint256 indexed _marketIndex, uint256 _feeRate);

    /** @notice Vault time window is changed when event is emitted
      * @param _marketIndex Target market index
      * @param _timeWindow Target time window
      */ 
    event changedTimeWindow(uint256 indexed _marketIndex, uint256 _timeWindow);
    
    /** @notice Controller is changed when event is emitted
      * @param _marketIndex Target market index
      * @param controller Target controller address
      */ 
    event changedController(
        uint256 indexed _marketIndex,
        address indexed controller
    );
    event changedOracle(address indexed _token, address _oracle);

    /*//////////////////////////////////////////////////////////////
                                MAPPINGS
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address[]) public indexVaults; //[0] hedge and [1] risk vault
    mapping(uint256 => uint256[]) public indexEpochs; //all epochs in the market
    mapping(address => address) public tokenToOracle; //token address to respective oracle smart contract address

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /** @notice Only admin addresses can call functions that use this modifier
      */
    modifier onlyAdmin() {
        if(msg.sender != Admin)
            revert AddressNotAdmin(msg.sender);
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /** @notice Contract constructor
      * @param _treasury Treasury address
      * @param _weth Wrapped Ether token address
      * @param _admin Admin address
      */ 
    constructor(
        address _treasury,
        address _weth,
        address _admin
    ) {
        if(_admin == address(0))
            revert AddressZero();
        if(_weth == address(0))
            revert AddressZero();

        if(_treasury == address(0))
            revert AddressZero();

        Admin = _admin;
        WETH = _weth;
        marketIndex = 0;
        treasury = _treasury;
    }

    /*//////////////////////////////////////////////////////////////
                                ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
    @notice Function to create two new vaults, hedge and risk, with the respective params, and storing the oracle for the token provided
    @param _withdrawalFee uint256 of the fee value, multiply your % value by 10, Example: if you want fee of 0.5% , insert 5
    @param _token Address of the oracle to lookup the price in chainlink oracles
    @param _strikePrice uint256 representing the price to trigger the depeg event, needs to be the same decimals as the oracle price
    @param  epochBegin uint256 in UNIX timestamp, representing the begin date of the epoch. Example: Epoch begins in 31/May/2022 at 00h 00min 00sec: 1654038000
    @param  epochEnd uint256 in UNIX timestamp, representing the end date of the epoch. Example: Epoch ends in 30th June 2022 at 00h 00min 00sec: 1656630000
    @param  _oracle Address representing the smart contract to lookup the price of the given _token param
    @return insr    Address of the deployed hedge vault
    @return rsk     Address of the deployed risk vault
     */
    function createNewMarket(
        uint256 _withdrawalFee,
        address _token,
        int256 _strikePrice,
        uint256 epochBegin,
        uint256 epochEnd,
        address _oracle,
        string memory _name
    ) public onlyAdmin returns (address insr, address rsk) {
        if(
            IController(controller).getVaultFactory() != address(this)
            )
            revert AddressFactoryNotInController();

        if(controller == address(0))
            revert ControllerNotSet();

        if(_strikePrice > 1000)
            revert StrikePriceGreaterThan1000(_strikePrice);

        if(_strikePrice < 100)
            revert StrikePriceLesserThan100(_strikePrice);

        _strikePrice = _strikePrice * 10e15;

        marketIndex += 1;

        //y2kUSDC_99*RISK or y2kUSDC_99*HEDGE

        Vault hedge = new Vault(
            WETH,
            string(abi.encodePacked(_name,"HEDGE")),
            "hY2K",
            treasury,
            _token,
            _strikePrice,
            controller
        );

        Vault risk = new Vault(
            WETH,
            string(abi.encodePacked(_name,"RISK")),
            "rY2K",
            treasury,
            _token,
            _strikePrice,
            controller
        );

        indexVaults[marketIndex] = [address(hedge), address(risk)];

        if (tokenToOracle[_token] == address(0)) {
            tokenToOracle[_token] = _oracle;
        }

        emit MarketCreated(
            marketIndex,
            address(hedge),
            address(risk),
            _token,
            _name,
            _strikePrice
        );

        MarketVault memory marketVault = MarketVault(marketIndex, epochBegin, epochEnd, hedge, risk, _withdrawalFee);

        _createEpoch(marketVault);

        return (address(hedge), address(risk));
    }

    /**    
    @notice Function to deploy hedge assets for given epochs, after the creation of this vault, where the Index is the date of the end of epoch
    @param  index uint256 of the market index to create more assets in
    @param  epochBegin uint256 in UNIX timestamp, representing the begin date of the epoch. Example: Epoch begins in 31/May/2022 at 00h 00min 00sec: 1654038000
    @param  epochEnd uint256 in UNIX timestamp, representing the end date of the epoch and also the ID for the minting functions. Example: Epoch ends in 30th June 2022 at 00h 00min 00sec: 1656630000
    @param _withdrawalFee uint256 of the fee value, multiply your % value by 10, Example: if you want fee of 0.5% , insert 5
     */
    function deployMoreAssets(
        uint256 index,
        uint256 epochBegin,
        uint256 epochEnd,
        uint256 _withdrawalFee
    ) public onlyAdmin {
        if(controller == address(0))
            revert ControllerNotSet();

        if (index > marketIndex) {
            revert MarketDoesNotExist(index);
        }
        address hedge = indexVaults[index][0];
        address risk = indexVaults[index][1];

        MarketVault memory marketVault = MarketVault(index, epochBegin, epochEnd, Vault(hedge), Vault(risk), _withdrawalFee);

        _createEpoch(marketVault);
    }

    function _createEpoch(
        MarketVault memory _marketVault
    ) internal {
        
        _marketVault.hedge.createAssets(_marketVault.epochBegin, _marketVault.epochEnd, _marketVault.withdrawalFee);
        _marketVault.risk.createAssets(_marketVault.epochBegin, _marketVault.epochEnd, _marketVault.withdrawalFee);

        indexEpochs[_marketVault.index].push(_marketVault.epochEnd);

        emit EpochCreated(
            keccak256(abi.encodePacked(_marketVault.index, _marketVault.epochBegin, _marketVault.epochEnd)),
            _marketVault.index,
            _marketVault.epochBegin,
            _marketVault.epochEnd,
            address(_marketVault.hedge),
            address(_marketVault.risk),
            _marketVault.hedge.tokenInsured(),
            _marketVault.hedge.name(),
            _marketVault.hedge.strikePrice(),
            _marketVault.withdrawalFee
        );
    }

    /**
    @notice Admin function, sets the controller address
    @param  _controller Address of the controller smart contract
     */
    function setController(address _controller) public onlyAdmin {
        if(_controller == address(0))
            revert AddressZero();
        controller = _controller;

        emit controllerSet(_controller);
    }

    /**
    @notice Admin function, changes the assigned treasury address
    @param _treasury Treasury address
    @param  _marketIndex Target market index
     */
    function changeTreasury(address _treasury, uint256 _marketIndex)
        public
        onlyAdmin
    {
        treasury = _treasury;
        address[] memory vaults = indexVaults[_marketIndex];
        Vault insr = Vault(vaults[0]);
        Vault risk = Vault(vaults[1]);
        insr.changeTreasury(_treasury);
        risk.changeTreasury(_treasury);

        emit changedTreasury(_treasury, _marketIndex);
    }

    /**
    @notice Admin function, changes vault time window
    @param _marketIndex Target market index
    @param  _timewindow New time window
     */
    function changeTimewindow(uint256 _marketIndex, uint256 _timewindow)
        public
        onlyAdmin
    {
        address[] memory vaults = indexVaults[_marketIndex];
        Vault insr = Vault(vaults[0]);
        Vault risk = Vault(vaults[1]);
        insr.changeTimewindow(_timewindow);
        risk.changeTimewindow(_timewindow);

        emit changedTimeWindow(_marketIndex, _timewindow);
    }

    /**
    @notice Admin function, changes controller address
    @param _marketIndex Target market index
    @param  _controller Address of the controller smart contract
     */
    function changeController(uint256 _marketIndex, address _controller)
        public
        onlyAdmin
    {
        if(_controller == address(0))
            revert AddressZero();

        address[] memory vaults = indexVaults[_marketIndex];
        Vault insr = Vault(vaults[0]);
        Vault risk = Vault(vaults[1]);
        insr.changeController(_controller);
        risk.changeController(_controller);

        emit changedController(_marketIndex, _controller);
    }

    /**
    @notice Admin function, changes oracle address for a given token
    @param _token Target token address
    @param  _oracle Oracle address
     */
    function changeOracle(address _token, address _oracle) public onlyAdmin {
        if(_oracle == address(0))
            revert AddressZero();
        if(_token == address(0))
            revert AddressZero();
            
        tokenToOracle[_token] = _oracle;
        emit changedOracle(_token, _oracle);
    }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/

    /**
    @notice Function the retrieve the addresses of the hedge and risk vaults, in an array, in the respective order
    @param index uint256 of the market index which to the vaults are associated to
    @return vaults Address array of two vaults addresses, [0] being the hedge vault, [1] being the risk vault
     */
    function getVaults(uint256 index)
        public
        view
        returns (address[] memory vaults)
    {
        return indexVaults[index];
    }
}
