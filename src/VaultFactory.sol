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
    error AddressNotAdmin(address addr);
    error AddressZero();
    error AddressNotController();
    error AddressFactoryNotInController();
    error StrikePriceGreaterThan100(int256 strikePrice);
    error StrikePriceLesserThan10(int256 strikePrice);
    error ControllerNotSet();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event MarketCreated(
        uint256 indexed mIndex,
        address hedge,
        address risk,
        address token,
        string name,
        int256 strikePrice
    );

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

    event controllerSet(address indexed newController);

    event changedTreasury(address _treasury, uint256 indexed _marketIndex);
    event changedVaultFee(uint256 indexed _marketIndex, uint256 _feeRate);
    event changedTimeWindow(uint256 indexed _marketIndex, uint256 _timeWindow);
    event changedController(
        uint256 indexed _marketIndex,
        address indexed controller
    );
    event changeOracle(address indexed _token, address _oracle);

    /*//////////////////////////////////////////////////////////////
                                MAPPINGS
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address[]) public indexVaults; //[0] hedge and [1] risk vault
    mapping(uint256 => uint256[]) public indexEpochs; //all epochs in the market
    mapping(address => address) public tokenToOracle; //token address to respective oracle smart contract address

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyAdmin() {
        if(msg.sender != Admin)
            revert AddressNotAdmin(msg.sender);
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

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
        if(
            IController(controller).getVaultFactory() != address(this)
            )
            revert AddressFactoryNotInController();

        if(controller == address(0))
            revert ControllerNotSet();

        if(_strikePrice > 100)
            revert StrikePriceGreaterThan100(_strikePrice);

        if(_strikePrice < 10)
            revert StrikePriceLesserThan10(_strikePrice);

        _strikePrice = _strikePrice * 10e16;

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

        _createEpoch(marketIndex, epochBegin, epochEnd, hedge, risk, _withdrawalFee);

        return (address(hedge), address(risk));
    }

    /**    
    @notice function to deploy hedge assets for given epochs, after the creation of this vault, where the Index is the date of the end of epoch;
    @param  index uint256 of the market index to create more assets in;
    @param  epochBegin uint256 in UNIX timestamp, representing the begin date of the epoch. Example: Epoch begins in 31/May/2022 at 00h 00min 00sec: 1654038000;
    @param  epochEnd uint256 in UNIX timestamp, representing the end date of the epoch and also the ID for the minting functions. Example: Epoch ends in 30th June 2022 at 00h 00min 00sec: 1656630000;
    @param _withdrawalFee uint256 of the fee value, multiply your % value by 10, Example: if you want fee of 0.5% , insert 5;
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

        _createEpoch(index, epochBegin, epochEnd, Vault(hedge), Vault(risk), _withdrawalFee);
    }

    function _createEpoch(
        uint256 index,
        uint256 epochBegin,
        uint256 epochEnd,
        Vault hedge,
        Vault risk,
        uint256 _withdrawalFee
    ) internal {
        hedge.createAssets(epochBegin, epochEnd, _withdrawalFee);
        risk.createAssets(epochBegin, epochEnd, _withdrawalFee);

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
            Vault(hedge).strikePrice(),
            _withdrawalFee
        );
    }

    /**
    @notice function to set the controller address;
    @param  _controller address of the controller smart contract;
     */
    function setController(address _controller) public onlyAdmin {
        if(_controller == address(0))
            revert AddressZero();
        controller = _controller;

        emit controllerSet(_controller);
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
        if(_controller == address(0))
            revert AddressZero();

        address[] memory vaults = indexVaults[_marketIndex];
        Vault insr = Vault(vaults[0]);
        Vault risk = Vault(vaults[1]);
        insr.changeController(_controller);
        risk.changeController(_controller);

        emit changedController(_marketIndex, _controller);
    }

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
