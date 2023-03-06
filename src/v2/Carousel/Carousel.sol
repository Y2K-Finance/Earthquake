// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../VaultV2.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {CarouselCreator} from "../libraries/CarouselCreator.sol";
import {FixedPointMathLib} from "@solmate/utils/FixedPointMathLib.sol";

/// @author Y2K Finance Team

contract Carousel is VaultV2 {
    using SafeERC20 for IERC20;
    using FixedPointMathLib for uint256;
    /*///////////////////////////////////////////////////////////////
                               IMMUTABLES AND STORAGE
    //////////////////////////////////////////////////////////////*/
    // Earthquake parameters
    uint256 public relayerFee;
    uint256 public depositFee;
    IERC20 public immutable emissionsToken;

    mapping(address => uint256) public ownerToRollOverQueueIndex;
    QueueItem[] public rolloverQueue;
    QueueItem[] public depositQueue;
    mapping(uint256 => uint256) public rolloverAccounting;
    mapping(uint256 => mapping(address => uint256)) public _emissionsBalances;
    mapping(uint256 => uint256) public emissions;

    /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /** @notice constructor
        @param _data  Carousel.ConstructorArgs struct containing the data to be used in the constructor;
     */
    constructor(
        bool _isWETH,
        address _assetAddress,
        string memory _name,
        string memory _symbol,
        string memory _tokenURI,
        address _token,
        uint256 _strike,
        address _controller,
        address _treasury,
        bytes memory _data 
    )
        VaultV2(
            _isWETH,
            _assetAddress,
            _name,
            _symbol,
            _tokenURI,
            _token,
            _strike,
            _controller,
            _treasury
        )
    {
        (uint256 _relayerFee, uint256 _depositFee, address _emissionsToken) = abi.decode(_data, (uint256, uint256, address));
        if(_relayerFee < 10000) revert RelayerFeeToLow();
        if(_depositFee > 250) revert BPSToHigh();
        if(_emissionsToken == address(0)) revert AddressZero();
        emissionsToken = IERC20(_emissionsToken);
        relayerFee = _relayerFee;
        depositFee = _depositFee;

        // set epoch 0 to be allways available to deposit into Queue
        epochExists[0] = true;
        epochConfig[0] = EpochConfig({
            epochBegin: 10**10*40 - 7 days,
            epochEnd: 10**10*40,
            epochCreation: uint40(block.timestamp)
        });
        epochs.push(0);
    }

    /*///////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    /** @notice Deposit function
        @param  _id epoch id
        @param _assets   uint256 of how many assets you want to deposit;
        @param _receiver  address of the receiver of the shares provided by this function, that represent the ownership of the deposited asset;
     */
    function deposit(
        uint256 _id,
        uint256 _assets,
        address _receiver
    )
        public
        override(VaultV2)
        epochIdExists(_id)
        epochHasNotStarted(_id)
        minRequiredDeposit(_assets)
        nonReentrant
    {
        // make sure that epoch exists
        // epoch has not started (valid deposit period)
        // amount is enough to pay for relayer fees in case of queue deposit
        // function is not reentrant
        if (_receiver == address(0)) revert AddressZero();

        _asset().safeTransferFrom(msg.sender, address(this), _assets);
        // handles deposit logic for all cases (direct deposit, late deposit (if activated), queue deposit)
        _deposit(_id, _assets, _receiver);
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
        override(VaultV2)
        epochIdExists(_id)
        epochHasEnded(_id)
        notRollingOver(_owner, _id, _assets)
        nonReentrant
        returns (uint256 shares)
    {
        // make sure that epoch exists
        // epoch is resolved
        // owners funds are not locked in rollover
        // function is not reentrant
        if (_receiver == address(0)) revert AddressZero();

        if (
            msg.sender != _owner &&
            isApprovedForAll(_owner, msg.sender) == false
        ) revert OwnerDidNotAuthorize(msg.sender, _owner);

        _burn(_owner, _id, _assets);
        _burnEmissions(_owner, _id, _assets);
        uint256 entitledShares;
        uint256 entitledEmissions = previewEmissionsWithdraw(_id, _assets);
        if (epochNull[_id] == false) {
            entitledShares = previewWithdraw(_id, _assets);
        } else {
            entitledShares = _assets;
        }
        if (entitledShares > 0) {
            SemiFungibleVault.asset.safeTransfer(_receiver, entitledShares);
        }
        if (entitledEmissions > 0) {
            emissionsToken.safeTransfer(_receiver, entitledEmissions);
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
                        TRANSFER LOGIC
        add notRollingOver modifier to all transfer functions      
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override notRollingOver(from, id, amount) {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
        // emissions transfer
        uint256 fromBalance = _emissionsBalances[id][from];
        require(
            fromBalance >= amount,
            "ERC1155: insufficient balance for transfer"
        );
        unchecked {
            _emissionsBalances[id][from] = fromBalance - amount;
        }
        _emissionsBalances[id][to] += amount;
        emit TransferSingleEmissions(_msgSender(), from, to, id, amount);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address /*from*/,
        address /*to*/,
        uint256[] memory /*ids*/,
        uint256[] memory /*amounts*/,
        bytes memory /*data*/
    ) public pure override {
        revert();
    }

    /*///////////////////////////////////////////////////////////////
                        Carousel Rollover Logic
    //////////////////////////////////////////////////////////////*/

    /** @notice enlists in rollover queue
        @dev user needs to have >= _assets in epoch (_epochId)
        @param  _epochId epoch id
        @param _assets   uint256 of how many assets deposited;
        @param _receiver  address of the receiver of the emissions;
     */
    function enlistInRollover(
        uint256 _epochId,
        uint256 _assets,
        address _receiver
    ) public epochIdExists(_epochId) minRequiredDeposit(_assets) {
        // check if sender is approved by owner
        if (
            msg.sender != _receiver &&
            isApprovedForAll(_receiver, msg.sender) == false
        ) revert OwnerDidNotAuthorize(msg.sender, _receiver);
        // check if user has enough balance
        if (balanceOf(_receiver, _epochId) < _assets)
            revert InsufficientBalance();

        // check if user has already queued up a rollover
        if (ownerToRollOverQueueIndex[_receiver] != 0) {
            // if so, update the queue
            uint256 index = getRolloverIndex(_receiver);
            rolloverQueue[index].assets = _assets;
            rolloverQueue[index].epochId = _epochId;
        } else {
            // if not, add to queue
            rolloverQueue.push(
                QueueItem({
                    assets: _assets,
                    receiver: _receiver,
                    epochId: _epochId
                })
            );
        }
        ownerToRollOverQueueIndex[_receiver] = rolloverQueue.length;

        emit RolloverQueued(_receiver, _assets, _epochId);
    }

    /** @notice delists from rollover queue
        @param _owner address that is delisting from rollover queue
     */
    function delistInRollover(address _owner) public {
        // check if user has already queued up a rollover
        if (ownerToRollOverQueueIndex[_owner] == 0)
            revert NoRolloverQueued();
        // check if sender is approved by owner
        if (
            msg.sender != _owner &&
            isApprovedForAll(_owner, msg.sender) == false
        ) revert OwnerDidNotAuthorize(msg.sender, _owner);

        // swich the last item in the queue with the item to be removed
        uint256 index = getRolloverIndex(_owner);
        uint256 length = rolloverQueue.length;
        if (index == length - 1) {
            // if only one item in queue
            rolloverQueue.pop();
            delete ownerToRollOverQueueIndex[_owner];
        } else {
            // overwrite the item to be removed with the last item in the queue
            rolloverQueue[index] = rolloverQueue[length - 1];
            // remove the last item in the queue
            rolloverQueue.pop();
            // update the index of prev last user ( mapping index is allways array index + 1)
            ownerToRollOverQueueIndex[rolloverQueue[index].receiver] = index+ 1;
            // remove receiver from index mapping
            delete ownerToRollOverQueueIndex[_owner];
        }
    }

    /** @notice mints deposit in rollover queue
        @param _epochId epoch id
        @param _operations  uint256 of how many operations to execute;
     */
    function mintDepositInQueue(uint256 _epochId, uint256 _operations)
        external
        epochIdExists(_epochId)
        epochHasNotStarted(_epochId)
        nonReentrant
    {
        // make sure there is already a new epoch set
        // epoch has not started
        QueueItem[] memory queue = depositQueue;
        uint256 length = depositQueue.length;

        // dont allow minting if epochId is 0
        if (_epochId == 0) revert InvalidEpochId();

        if (length == 0) revert OverflowQueue();
        // relayers can always input a very big number to mint all deposit queues, without the need to read depostQueue length first
        if(_operations > length) _operations = length;

        // queue is executed from the tail to the head
        // get last index of queue
        uint256 i = length - 1;
        while ((length - _operations) <= i) {
            // this loop impelements FILO (first in last out) stack to reduce gas cost and improve code readability
            // changing it to FIFO (first in first out) would require more code changes and would be more expensive
            _mintShares(
                queue[i].receiver,
                _epochId,
                queue[i].assets - relayerFee
            );
            emit Deposit(msg.sender,  queue[i].receiver, _epochId,  queue[i].assets - relayerFee);
            depositQueue.pop();
            if( i == 0 ) break;
            unchecked {
                i--;
            }
        }

        emit RelayerMinted(_epochId, _operations);

        asset.safeTransfer(msg.sender, _operations * relayerFee);
    }

    /** @notice mints for rollovers
        @param _epochId epoch id
        @param _operations  uint256 of how many operations to execute;
     */
    function mintRollovers(uint256 _epochId, uint256 _operations)
        external
        epochIdExists(_epochId)
        epochHasNotStarted(_epochId)
        nonReentrant
    {
        // epoch has not started
        // dont allow minting if epochId is 0
        if (_epochId == 0) revert InvalidEpochId();

        uint256 length = rolloverQueue.length;
        uint256 index = rolloverAccounting[_epochId];

        // revert if queue is empty or operations are more than queue length
        if ( length == 0  ) revert OverflowQueue();

        if( _operations > length || (index + _operations) > length) _operations = length - index;

        // prev epoch is resolved
        if(!epochResolved[epochs[epochs.length - 2]]) revert EpochNotResolved();

        // make sure epoch is next epoch
        if (epochs[epochs.length - 1] != _epochId) revert InvalidEpochId();   

        QueueItem[] memory queue = rolloverQueue;

        // account for how many operations have been done
        uint256 prevIndex = index;
        uint256 executions = 0;
        
        while ((index-prevIndex) < (_operations)) {    
            // only roll over if last epoch is resolved
            if(epochResolved[queue[index].epochId]) {
                uint256 entitledShares = previewWithdraw(
                    queue[index].epochId,
                    queue[index].assets
                );
                // mint only if user won epoch he is rolling over
                if (
                    entitledShares >
                    queue[index].assets
                ) {
                    // skip the rollover for the user if the assets cannot cover the relayer fee instead of revert.
                    if(queue[index].assets < relayerFee) {
                         index++;
                         continue;
                    }
                    // @note we know shares were locked up to this point
                    _burn(
                        queue[index].receiver,
                        queue[index].epochId,
                        queue[index].assets
                    );
                    // transfer emission tokens out of contract otherwise user could not access them as vault shares are burned
                    _burnEmissions(  
                        queue[index].receiver,
                        queue[index].epochId,
                        queue[index].assets
                    );
                    // @note emission token is a known token which has no before transfer hooks which makes transfer safer
                    emissionsToken.safeTransfer(queue[index].receiver, previewEmissionsWithdraw(queue[index].epochId,  queue[index].assets));

                    emit Withdraw(
                        msg.sender,
                        queue[index].receiver,
                        queue[index].receiver,
                        _epochId,
                        queue[index].assets,
                        entitledShares
                    );
                    uint256 assetsToMint = queue[index].assets - relayerFee;
                    _mintShares(
                        queue[index].receiver,
                        _epochId,
                        assetsToMint
                    );
                    emit Deposit(msg.sender,  queue[index].receiver, _epochId, assetsToMint);
                    rolloverQueue[index].assets = assetsToMint;
                    rolloverQueue[index].epochId = _epochId;
                    // only pay relayer for successful mints
                    executions++;
                }
            }
            index++;
        }

        if(executions > 0) rolloverAccounting[_epochId] = index;

        if(executions * relayerFee > 0) asset.safeTransfer(msg.sender, executions * relayerFee);
       
        emit RelayerMinted(_epochId, executions);
    
    }

    /*///////////////////////////////////////////////////////////////
                        INTERNAL MUTATIVE LOGIC
    //////////////////////////////////////////////////////////////*/

    /** @notice deposits assets into epoch
        @param _id epoch id
        @param _assets amount of assets to deposit
        @param _receiver address of receiver
     */
    function _deposit(uint256 _id,  uint256 _assets, address _receiver) internal {
             // mint logic, either in queue or direct deposit
            if(_id != 0){
                uint256 assetsToDeposit = _assets;

                if(depositFee > 0){
                    (uint256 maxX, , uint256 minX)= getEpochConfig(_id);
                    // deposit fee is calcualted linearly between time of epoch creation and epoch starting (deposit window)
                    // this is because late depositors have an informational advantage
                    uint256 fee = _calculateFeePercent(int256(minX), int256(maxX));
                    // min minRequiredDeposit modifier ensures that _assets has high enough value to not devide by 0
                    // 0.5% = multiply by 10000 then divide by 50
                    uint256 feeAmount = _assets.mulDivDown(fee, 10000);
                    assetsToDeposit = _assets - feeAmount;
                    _asset().safeTransfer(treasury, feeAmount);
                }

                _mintShares(_receiver, _id, assetsToDeposit);

                emit Deposit(msg.sender, _receiver, _id, _assets);
        } else {
            depositQueue.push(
                QueueItem({assets: _assets, receiver: _receiver, epochId: _id})
            );

            emit DepositInQueue(msg.sender, _receiver, _id, _assets);
        }
    }

     /**
        * @notice calculates fee percent based on time
        * @param minX min x value
        * @param maxX max x value
     */
    function _calculateFeePercent(
        int256 minX,
        int256 maxX
    ) internal view returns (uint256 _y) {
        /**
         * Two Point Form
         * https://www.cuemath.com/geometry/two-point-form/
         * https://ethereum.stackexchange.com/a/143172
         */
         // minY will always be 0 thats why is (maxY - minY) shorten to maxY
        int256 maxY = int256(depositFee) * int256(FixedPointMathLib.WAD);
        _y = 
        uint256( // cast to uint256
            ((((maxY) / (maxX - minX)) * (int256(block.timestamp) - maxX)) + maxY) // two point math
            / (int256(FixedPointMathLib.WAD)) // scale down 
        );        
    }

    /** @notice mints shares of vault for user
        @param to address of receiver
        @param id epoch id
        @param amount amount of shares to mint
     */
    function _mintShares(
        address to,
        uint256 id,
        uint256 amount 
    ) internal {
        _mint(to, id, amount, EMPTY);
        _mintEmissions(to, id, amount);
    }

    /** @notice mints emission shares based of vault shares for user
        @param to address of receiver
        @param id epoch id
        @param amount amount of shares to mint
     */
    function _mintEmissions(
        address to,
        uint256 id,
        uint256 amount
    ) internal {
        require(to != address(0), "ERC1155: mint to the zero address");

        _emissionsBalances[id][to] += amount;
        emit TransferSingleEmissions(_msgSender(), address(0), to, id, amount);
    }

    /** @notice burns emission shares of vault for user
        @param from address of sender
        @param id epoch id
        @param amount amount of shares to burn
     */
    function _burnEmissions(
        address from,
        uint256 id,
        uint256 amount
    ) internal {
        require(from != address(0), "ERC1155: burn from the zero address");

        uint256 fromBalance = _emissionsBalances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _emissionsBalances[id][from] = fromBalance - amount;
        }

        emit TransferSingleEmissions(
            _msgSender(),
            from,
            address(0),
            id,
            amount
        );
    }

    /*///////////////////////////////////////////////////////////////
                        ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /** @notice sets emissions
        * @param _epochId epoch id
        * @param _emissionsRate emissions rate
     */
    function setEmissions(uint256 _epochId, uint256 _emissionsRate)
        external
        onlyFactory
        epochIdExists(_epochId)
    {
        emissions[_epochId] = _emissionsRate;
    }

    /** @notice changes relayer fee
        * @param _relayerFee relayer fee
     */
    function changeRelayerFee(uint256 _relayerFee) external onlyFactory {
        relayerFee = _relayerFee;
    }

    /** @notice changes deposit fee
        * @param _depositFee deposit fee
     */
    function changeDepositFee(uint256 _depositFee) external onlyFactory {
        depositFee = _depositFee;
    }

    /*///////////////////////////////////////////////////////////////
                        Getter Functions
    //////////////////////////////////////////////////////////////*/

    /** @notice returns the rollover index
        * @param _owner address of the owner
        * @return rollover index
     */
    function getRolloverIndex(address _owner) public view returns (uint256) {
        return ownerToRollOverQueueIndex[_owner] - 1;
    }

    /** @notice returns the emissions to withdraw
        * @param _id epoch id
        * @param _assets amount of assets to withdraw
        * @return entitledAmount amount of emissions to withdraw
     */
    function previewEmissionsWithdraw(uint256 _id, uint256 _assets)
        public
        view
        returns (uint256 entitledAmount)
    {
        entitledAmount = _assets.mulDivDown(emissions[_id], finalTVL[_id]);
    }

    /** @notice returns the deposit queue length
        * @return queue length for the deposit
     */
    function getDepositQueueLenght() public view returns (uint256) {
        return depositQueue.length;
    }

    /** @notice returns the queue length for the rollover
        * @return queue length for the rollover
     */
    function getRolloverQueueLenght() public view returns (uint256) {
        return rolloverQueue.length;
    }

    /** @notice returns the total value locked in the rollover queue
      * @return tvl total value locked in the rollover queue
     */
    function getRolloverTVL( uint256 _epochId ) public view returns(uint256 tvl) {
        for (uint256 i = 0; i < rolloverQueue.length; i++) {
            if(
                rolloverQueue[i].epochId == _epochId && 
                (previewWithdraw(rolloverQueue[i].epochId, rolloverQueue[i].assets) >
                rolloverQueue[i].assets
            )
            ) {
                 tvl += rolloverQueue[i].assets;
            }
           
        }
    }

     /** @notice returns users rollover balance and epoch which is rolling over
        * @param _owner address of the user
        * @return balance balance of the user
        * @return epochId epoch id 
     */
    function getRolloverBalance(address _owner)
        public
        view
        returns (uint256 balance, uint256 epochId)
    {
        balance = rolloverQueue[getRolloverIndex(_owner)].assets;
        epochId = rolloverQueue[getRolloverIndex(_owner)].epochId;
    }

    /** @notice returns the total value locked in the deposit queue
      * @return tvl total value locked in the deposit queue
     */
    function getDepositQueueTVL() public view returns(uint256 tvl) {
        for (uint256 i = 0; i < depositQueue.length; i++) {
            tvl += depositQueue[i].assets;
        }
    }

    /** @notice returns the total emissions balance
      * @return totalEmissions total emissions balance
    */
    function balanceOfEmissions(address _owner, uint256 _id)
        public
        view
        returns (uint256)
    {
        return _emissionsBalances[_id][_owner];
    }

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct QueueItem {
        uint256 assets;
        address receiver;
        uint256 epochId;
    }

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /** @notice checks if deposit is greater than relayer fee
      * @param _assets amount of assets to deposit
     */
    modifier minRequiredDeposit(uint256 _assets) {
        if (_assets < relayerFee) revert MinDeposit();
        _;
    }

    /** @notice checks if not rolling over
        * @param _receiver address of the receiver
        * @param _epochId epoch id
        * @param _assets amount of assets to deposit
     */
    modifier notRollingOver(
        address _receiver,
        uint256 _epochId,
        uint256 _assets
    ) {
        if (ownerToRollOverQueueIndex[_receiver] != 0) {
            QueueItem memory item = rolloverQueue[getRolloverIndex(_receiver)];
            if (item.epochId == _epochId && (balanceOf(_receiver, _epochId) - item.assets) < _assets)
                revert AlreadyRollingOver();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error MinDeposit();
    error OverflowQueue();
    error AlreadyRollingOver();
    error InvalidEpochId();
    error InsufficientBalance();
    error NoRolloverQueued();
    error RelayerFeeToLow();
    error BPSToHigh();
    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /** @notice emitted when a deposit is queued
      * @param sender the address of the sender
      * @param receiver the address of the receiver
      * @param epochId the epoch id
      * @param assets the amount of assets
     */
    event DepositInQueue(
        address indexed sender,
        address indexed receiver,
        uint256 epochId,
        uint256 assets
    );

    /** @notice emitted when shares are minted by relayer
      * @param epochId the epoch id
      * @param operations how many positions were minted
     */
    event RelayerMinted(
        uint256 epochId,
        uint256 operations
    );

    /** @notice emitted when a rollover is queued
        * @param sender the address of the sender
        * @param assets the amount of assets
        * @param epochId the epoch id
     */
    event RolloverQueued(
        address indexed sender,
        uint256 assets,
        uint256 epochId
    );

    /** @notice emitted when emissions are transfered
        * @param operator the address of the operator
        * @param from the address of the sender
        * @param to the address of the receiver
        * @param id the id of the emissions
        * @param value the amount of emissions
     */
    event TransferSingleEmissions(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );
}
