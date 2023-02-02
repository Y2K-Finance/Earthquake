// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../VaultV2.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @author Y2K Finance Team

contract Carousel is VaultV2 {
    using SafeERC20 for IERC20;
    using FixedPointMathLib for uint256;
    /*///////////////////////////////////////////////////////////////
                               IMMUTABLES AND STORAGE
    //////////////////////////////////////////////////////////////*/
    // Earthquake parameters
    uint256 public relayerFee;
    uint256 public closingTimeFrame;
    address public feeTreasury;
    IERC20 public emissionsToken;

    mapping(address => uint256) public ownerToRollOverQueueIndex;
    QueueItem[] public rolloverQueue;
    QueueItem[] public depositQueue;
    mapping(uint256 => uint256) public rolloverAccounting;
    mapping(uint256 => mapping(address => uint256)) private _emissionsBalances;
    mapping(uint256 => uint256) private emissions;

    /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        address _assetAddress,
        string memory _name,
        string memory _symbol,
        string memory _tokenURI,
        address _token,
        uint256 _strike,
        address _controller,
        address _treasury,
        address _feeTreasury,
        address _emissionsToken,
        uint256 _relayerFee
    )
        VaultV2(
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
        emissionsToken = IERC20(_emissionsToken);
        relayerFee = _relayerFee;
        feeTreasury = _feeTreasury;
    }

    /*///////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function deposit(
        uint256 _id,
        uint256 _assets,
        address _receiver
    )
        public
        override(VaultV2)
        minRequiredDeposit(_assets)
        epochIdExists(_id)
        epochHasNotStarted(_id)
        nonReentrant
    {
        if (_receiver == address(0)) revert AddressZero();

        _asset().safeTransferFrom(msg.sender, address(this), _assets);

        // mint logic, either in queue or direct deposit
        if (queueClosed(_id)) {
            uint256 lateDepositFee = _assets; // TODO: calculate late deposit fee
            uint256 assetsToDeposit = _assets; // TODO: calculate assets to deposit
            _asset().safeTransfer(feeTreasury, lateDepositFee);

            _mint(_receiver, _id, assetsToDeposit, EMPTY);

            emit LateDeposit(
                msg.sender,
                _receiver,
                _id,
                assetsToDeposit,
                lateDepositFee
            );
        } else {
            depositQueue.push(
                QueueItem({assets: _assets, receiver: _receiver, epochId: _id})
            );

            emit DepositInQueue(msg.sender, _receiver, _id, _assets);
        }
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
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public override {
        revert();
    }

    /*///////////////////////////////////////////////////////////////
                        Carousel Rollover Logic
    //////////////////////////////////////////////////////////////*/

    function enListInRollover(
        uint256 _assets,
        uint256 _epochId,
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

    function deListInRollover(address _receiver) public {
        // check if user has already queued up a rollover
        if (ownerToRollOverQueueIndex[_receiver] == 0)
            revert NoRolloverQueued();
        // check if sender is approved by owner
        if (
            msg.sender != _receiver &&
            isApprovedForAll(_receiver, msg.sender) == false
        ) revert OwnerDidNotAuthorize(msg.sender, _receiver);

        // swich the last item in the queue with the item to be removed
        uint256 index = getRolloverIndex(_receiver);
        if (index == rolloverQueue.length - 1) {
            rolloverQueue.pop();
            delete ownerToRollOverQueueIndex[_receiver];
        } else {
            // overwrite the item to be removed with the last item in the queue
            rolloverQueue[index] = rolloverQueue[rolloverQueue.length - 1];
            // remove the last item in the queue
            rolloverQueue.pop();
            // update the index of prev last user
            ownerToRollOverQueueIndex[rolloverQueue[index].receiver] = index;
            // remove receiver from index mapping
            delete ownerToRollOverQueueIndex[_receiver];
        }
    }

    function mintDepositInQueue(uint256 _epochId, uint256 _operations)
        external
        epochIdExists(_epochId)
        epochHasNotStarted(_epochId)
        nonReentrant
    {
        // make sure there is already a new epoch set
        // epoch has not started
        QueueItem[] memory queue = depositQueue;
        uint256 length = rolloverQueue.length;

        // revert if queue is empty or operations are more than queue length
        if (length == 0 || _operations > length - 1) revert OverflowQueue();

        // queue is executed from the tail to the head
        // get last index of queue
        uint256 i = length - 1;
        while (i > (length - 1) - _operations) {
            _mint(
                queue[i].receiver,
                queue[i].epochId,
                queue[i].assets - relayerFee,
                EMPTY
            );
            depositQueue.pop();
            unchecked {
                i--;
            }
        }

        asset.safeTransfer(feeTreasury, _operations * relayerFee);
    }

    function mintRollovers(uint256 _epochId, uint256 _operations)
        external
        epochIdExists(_epochId)
        epochHasNotStarted(_epochId)
        nonReentrant
    {
        // make sure there is already a new epoch set
        // epoch has not started
        // prev epoch is resolved
        if (
            epochResolved[epochs[epochs.length - 2]] &&
            epochs[epochs.length - 1] == _epochId
        ) {
            QueueItem[] memory queue = rolloverQueue;
            uint256 length = rolloverQueue.length;
            // revert if queue is empty or operations are more than queue length
            if (length == 0 || _operations > length - 1) revert OverflowQueue();
            // account for how many operations have been done
            uint256 index = rolloverAccounting[_epochId];
            while (index < _operations) {
                // only roll over if user won last epoch
                if (
                    previewWithdraw(queue[index].epochId, queue[index].assets) >
                    queue[index].assets
                ) {
                    _burn(
                        queue[index].receiver,
                        queue[index].epochId,
                        queue[index].assets
                    );
                    _mint(
                        queue[index].receiver,
                        _epochId,
                        queue[index].assets - relayerFee,
                        EMPTY
                    );
                    rolloverQueue[index].assets =
                        queue[index].assets -
                        relayerFee;
                    rolloverQueue[index].epochId = _epochId;
                }
                index++;
            }

            rolloverAccounting[_epochId] = index;

            asset.safeTransfer(feeTreasury, _operations * relayerFee);
        }
    }

    function queueClosed(uint256 _epochId) public view returns (bool) {
        if (_epochId == 0) return false;
        else if (
            block.timestamp + closingTimeFrame >=
            epochConfig[_epochId].epochBegin
        ) return true;
        else return false;
    }

    /*///////////////////////////////////////////////////////////////
                        INTERNAL MUTATIVE LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal override {
        _mint(to, id, amount, data);
        _mintEmissoins(to, id, amount, data);
    }

    function _mintEmissoins(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal {
        require(to != address(0), "ERC1155: mint to the zero address");

        _emissionsBalances[id][to] += amount;
        emit TransferSingleEmissions(_msgSender(), address(0), to, id, amount);
    }

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

    function setEmissions(uint256 _epochId, uint256 _emissionsRate)
        external
        onlyFactory
        epochIdExists(_epochId)
    {
        emissions[_epochId] = _emissionsRate;
    }

    /*///////////////////////////////////////////////////////////////
                        Getter Functions
    //////////////////////////////////////////////////////////////*/

    function getRolloverIndex(address _owner) internal view returns (uint256) {
        return ownerToRollOverQueueIndex[_owner] - 1;
    }

    function previewEmissionsWithdraw(uint256 _id, uint256 _assets)
        public
        view
        returns (uint256 entitledAmount)
    {
        entitledAmount = _assets.mulDivUp(emissions[_id], emissions[_id]);
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

    modifier minRequiredDeposit(uint256 _assets) {
        if (_assets < relayerFee) revert MinDeposit();
        _;
    }

    modifier notRollingOver(
        address _receiver,
        uint256 _epochId,
        uint256 _assets
    ) {
        if (ownerToRollOverQueueIndex[_receiver] != 0) {
            QueueItem memory item = rolloverQueue[getRolloverIndex(_receiver)];
            if (item.epochId == _epochId && item.assets < _assets)
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
    error InsufficientBalance();
    error NoRolloverQueued();

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event DepositInQueue(
        address indexed sender,
        address indexed receiver,
        uint256 epochId,
        uint256 assets
    );

    event LateDeposit(
        address indexed sender,
        address indexed receiver,
        uint256 epochId,
        uint256 assets,
        uint256 lateDepositFee
    );

    event RolloverQueued(
        address indexed sender,
        uint256 assets,
        uint256 epochId
    );

    event TransferSingleEmissions(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );
}
