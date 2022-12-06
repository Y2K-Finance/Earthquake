// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {ERC20} from "@solmate/tokens/ERC20.sol";

contract Y2K is ERC20("Y2K", "Y2K", 18) {
    error ZeroAddress();
    error ZeroAmount();

    constructor(uint256 _amount, address _reciever) {
        if (_amount == 0) revert ZeroAmount();
        if (_reciever == address(0)) revert ZeroAddress();

        _mint(_reciever, _amount);
    }

    /**
            @notice Burn tokens
            @param  _amount  uint256  Amount to burn
         */
    function burn(uint256 _amount) external {
        _burn(msg.sender, _amount);
    }
}
