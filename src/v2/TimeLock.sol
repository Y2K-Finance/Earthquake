import {IVaultFactoryV2} from "./interfaces/IVaultFactoryV2.sol";

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract TimeLock {
    mapping(bytes32 => bool) public queued;

    address public policy;

    uint32 public constant MIN_DELAY = 3 days;
    uint32 public constant MAX_DELAY = 30 days;
    uint32 public constant GRACE_PERIOD = 14 days;

    error NotOwner(address sender);
    error AlreadyQueuedError(bytes32 txId);
    error TimestampNotInRangeError(uint256 blocktimestamp, uint256 timestamp);
    error NotQueuedError(bytes32 txId);
    error TimestampNotPassedError(uint256 blocktimestamp, uint256 timestamp);
    error TimestampExpiredError(uint256 blocktimestamp, uint256 timestamp);
    error TxFailedError(string func);

    /** @notice queues transaction when emitted
        @param txId unique id of the transaction
        @param target contract to call
        @param func function to call
        @param index market index of the vault to call the function on
        @param data data to pass to the function
        @param to address to change the params to
        @param token token to change the params to
        @param timestamp timestamp to execute the transaction
     */
    event Queue(
        bytes32 indexed txId,
        address indexed target,
        string func,
        uint256 index,
        uint256 data,
        address to,
        address token,
        uint256 timestamp
    );

    /** @notice executes transaction when emitted
        @param txId unique id of the transaction
        @param target contract to call
        @param func function to call
        @param index market index of the vault to call the function on
        @param data data to pass to the function
        @param to address to change the params to
        @param token token to change the params to
        @param timestamp timestamp to execute the transaction
     */
    event Execute(
        bytes32 indexed txId,
        address indexed target,
        string func,
        uint256 index,
        uint256 data,
        address to,
        address token,
        uint256 timestamp
    );

    /** @notice deletes transaction when emitted
        @param txId unique id of the transaction
        @param target contract to call
        @param func function to call
        @param index market index of the vault to call the function on
        @param data data to pass to the function
        @param to address to change the params to
        @param token token to change the params to
        @param timestamp timestamp to execute the transaction
     */
    event Delete(
        bytes32 indexed txId,
        address indexed target,
        string func,
        uint256 index,
        uint256 data,
        address to,
        address token,
        uint256 timestamp
    );

    /** @notice only owner can call functions with this modifier
     */
    modifier onlyOwner() {
        if (msg.sender != policy) revert NotOwner(msg.sender);
        _;
    }

    /** @notice constructor
        @param _policy  address of the policy contract;
      */
    constructor(address _policy) {
        policy = _policy;
    }

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
        uint256 _timestamp
    ) external onlyOwner {
        //create tx id
        bytes32 txId = getTxId(
            _target,
            _func,
            _index,
            _data,
            _to,
            _token,
            _timestamp
        );

        //check tx id unique
        if (queued[txId]) {
            revert AlreadyQueuedError(txId);
        }

        //check timestamp
        if (
            _timestamp < block.timestamp + MIN_DELAY ||
            _timestamp > block.timestamp + MAX_DELAY
        ) {
            revert TimestampNotInRangeError(block.timestamp, _timestamp);
        }

        //queue tx
        queued[txId] = true;

        emit Queue(
            txId,
            _target,
            _func,
            _index,
            _data,
            _to,
            _token,
            _timestamp
        );
    }

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
        uint256 _timestamp
    ) external onlyOwner {
        bytes32 txId = getTxId(
            _target,
            _func,
            _index,
            _data,
            _to,
            _token,
            _timestamp
        );

        //check tx id queued
        if (!queued[txId]) {
            revert NotQueuedError(txId);
        }

        //check block.timestamp > timestamp
        if (block.timestamp < _timestamp) {
            revert TimestampNotPassedError(block.timestamp, _timestamp);
        }
        if (block.timestamp > _timestamp + GRACE_PERIOD) {
            revert TimestampExpiredError(
                block.timestamp,
                _timestamp + GRACE_PERIOD
            );
        }

        //delete tx from queue
        queued[txId] = false;

        //execute tx
        // if (compareStringsbyBytes(_func, "changeTreasury")) {
        //     IVaultFactoryV2(_target).changeTreasury(_to, _index);
        // } else if (compareStringsbyBytes(_func, "changeController")) {
        //     IVaultFactoryV2(_target).changeController(_index, _to);
        // } else if (compareStringsbyBytes(_func, "changeOracle")) {
        //     IVaultFactoryV2(_target).changeOracle(_token, _to);
        // } else {
        //     revert TxFailedError(_func);
        // }

        emit Execute(
            txId,
            _target,
            _func,
            _index,
            _data,
            _to,
            _token,
            _timestamp
        );
    }

    /** @notice cancels the transaction
        *  @param _target The target contract
        *  @param _func The function to call
        *  @param _index The market index of the vault to call the function on
        *  @param _data The data to pass to the function
        *  @param _to The address to change the params to
        *  @param _token The token to change the params to
        *  @param _timestamp The timestamp after which to execute the transaction
     */
    function cancel(
        address _target,
        string calldata _func,
        uint256 _index,
        uint256 _data,
        address _to,
        address _token,
        uint256 _timestamp
    ) external onlyOwner {
        bytes32 txId = getTxId(
            _target,
            _func,
            _index,
            _data,
            _to,
            _token,
            _timestamp
        );

        //check tx id queued
        if (!queued[txId]) {
            revert NotQueuedError(txId);
        }

        //delete tx from queue
        queued[txId] = false;

        emit Delete(
            txId,
            _target,
            _func,
            _index,
            _data,
            _to,
            _token,
            _timestamp
        );
    }

    /** @notice get transaction id
        *  @param _target The target contract
        *  @param _func The function to call
        *  @param _index The market index of the vault to call the function on
        *  @param _data The data to pass to the function
        *  @param _to The address to change the params to
        *  @param _token The token to change the params to
        *  @param _timestamp The timestamp after which to execute the transaction
        *  @return txId
     */
    function getTxId(
        address _target,
        string calldata _func,
        uint256 _index,
        uint256 _data,
        address _to,
        address _token,
        uint256 _timestamp
    ) public pure returns (bytes32 txId) {
        return
            keccak256(
                abi.encode(
                    _target,
                    _func,
                    _index,
                    _data,
                    _to,
                    _token,
                    _timestamp
                )
            );
    }

    /** @notice compare strings by bytes
        *  @param s1 string 1
        *  @param s2 string 2
        *  @return bool
     */
    function compareStringsbyBytes(string memory s1, string memory s2)
        public
        pure
        returns (bool)
    {
        return
            keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }

    /** @notice change owner
        *  @param _newOwner new owner
    */
    function changeOwner(address _newOwner) external onlyOwner {
        policy = _newOwner;
    }

    // TODO change owner on factory no queue
}
