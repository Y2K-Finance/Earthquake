// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC20} from "@solmate/tokens/ERC20.sol";

contract MintableToken is ERC20 {
    constructor(string memory name, string memory symbol)
        ERC20(name, symbol, 18)
    {}

    function moneyPrinterGoesBrr(address _sender) public {
        _mint(_sender, 100 ether);
    }

    function mint(address _sender) public {
        _mint(_sender, 100 ether);
    }

    function mint(address _sender, uint256 _amount) public {
        _mint(_sender, _amount * 1 ether);
    }
}
