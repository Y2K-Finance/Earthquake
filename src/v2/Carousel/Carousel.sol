// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../VaultV2.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
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
    uint256 public minQueueDeposit;
    IERC20 public immutable emissionsToken;

    mapping(address => uint256) public ownerToRollOverQueueIndex;
    QueueItem[] public rolloverQueue;
    QueueItem[] public depositQueue;
    mapping(uint256 => uint256) public rolloverAccounting;
    mapping(uint256 => uint256) public emissions;

    /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /** @notice constructor
        @param _data  Carousel.ConstructorArgs struct containing the data to be used in the constructor;
     */
    constructor(ConstructorArgs memory _data)
        VaultV2(
            _data.isWETH,
            _data.assetAddress,
            _data.name,
            _data.symbol,
            _data.tokenURI,
            _data.token,
            _data.strike,
            _data.controller
        )
    {
        if (_data.relayerFee < 10000) revert RelayerFeeToLow();
        if (_data.depositFee > 250) revert BPSToHigh();
        if (_data.emissionsToken == address(0)) revert AddressZero();
        emissionsToken = IERC20(_data.emissionsToken);
        relayerFee = _data.relayerFee;
        depositFee = _data.depositFee;
        minQueueDeposit = _data.minQueueDeposit;

        // set epoch 0 to be allways available to deposit into Queue
        epochExists[0] = true;
        epochConfig[0] = EpochConfig({
            epochBegin: 10**10 * 40 - 7 days,
            epochEnd: 10**10 * 40,
            epochCreation: uint40(block.timestamp)
        });
        epochs.push(0);
    }

    /*///////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    /** @notice Deposit function
        @dev if receiver intends to deposit into queue and is contract, it must implement 1155 receiver interface otherwise funds will be stuck
        @param  _id epoch id, if 0 deposit will be queued;
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
        minRequiredDeposit(_assets, _id)
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

    function depositETH(uint256 _id, address _receiver)
        external
        payable
        override(VaultV2)
        minRequiredDeposit(msg.value, _id)
        epochIdExists(_id)
        epochHasNotStarted(_id)
        nonReentrant
    {
        if (!isWETH) revert CanNotDepositETH();
        if (_receiver == address(0)) revert AddressZero();

        IWETH(address(asset)).deposit{value: msg.value}();

        uint256 assets = msg.value;

        _deposit(_id, assets, _receiver);
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

        emit WithdrawWithEmissions(
            msg.sender,
            _receiver,
            _owner,
            _id,
            _assets,
            entitledShares,
            entitledEmissions
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
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address, /*from*/
        address, /*to*/
        uint256[] memory, /*ids*/
        uint256[] memory, /*amounts*/
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
    ) public epochIdExists(_epochId) minRequiredDeposit(_assets, _epochId) {
        // check if sender is approved by owner
        if (
            msg.sender != _receiver &&
            isApprovedForAll(_receiver, msg.sender) == false
        ) revert OwnerDidNotAuthorize(msg.sender, _receiver);
        // check if user has enough balance
        if (balanceOf(_receiver, _epochId) < _assets)
            revert InsufficientBalance();
        
        // check if user has already queued up a rollover
        if (isEnlistedInRolloverQueue(_receiver)) {
            uint256 index = getRolloverIndex(_receiver);
            // if so, update the queue
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
            // index will allways be higher than 0
            ownerToRollOverQueueIndex[_receiver] = rolloverQueue.length;
        }
    
        emit RolloverQueued(_receiver, _assets, _epochId);
    }

    /** @notice delists from rollover queue
        @param _owner address that is delisting from rollover queue
     */
    function delistInRollover(address _owner) public {
        // @note 
        // its not possible for users to delete the QueueItem from the array because
        // during rollover, earlier users in rollover queue, can grief attack later users by deleting their queue item
        // instead we just set the assets to 0 and the epochId to 0 as a flag to indicate that the user is no longer in the queue
  

        // check if user is enlisted in rollover queue
        if (!isEnlistedInRolloverQueue(_owner)) revert NoRolloverQueued();
        // check if sender is approved by owner
        if (
            msg.sender != _owner &&
            isApprovedForAll(_owner, msg.sender) == false
        ) revert OwnerDidNotAuthorize(msg.sender, _owner);

        // set assets to 0 but keep the queue item
        uint256 index = getRolloverIndex(_owner);
        rolloverQueue[index].assets = 0;
        rolloverQueue[index].epochId = 0;
        
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
        if (_operations > length) _operations = length;

        // queue is executed from the tail to the head
        // get last index of queue
        uint256 i = length - 1;
        while ((length - _operations) <= i) {
            // this loop impelements FILO (first in last out) stack to reduce gas cost and improve code readability
            // changing it to FIFO (first in first out) would require more code changes and would be more expensive
            // @note non neglectable min-deposit creates barriers for attackers to DDOS the queue

            uint256 assetsToDeposit = queue[i].assets;

            if (depositFee > 0) {
                (uint256 feeAmount, uint256 assetsAfterFee) = getEpochDepositFee(_epochId, assetsToDeposit);
                assetsToDeposit = assetsAfterFee;
                _asset().safeTransfer(treasury(), feeAmount);
            }

            _mintShares(
                queue[i].receiver,
                _epochId,
                assetsToDeposit - relayerFee
            );
            emit Deposit(
                msg.sender,
                queue[i].receiver,
                _epochId,
                assetsToDeposit - relayerFee
            );
            depositQueue.pop();
            if (i == 0) break;
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
        // dont allow rollover if epochId is 0
        if (_epochId == 0) revert InvalidEpochId();

        uint256 length = rolloverQueue.length;
        uint256 index = rolloverAccounting[_epochId];

        // revert if queue is empty or operations are more than queue length
        if (length == 0) revert OverflowQueue();

        if (_operations > length || (index + _operations) > length)
            _operations = length - index;

        // prev epoch is resolved
        if (!epochResolved[epochs[epochs.length - 2]])
            revert EpochNotResolved();

        // make sure epoch is next epoch
        if (epochs[epochs.length - 1] != _epochId) revert InvalidEpochId();

        QueueItem[] memory queue = rolloverQueue;

        // account for how many operations have been done
        uint256 prevIndex = index;
        uint256 executions = 0;

        while ((index - prevIndex) < (_operations)) {

            // only roll over if last epoch is resolved and user rollover position is valid
            if (epochResolved[queue[index].epochId] && queue[index].assets > 0) {

                uint256 entitledAmount = previewWithdraw(
                    queue[index].epochId,
                    queue[index].assets
                );

                // mint only if user won epoch he is rolling over
                if (entitledAmount > queue[index].assets) {
                    // @note previewAmountInShares can only be called if epoch is in profit
                    uint256 relayerFeeInShares = previewAmountInShares(queue[index].epochId, relayerFee);

                    // skip the rollover for the user if the assets cannot cover the relayer fee instead of revert.
                    if (queue[index].assets < relayerFeeInShares) {
                        index++;
                        continue;
                    }

                    // to calculate originalDepositValue get the diff between shares and value of shares 
                    // convert this value amount value back to shares  
                    // subtract from assets
                    uint256 originalDepositValue = queue[index].assets - previewAmountInShares(queue[index].epochId, (entitledAmount - queue[index].assets));
                    // @note we know shares were locked up to this point
                    _burn(
                        queue[index].receiver,
                        queue[index].epochId,
                        originalDepositValue
                    );
                    // @note emission token is a known token which has no before transfer hooks which makes transfer safer
                    emissionsToken.safeTransfer(
                        queue[index].receiver,
                        previewEmissionsWithdraw(
                            queue[index].epochId,
                            originalDepositValue
                        )
                    );

                    emit WithdrawWithEmissions(
                        msg.sender,
                        queue[index].receiver,
                        queue[index].receiver,
                        _epochId,
                        originalDepositValue,
                        entitledAmount,
                        previewEmissionsWithdraw(
                            queue[index].epochId,
                            originalDepositValue
                        )
                    );
                    uint256 assetsToMint = queue[index].assets - relayerFeeInShares;
                    _mintShares(queue[index].receiver, _epochId, assetsToMint);
                    emit Deposit(
                        msg.sender,
                        queue[index].receiver,
                        _epochId,
                        assetsToMint
                    );
                    rolloverQueue[index].assets = assetsToMint;
                    rolloverQueue[index].epochId = _epochId;
                    // only pay relayer for successful mints
                    executions++;
                }
            }
            index++;
        }

        if (executions > 0) rolloverAccounting[_epochId] = index;

        if (executions * relayerFee > 0)
            asset.safeTransfer(msg.sender, executions * relayerFee);

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
    function _deposit(
        uint256 _id,
        uint256 _assets,
        address _receiver
    ) internal {
        // mint logic, either in queue or direct deposit
        if (_id != 0) {
            uint256 assetsToDeposit = _assets;

            if (depositFee > 0) {
                (uint256 feeAmount, uint256 assetsAfterFee) = getEpochDepositFee(_id, _assets);
                assetsToDeposit = assetsAfterFee;
                _asset().safeTransfer(treasury(), feeAmount);
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
    }


    /*///////////////////////////////////////////////////////////////
                        ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

     /**
    @notice This function is called by the controller if the epoch has started, but the counterparty vault has no value. In this case the users can withdraw their deposit. Additionally, emissions are transferred to the treasury. 
    @param  _id uint256 identifier of the epoch
     */
    function setEpochNull(uint256 _id)
        public
        override
        onlyController
        epochIdExists(_id)
        epochHasEnded(_id)
    {
        epochNull[_id] = true;
        if(emissions[_id] > 0)  {
            emissionsToken.safeTransfer(treasury(), emissions[_id]);
            emissions[_id] = 0;
        }
    }


    /** @notice sets emissions
     * @param _epochId epoch id
     * @param _emissionAmount emissions rate
     */
    function setEmissions(uint256 _epochId, uint256 _emissionAmount)
        external
        onlyFactory
        epochIdExists(_epochId)
    {
        emissions[_epochId] = _emissionAmount;
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

    /** @notice cleans up rollover queue
     * @dev this function can only be called if there is no active deposit window
     * @param _addressesToDelist addresses to delist
     */
    function cleanUpRolloverQueue(address[] memory _addressesToDelist ) external onlyFactory epochHasStarted(epochs[epochs.length - 1]) {
        // check that there is no active deposit window;
        for (uint256 i = 0; i < _addressesToDelist.length; i++) {
            address owner = _addressesToDelist[i];
            uint256 index = ownerToRollOverQueueIndex[owner];
            if (index == 0) continue;
            uint256 queueIndex = index - 1;
            if (rolloverQueue[queueIndex].assets == 0) {
                // overwrite the item to be removed with the last item in the queue
                rolloverQueue[queueIndex] = rolloverQueue[rolloverQueue.length - 1];
                // remove the last item in the queue
                rolloverQueue.pop();
                // update the index of prev last user ( mapping index is allways array index + 1)
                ownerToRollOverQueueIndex[rolloverQueue[queueIndex].receiver] = queueIndex + 1;
                // remove receiver from index mapping
                delete ownerToRollOverQueueIndex[owner];
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                        Getter Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice calculates fee percent based on time
     * @param minX min x value
     * @param maxX max x value
     */
    function calculateFeePercent(int256 minX, int256 maxX)
        public
        view
        returns (uint256 _y)
    {
        /**
         * Two Point Form
         * https://www.cuemath.com/geometry/two-point-form/
         * https://ethereum.stackexchange.com/a/143172
         */
        // minY will always be 0 thats why is (maxY - minY) shorten to maxY
        int256 maxY = int256(depositFee) * int256(FixedPointMathLib.WAD);
        _y = uint256( // cast to uint256
            ((((maxY) / (maxX - minX)) * (int256(block.timestamp) - maxX)) +
                maxY) / (int256(FixedPointMathLib.WAD)) // two point math // scale down
        );
    }


    /** @notice returns the rollover index
     * @dev will revert if user is not in rollover queue
     * @param _owner address of the owner
     * @return rollover index
     */
    function getRolloverIndex(address _owner) public view returns (uint256) {
       return ownerToRollOverQueueIndex[_owner] - 1;
    }

    /** @notice retruns deposit fee at this time
     * @param _id epoch id
     * @param _assets amount of assets
     * @return feeAmount fee amount
     * @return _assetsAfterFee assets after fee
    */
    function getEpochDepositFee(uint256 _id, uint256 _assets)
        public
        view
        returns (uint256 feeAmount, uint256 _assetsAfterFee)
    {
        (uint256 maxX, , uint256 minX) = getEpochConfig(_id);
        // deposit fee is calcualted linearly between time of epoch creation and epoch starting (deposit window)
        // this is because late depositors have an informational advantage
        uint256 fee = calculateFeePercent(int256(minX), int256(maxX));
        // min minRequiredDeposit modifier ensures that _assets has high enough value to not devide by 0
        // 0.5% = multiply by 10000 then divide by 50
        feeAmount = _assets.mulDivDown(fee, 10000);
        _assetsAfterFee = _assets - feeAmount;
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

     /** @notice returns the emissions to withdraw
     * @param _id epoch id
     * @param _assets amount of shares
     * @return entitledShareAmount amount of emissions to withdraw
     */
    function previewAmountInShares(uint256 _id, uint256 _assets)
        public
        view
        returns (uint256 entitledShareAmount)
    {
        if(claimTVL[_id] != 0) {
            entitledShareAmount = _assets.mulDivDown(finalTVL[_id], claimTVL[_id]);
        } else {
            entitledShareAmount = 0;
        }
        
    }


    /** @notice returns the deposit queue length
     * @return queue length for the deposit
     */
    function getDepositQueueLength() public view returns (uint256) {
        return depositQueue.length;
    }

    /** @notice returns the queue length for the rollover
     * @return queue length for the rollover
     */
    function getRolloverQueueLength() public view returns (uint256) {
        return rolloverQueue.length;
    }

    /** @notice returns the total value locked in the rollover queue
     * @return tvl total value locked in the rollover queue
     */
    function getRolloverTVL(uint256 _epochId)
        public
        view
        returns (uint256 tvl)
    {
        for (uint256 i = 0; i < rolloverQueue.length; i++) {
            if (
                rolloverQueue[i].epochId == _epochId &&
                (previewWithdraw(
                    rolloverQueue[i].epochId,
                    rolloverQueue[i].assets
                ) > rolloverQueue[i].assets)
            ) {
                tvl += rolloverQueue[i].assets;
            }
        }
    }

    function getRolloverQueueItem(uint256 _index)
        public
        view
        returns (
            address receiver,
            uint256 assets,
            uint256 epochId
        )
    {
        receiver = rolloverQueue[_index].receiver;
        assets = rolloverQueue[_index].assets;
        epochId = rolloverQueue[_index].epochId;
    }

    /** @notice returns users rollover balance and epoch which is rolling over
     * @param _owner address of the user
     * @return balance balance of the user
     * @return epochId epoch id
     */
    function getRolloverPosition(address _owner)
        public
        view
        returns (uint256 balance, uint256 epochId)
    {
        if (!isEnlistedInRolloverQueue(_owner)) {
            return (0, 0);
        }
        uint256 index = getRolloverIndex(_owner);
        balance = rolloverQueue[index].assets;
        epochId = rolloverQueue[index].epochId;
    }


    /** @notice returns is user is enlisted in the rollover queue
     * @param _owner address of the user
     * @return bool is user enlisted in the rollover queue
     */
    function isEnlistedInRolloverQueue(address _owner)
        public
        view
        returns (bool)
    {   
        if(ownerToRollOverQueueIndex[_owner] == 0) {
            return false;
        }
        return rolloverQueue[getRolloverIndex(_owner)].assets != 0;
    }

    /** @notice returns the total value locked in the deposit queue
     * @return tvl total value locked in the deposit queue
     */
    function getDepositQueueTVL() public view returns (uint256 tvl) {
        for (uint256 i = 0; i < depositQueue.length; i++) {
            tvl += depositQueue[i].assets;
        }
    }

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct QueueItem {
        uint256 assets;
        address receiver;
        uint256 epochId;
    }

    struct ConstructorArgs {
        bool isWETH;
        address assetAddress;
        string name;
        string symbol;
        string tokenURI;
        address token;
        uint256 strike;
        address controller;
        address emissionsToken;
        uint256 relayerFee;
        uint256 depositFee;
        uint256 minQueueDeposit;
    }

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /** @notice checks if deposit is greater than relayer fee
     * @param _assets amount of assets to deposit
     */
    modifier minRequiredDeposit(uint256 _assets, uint256 _epochId) {
        if (_epochId == 0 && _assets < minQueueDeposit) revert MinDeposit();
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
        if (isEnlistedInRolloverQueue(_receiver)) {
            QueueItem memory item = rolloverQueue[getRolloverIndex(_receiver)];
            if (
                item.epochId == _epochId &&
                (balanceOf(_receiver, _epochId) - item.assets) < _assets
            ) revert AlreadyRollingOver();
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

    event WithdrawWithEmissions(
        address caller,
        address receiver,
        address indexed owner,
        uint256 indexed id,
        uint256 assets,
        uint256 shares,
        uint256 emissions
    );

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
    event RelayerMinted(uint256 epochId, uint256 operations);

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

}
