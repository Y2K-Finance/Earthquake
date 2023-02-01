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
    uint256 public minRequired;
    uint256 public relayerFee;
    uint256 public closingTimeFrame;
    address public feeTreasury;


    mapping(address => uint256) public ownerToRollOverQueueIndex;
    QueueItem[] public rolloverQueue;
    QueueItem[] public depositQueue;
    mapping(uint256 => uint256) public rolloverAccounting;

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
        uint256 _relayerFee
    ) VaultV2(_assetAddress,
        _name,
        _symbol,
        _tokenURI,
         _token,
         _strike,
        _controller,
         _treasury) {
        
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

        _asset().safeTransferFrom(
            msg.sender,
            address(this),
            _assets
        );


        // mint logic, either in queue or direct deposit
        if(queueClosed(_id)) {
            uint256 lateDepositFee = _assets; // TODO: calculate late deposit fee 
            uint256 assetsToDeposit = _assets; // TODO: calculate assets to deposit
            _asset().safeTransferFrom(
                msg.sender,
                feeTreasury,
                lateDepositFee
            );
            
            _mint(_receiver, _id, assetsToDeposit, EMPTY);

            emit LateDeposit(msg.sender, _receiver, _id, assetsToDeposit, lateDepositFee);

        } else {
             depositQueue.push(
                QueueItem({
                assets: _assets,
                receiver: _receiver,
                epochId: _id
            })
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
          external virtual
        override(VaultV2)
        epochIdExists(_id)
        epochHasEnded(_id)
        notRollingOver(_owner)
        nonReentrant
        returns (uint256 shares)
    {
        if (_receiver == address(0)) revert AddressZero();

        if (
            msg.sender != _owner &&
            isApprovedForAll(_owner, msg.sender) == false
        ) revert OwnerDidNotAuthorize(msg.sender, _owner);

        _burn(_owner, _id, _assets);

        uint256 entitledShares;

        if (epochNull[_id] == false) {
            entitledShares = previewWithdraw(_id, _assets);
        } else {
            entitledShares = _assets;
        }
        if (entitledShares > 0) {
            SemiFungibleVault.asset.safeTransfer(_receiver, entitledShares);
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
    ) public override notRollingOver(from) {
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
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public override notRollingOver(from) {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }



    /*///////////////////////////////////////////////////////////////
                        Carousel Rollover Logic
    //////////////////////////////////////////////////////////////*/
    
    
    function setRollover(uint256 assets, uint256 _epochId, address _receiver) public epochIdExists(_epochId){
        // check if sender is approved by owner
         if (
            msg.sender != _receiver &&
            isApprovedForAll(_receiver, msg.sender) == false
        ) revert OwnerDidNotAuthorize(msg.sender, _receiver);
        // check if user has enough balance
        if(balanceOf(_receiver, _epochId) < assets) revert InsufficientBalance();
        if(assets < minRequired) revert InsufficientBalance();

        // check if user has already queued up a rollover
        if(ownerToRollOverQueueIndex[msg.sender] != 0) revert AlreadyRollingOver();

        rolloverQueue.push(
            QueueItem({
            assets: assets,
            receiver: msg.sender,
            epochId: _epochId
        })
        );

        ownerToRollOverQueueIndex[msg.sender] = rolloverQueue.length - 1;

        emit RolloverQueued(msg.sender, assets, _epochId);
    }

    function mintDepositInQueue(uint256 _epochId, uint256 _operations) external 
    epochIdExists(_epochId)
    epochHasNotStarted(_epochId)
    nonReentrant 
    {
        // make sure there is already a new epoch set
        // epoch has not started
        QueueItem[] memory queue = depositQueue;
        uint256 length = rolloverQueue.length;

        // revert if queue is empty or operations are more than queue length
        if(length == 0 || _operations > length-1) revert OverflowQueue();

        // queue is executed from the tail to the head
        // get last index of queue
        uint256 i = length - 1;
        while (i > (length - 1) - _operations) {
            _mint(queue[i].receiver, queue[i].epochId, queue[i].assets - relayerFee, EMPTY);
            depositQueue.pop();
            unchecked {
                i--;
            }
        }

        uint256 relayerFee = _operations * relayerFee;

        asset.safeTransfer(
                feeTreasury,
                relayerFee
        );
       
    }

    function mintRollovers(uint256 _epochId, uint256 _operations) external
            epochIdExists(_epochId)
            epochHasNotStarted(_epochId)
            nonReentrant  
        {
            // make sure there is already a new epoch set
            // epoch has not started
            // prev epoch is resolved
            if ( epochResolved[epochs[epochs.length - 2]] && epochs[epochs.length - 1 ] == _epochId) {

                QueueItem[] memory queue = rolloverQueue;
                uint256 length = rolloverQueue.length;
                // revert if queue is empty or operations are more than queue length
                if(length == 0 || _operations > length-1) revert OverflowQueue();
                // account for how many operations have been done
                uint256 index = rolloverAccounting[_epochId];
                while(index < _operations) {
                // only roll over if user won last epoch
                if (previewWithdraw(queue[index].epochId, queue[index].assets) > queue[index].assets) {
                        _burn(queue[index].receiver, queue[index].epochId, queue[index].assets);
                        _mint(queue[index].receiver, _epochId, queue[index].assets - relayerFee, EMPTY);
                        rolloverQueue[index].assets = queue[index].assets - relayerFee;
                        rolloverQueue[index].epochId = _epochId;
                    }
                    index++;
                }

                rolloverAccounting[_epochId] = index;

                uint256 relayerFee = _operations * relayerFee;

                asset.safeTransfer(
                    feeTreasury,
                    relayerFee
                );
            }
        }
    

    function queueClosed(uint256 _epochId) public view returns (bool) {
        if(_epochId == 0) return false;
        else if (block.timestamp + closingTimeFrame >= epochConfig[_epochId].epochBegin) return true;
        else return false;
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

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier minRequiredDeposit(uint256 _assets) {
       if(_assets < relayerFee) revert MinDeposit();
        _;
    }

    modifier notRollingOver(address _owner) {
        if(ownerToRollOverQueueIndex[_owner] != 0) revert AlreadyRollingOver();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error MinDeposit();
    error OverflowQueue();
    error AlreadyRollingOver();
    error InsufficientBalance();
}