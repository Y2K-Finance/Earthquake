// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/// @author MiguelBits

contract TimeLock {
    mapping(bytes32 => bool) public queued;

    error NotOwner(address sender);
    error AlreadyQueuedError(bytes32 txId);
    error TimestampNotInRangeError(uint256 blocktimestamp, uint256 timestamp);
    error NotQueuedError(bytes32 txId);
    error TimestampNotPassedError(uint256 blocktimestamp, uint256 timestamp);
    error TimestampExpiredError(uint256 blocktimestamp, uint256 timestamp);
    error TxFailedError(string func);

    event Queue(
        bytes32 indexed txId,
        address indexed target, 
        string func,
        uint index,
        uint data,
        address to,
        address token,
        uint timestamp);

    event Execute(
        bytes32 indexed txId,
        address indexed target, 
        string func,
        uint index,
        uint data,
        address to,
        address token,
        uint timestamp);

    event Delete(
        bytes32 indexed txId,
        address indexed target, 
        string func,
        uint index,
        uint data,
        address to,
        address token,
        uint timestamp);

    /**
     * @dev leave params zero if not using them
     * @notice Queue a transaction
     * @param _target The target contract
     * @param _func The function to call
     * @param _index The market index of the vault to call the function on
     * @param _data The data to pass to the function
     * @param _to The address to change the params to
     * @param _token The token to change the params to
     * @param _timestamp The timestamp to execute the transaction
     */
    function queue(
        address _target, 
        string calldata _func,
        uint256 _index,
        uint256 _data,
        address _to,
        address _token,
        uint256 _timestamp) external{}

    /**
     * @dev leave params zero if not using them
     * @notice Execute a Queued a transaction
     * @param _target The target contract
     * @param _func The function to call
     * @param _index The market index of the vault to call the function on
     * @param _data The data to pass to the function
     * @param _to The address to change the params to
     * @param _token The token to change the params to
     * @param _timestamp The timestamp after which to execute the transaction
     */
    function execute(
        address _target, 
        string calldata _func,
        uint256 _index,
        uint256 _data,
        address _to,
        address _token,
        uint256 _timestamp) external {}

    function cancel(
        address _target, 
        string calldata _func,
        uint256 _index,
        uint256 _data,
        address _to,
        address _token,
        uint256 _timestamp) external {}

    function getTxId(address _target, 
        string calldata _func,
        uint _index,
        uint _data,
        address _to,
        address _token,
        uint _timestamp
    ) public pure returns (bytes32 txId){}

    function compareStringsbyBytes(string memory s1, string memory s2) external pure returns(bool){}

    function changeOwner(address _newOwner) external{}
}


contract IVaultFactory {

    /*//////////////////////////////////////////////////////////////
                                MAPPINGS
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address[]) public indexVaults; //[0] hedge and [1] risk vault
    mapping(uint256 => uint256[]) public indexEpochs; //all epochs in the market
    mapping(address => address) public tokenToOracle; //token address to respective oracle smart contract address

    /*//////////////////////////////////////////////////////////////
                                ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
    @notice Function to create two new vaults, hedge and risk, with the respective params, and storing the oracle for the token provided
    @param _withdrawalFee uint256 of the fee value, multiply your % value by 10, Example: if you want fee of 0.5% , insert 5
    @param _token Address of the oracle to lookup the price in chainlink oracles
    @param _strikePrice uint256 representing the price to trigger the depeg event, needs to be 18 decimals
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
    ) public returns (address insr, address rsk) {
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
    ) public {
        
    }

    /**
    @notice Admin function, sets the controller address
    @param  _controller Address of the controller smart contract
     */
    function setController(address _controller) public  {

    }

    /**
    @notice Admin function, changes the assigned treasury address
    @param _treasury Treasury address
    @param  _marketIndex Target market index
     */
    function changeTreasury(address _treasury, uint256 _marketIndex)
        public
        
    {
    
    }

    /**
    @notice Admin function, changes vault time window
    @param _marketIndex Target market index
    @param  _timewindow New time window
     */
    function changeTimewindow(uint256 _marketIndex, uint256 _timewindow)
        public
        
    {
        
    }

    /**
    @notice Admin function, changes controller address
    @param _marketIndex Target market index
    @param  _controller Address of the controller smart contract
     */
    function changeController(uint256 _marketIndex, address _controller)
        public
    {
        
    }

    /**
    @notice Admin function, changes oracle address for a given token
    @param _token Target token address
    @param  _oracle Oracle address
     */
    function changeOracle(address _token, address _oracle) public {

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
    }
}
