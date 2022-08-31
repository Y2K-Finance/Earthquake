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

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error MarketDoesNotExist(uint256 marketIndex);

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    
    /** @notice Market is created when event triggers
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

    /** @notice Epoch is created when event triggers
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
        int256 strikePrice
    );

    /** @notice Controller is set when event triggers
      * @param newController Address for new controller
      */ 
    event controllerSet(address indexed newController);

    /** @notice Treasury is changed when event triggers
      * @param _treasury Treasury address
      * @param _marketIndex Target market index
      */ 
    event changedTreasury(address _treasury, uint256 indexed _marketIndex);

    /** @notice Vault fee is changed when event triggers
      * @param _marketIndex Target market index
      * @param _feeRate Target fee rate
      */ 
    event changedVaultFee(uint256 indexed _marketIndex, uint256 _feeRate);

     /** @notice Withdrawal fee is changed when event triggers
      * @param _marketIndex Target market index
      * @param _feeRate Target fee rate
      */ 
    event changeWithdrawalFee(uint256 indexed _marketIndex, uint256 _feeRate);

    /** @notice Time window is changed when event triggers
      * @param _marketIndex Target market index
      * @param _timeWindow Target time window
      */ 
    event changedTimeWindow(uint256 indexed _marketIndex, uint256 _timeWindow);
    
    /** @notice Controller is changed when event triggers
      * @param _marketIndex Target market index
      * @param controller Target controller address
      */ 
    event changedController(
        uint256 indexed _marketIndex,
        address indexed controller
    );

    /*//////////////////////////////////////////////////////////////
                                MAPPINGS
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address[]) public indexVaults; //[0] hedge and [1] risk vault
    mapping(uint256 => uint256[]) public indexEpochs; //all epochs in the market
    mapping(address => address) public tokenToOracle; //token address to respective oracle smart contract address

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/
    
    /** @notice Only admin addresses can call functions with this modifier
      */
    modifier onlyAdmin() {
        require(msg.sender == Admin, "You are not Admin!");
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
        require(_admin != address(0), "admin cannot be the zero address");
        require(_weth != address(0), "WETH cannot be the zero address");
        require(_treasury != address(0), "treasury cannot be the zero address");

        Admin = _admin;
        WETH = _weth;
        marketIndex = 0;
        treasury = _treasury;
    }

    /*//////////////////////////////////////////////////////////////
                                ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
    @notice function to create two new vaults, hedge and risk, with the respective params, and storing the oracle for the token provided
    @param _withdrawalFee uint256 of the fee value, multiply your % value by 10, Example: if you want fee of 0.5% , insert 5;
    @param _token address of the oracle to lookup the price in chainlink oracles;
    @param _strikePrice uint256 representing the price to trigger the depeg event, needs to be the same decimals as the oracle price;
    @param  epochBegin uint256 in UNIX timestamp, representing the begin date of the epoch. Example: Epoch begins in 31/May/2022 at 00h 00min 00sec: 1654038000;
    @param  epochEnd uint256 in UNIX timestamp, representing the end date of the epoch. Example: Epoch ends in 30th June 2022 at 00h 00min 00sec: 1656630000;
    @param  _oracle address representing the smart contract to lookup the price of the given _token param;
    @return insr    address of the deployed hedge vault;
    @return rsk     address of the deployed risk vault;
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
        require(
            IController(controller).getVaultFactory() == address(this),
            "Vault Factory not set in Controller to this address"
        );
        require(controller != address(0), "Controller is not set!");
        require(_strikePrice < 100, "Strike price must be less than 100");
        require(_strikePrice > 10, "Strike price must be greater than 10");

        _strikePrice = _strikePrice * 10e16;

        marketIndex += 1;

        //y2kUSDC_99*RISK or y2kUSDC_99*HEDGE

        Vault hedge = new Vault(
            WETH,
            string(abi.encodePacked(_name,"HEDGE")),
            "hY2K",
            treasury,
            _withdrawalFee,
            _token,
            _strikePrice,
            controller
        );

        Vault risk = new Vault(
            WETH,
            string(abi.encodePacked(_name,"RISK")),
            "rY2K",
            treasury,
            _withdrawalFee,
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

        _createEpoch(marketIndex, epochBegin, epochEnd, hedge, risk);

        return (address(hedge), address(risk));
    }

    /**    
    @notice function to deploy hedge assets for given epochs, after the creation of this vault, where the Index is the date of the end of epoch;
    @param  index uint256 of the market index to create more assets in;
    @param  epochBegin uint256 in UNIX timestamp, representing the begin date of the epoch. Example: Epoch begins in 31/May/2022 at 00h 00min 00sec: 1654038000;
    @param  epochEnd uint256 in UNIX timestamp, representing the end date of the epoch and also the ID for the minting functions. Example: Epoch ends in 30th June 2022 at 00h 00min 00sec: 1656630000;
     */
    function deployMoreAssets(
        uint256 index,
        uint256 epochBegin,
        uint256 epochEnd
    ) public onlyAdmin {
        require(controller != address(0), "Controller is not set!");
        if (index > marketIndex) {
            revert MarketDoesNotExist(index);
        }
        address hedge = indexVaults[index][0];
        address risk = indexVaults[index][1];

        _createEpoch(index, epochBegin, epochEnd, Vault(hedge), Vault(risk));
    }

    function _createEpoch(
        uint256 index,
        uint256 epochBegin,
        uint256 epochEnd,
        Vault hedge,
        Vault risk
    ) internal {
        hedge.createAssets(epochBegin, epochEnd);
        risk.createAssets(epochBegin, epochEnd);

        indexEpochs[index].push(epochEnd);

        emit EpochCreated(
            keccak256(abi.encodePacked(index, epochBegin, epochEnd)),
            index,
            epochBegin,
            epochEnd,
            address(hedge),
            address(risk),
            Vault(hedge).tokenInsured(),
            Vault(hedge).name(),
            Vault(hedge).strikePrice()
        );
    }

    /**
    @notice function to set the controller address;
    @param  _controller address of the controller smart contract;
     */
    function setController(address _controller) public onlyAdmin {
        require(_controller != address(0), "Controller address cannot be 0x0");
        controller = _controller;

        emit controllerSet(_controller);
    }

    /**
    @notice admin function to change fees on running vaults;
    @param _marketIndex uint256 of the market index which to the vaults are associated to;
    @param _fee uint256 of the fee value, multiply your % value by 10, Example: if you want fee of 0.5% , insert 5;
     */
    function changeWithdrawalVaultFee(uint256 _marketIndex, uint256 _fee)
        public
        onlyAdmin
    {
        address[] memory vaults = indexVaults[_marketIndex];
        Vault insr = Vault(vaults[0]);
        Vault risk = Vault(vaults[1]);
        insr.changeWithdrawalFee(_fee);
        risk.changeWithdrawalFee(_fee);

        emit changeWithdrawalFee(_marketIndex, _fee);
    }

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

    function changeController(uint256 _marketIndex, address _controller)
        public
        onlyAdmin
    {
        require(_controller != address(0), "Controller address cannot be 0x0");

        address[] memory vaults = indexVaults[_marketIndex];
        Vault insr = Vault(vaults[0]);
        Vault risk = Vault(vaults[1]);
        insr.changeController(_controller);
        risk.changeController(_controller);

        emit changedController(_marketIndex, _controller);
    }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/

    /**
    @notice function the retrieve the addresses of the hedge and risk vaults, in an array, in the respective order;
    @param index uint256 of the market index which to the vaults are associated to;
    @return vaults address array of two vaults addresses, [0] being the hedge vault, [1] being the risk vault;
     */
    function getVaults(uint256 index)
        public
        view
        returns (address[] memory vaults)
    {
        return indexVaults[index];
    }
}
