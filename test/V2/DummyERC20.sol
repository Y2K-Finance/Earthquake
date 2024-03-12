// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@solmate/tokens/ERC20.sol";

contract DummyERC20 is ERC20("Y2K Token", "Y2K", 18) {
    function mint(address _to, uint256 _amount) external {
        _mint(_to, _amount);
    }
}
