// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IWETH} from "./interfaces/IWETH.sol";
import {VaultV2} from "./VaultV2.sol";

/// @author Y2K Finance Team

contract VaultV2WETH is VaultV2 {
    /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /** @notice constructor
        @param _assetAddress  address of the asset to be deposited;
        @param _name  string representing the name of the vault;
        @param _symbol  string representing the symbol of the vault;
        @param _tokenURI  string representing the tokenURI of the vault;
        @param _token  address of the token to be used as a reward for the stakers;
        @param _strikePrice  uint256 representing the strike price of the vault;
        @param _controller  address of the controller of the vault;
        @param _treasury  address of the treasury of the vault;
     */
    constructor(
        bool isWETH,
        address _assetAddress,
        string memory _name,
        string memory _symbol,
        string memory _tokenURI,
        address _token,
        uint256 _strikePrice,
        address _controller,
        address _treasury
    )
        VaultV2(
            isWETH,
            _assetAddress,
            _name,
            _symbol,
            _tokenURI,
            _token,
            _strikePrice,
            _controller,
            _treasury
        )
    {}

    /**
        @notice Deposit ETH function
        @param  _id  uint256 representing the id of the epoch;
        @param _receiver  address of the receiver of the shares provided by this function, that represent the ownership of the deposited asset;
     */
    function depositETH(uint256 _id, address _receiver)
        external
        payable
        epochIdExists(_id)
        epochHasNotStarted(_id)
        nonReentrant
    {

        if(!isWETH) revert CanNotDepositETH();
        require(msg.value > 0, "ZeroValue");
        if (_receiver == address(0)) revert AddressZero();

        IWETH(address(asset)).deposit{value: msg.value}();
        _mint(_receiver, _id, msg.value, EMPTY);

        emit Deposit(msg.sender, _receiver, _id, msg.value);
    }

    error CanNotDepositETH();
}
