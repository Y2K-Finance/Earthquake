// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {
    ReentrancyGuard
} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../SemiFungibleVault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {FixedPointMathLib} from "@solmate/utils/FixedPointMathLib.sol";
import {
    ERC1155Holder
} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
/// @author Y2K Finance Team

contract Carousel is ERC1155Holder, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using FixedPointMathLib for uint256;

    /*///////////////////////////////////////////////////////////////
                               IMMUTABLES AND STORAGE
    //////////////////////////////////////////////////////////////*/

    // Earthquake parameters
    uint256 minRequiredDeposit;
    IERC20 asset;
    // Earthquake bussiness logic
    uint256[] public epochs;

    mapping(uint256 => DepositsQueue[])  public rolloverQueue;
    mapping(uint256 => uint256) public rolloverQueueIndex;
    mapping(uint256 => DepositsQueue[])  public depositQueue;

    mapping(uint256 => uint256) public finalTVL;
    mapping(uint256 => uint256) public claimTVL;

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
        address _treasury
    ) SemiFungibleVault(IERC20(_assetAddress), _name, _symbol, _tokenURI) {
        if (_controller == address(0)) revert AddressZero();
        if (_token == address(0)) revert AddressZero();
        if (_assetAddress == address(0)) revert AddressZero();
        if (_treasury == address(0)) revert AddressZero();
        token = _token;
        strike = _strike;
        factory = msg.sender;
        controller = _controller;
        whitelistedAddresses[_treasury] = true;
    }


    /*///////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

     /**
        @param  _id  uint256 in UNIX timestamp, representing the end date of the epoch. Example: Epoch ends in 30th June 2022 at 00h 00min 00sec: 1654038000;
        @param  _assets  uint256 representing how many assets the user wants to deposit, a fee will be taken from this value;
        @param _receiver  address of the receiver of the assets provided by this function, that represent the ownership of the deposited asset;
     */
    function deposit(
        uint256 _epochId,
        uint256 _assets,
        address _receiver
    )
        public
        minRequiredDeposit(_assets)
        nonReentrant
    {
        if (_receiver == address(0)) revert AddressZero();

        asset.safeTransferFrom(
            msg.sender,
            address(this),
            _assets
        );

        // mint logic, either in queue or direct deposit
        if(queueClosed(_epochId)) {
            uint256 lateDepositFee = _assets.mul(5).div(100); // 
            uint256 assetsToDeposit = _assets.sub(lateDepositFee);
            SemiFungibleVault.asset.safeTransfer(
                treasury,
                lateDepositFee
            );
            _deposit(_epochId, assetsToDeposit, address(this));
            
            _mint(_receiver, _epochId, assetsToDeposit, EMPTY);

        } else {
            _depositInQueue(_receiver, _assets);
        }
        

        emit Deposit(msg.sender, _receiver, _epochId, _assets);
    }

     function _depositInQueue(
        uint256 _assets,
        address _receiver
    )
        internal
    {
        
        depositsQueue.push(DepositsQueue({
            assets: _assets,
            receiver: _receiver
        }));

        emit DepositInQueue(msg.sender, _receiver, _assets);
    }


    function mintDepositQueue(uint256 _epochId) external onlyRelayer  {
        if (queueClosed(_epochId) && epochNotStarted(_epochId)) {
            DepositsQueue memory queue = depositsQueue;

           for (uint256 i = queue.length - 1; i == 0; i--) {
                _mint(queue[i].receiver, queue[i].epochId, queue[i].assets, EMPTY);
                epochAccounting[epochId] =+ queue[i].assets;
                depositsQueue.pop();
            }

           if(depositsQueue.length == 0) {
                // relayer fee logic before deposit
                uint256 relayerFee = epochAccounting[epochId].mul(5).div(100);
                uint256 assetsToDeposit = epochAccounting[epochId].sub(relayerFee);

                _deposit(_epochId, assetsToDeposit, address(this));
                emit RelayerDeposit(msg.sender, _epochId, assetsToDeposit, relayerFee);
            }
        }
       
    }

    function mintRolloverQueue(uint256 _epochId) external onlyRelayer  {
        if (queueClosed(_epochId) && epochNotStarted(_epochId)) {
            DepositsQueue memory queue = rolloverQueue;
            if(queue.length == 0) revert QueueEmpty();

            uint256 prevEpochId = epochs[epochs.length - 1];
            for (uint256 i = rolloverQueueIndex[epochId]; i < rolloverQueueIndex[epochId]+maxIterations; i++) {
                _burn(queue[i].receiver, prevEpochId, queue[i].assets, EMPTY)
                _mint(queue[i].receiver, _epochId, queue[i].assets, EMPTY);
                epochRolloverAccounting[epochId] =+ queue[i].assets;
            }

            if(queue.length > maxIterations) {
                rolloverQueueIndex[epochId] =+ maxIterations;
            }

           if(depositsQueue.length == 0) {
                // relayer fee logic before deposit
                uint256 relayerFee = epochRolloverAccounting[epochId].mul(5).div(100);
                uint256 assetsToDeposit = epochRolloverAccounting[epochId].sub(relayerFee);

                _deposit(_epochId, assetsToDeposit, address(this));
                emit RelayerDeposit(msg.sender, _epochId, assetsToDeposit, relayerFee);
           }
        }
    }
    


    /**
        @param  _id  uint256 in UNIX timestamp, representing the end date of the epoch. Example: Epoch ends in 30th June 2022 at 00h 00min 00sec: 1654038000;
        @param  _assets  uint256 representing how many assets the user wants to deposit, a fee will be taken from this value;
        @param _receiver  address of the receiver of the assets provided by this function, that represent the ownership of the deposited asset;
     */
    function _deposit(
        uint256 _id,
        uint256 _assets,
        address _receiver
    )
        intenral
    {
        earthquake.deposit(_id, _assets, _receiver);
        emit Deposit(msg.sender, _receiver, _id, _assets);
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
        override(SemiFungibleVault)
        epochIdExists(_id)
        epochHasEnded(_id)
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

      /**
    @notice Withdraw entitled deposited assets, checking if a depeg event
    @param  _id uint256 identifier of the epoch you want to withdraw from;
    @param _assets   uint256 of how many assets you want to withdraw, this value will be used to calculate how many assets you are entitle to according the vaults claimTVL;
    @param _receiver  Address of the receiver of the assets provided by this function, that represent the ownership of the transfered asset;
    @param _owner    Address of the owner of these said assets;
    @return shares How many shares the owner is entitled to, according to the conditions;
     */
    function _withdraw(
        uint256 _id,
        uint256 _assets,
        address _receiver,
        address _owner
    )
        external
        override(SemiFungibleVault)
        epochIdExists(_id)
        epochHasEnded(_id)
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

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct DepositsQueue {
        uint256 epochId;
        uint256 assets;
        address receiver;
    }

}