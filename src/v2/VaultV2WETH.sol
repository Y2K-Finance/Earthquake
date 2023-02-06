// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IWETH} from "./interfaces/IWETH.sol";
import {VaultV2} from "./VaultV2.sol";

/// @author Y2K Finance Team

contract VaultV2WETH is VaultV2 {
    /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
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
        @param  _id  uint256 in UNIX timestamp, representing the end date of the epoch. Example: Epoch ends in 30th June 2022 at 00h 00min 00sec: 1654038000;
        @param _receiver  address of the receiver of the shares provided by this function, that represent the ownership of the deposited asset;
     */
    function depositETH(uint256 _id, address _receiver)
        external
        payable
        epochIdExists(_id)
        epochHasNotStarted(_id)
        nonReentrant
    {
        require(msg.value > 0, "ZeroValue");
        if (_receiver == address(0)) revert AddressZero();

        IWETH(address(asset)).deposit{value: msg.value}();
        _mint(_receiver, _id, msg.value, EMPTY);

        emit Deposit(msg.sender, _receiver, _id, msg.value);
    }
}
