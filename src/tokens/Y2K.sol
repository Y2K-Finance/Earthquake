// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {ERC20} from "@solmate/tokens/ERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";

contract Y2K is AccessControl, ERC20("Y2K", "Y2K", 18) {
    bytes32 public constant MINTER_ROLE = "MINTER_ROLE";

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice Mints tokens to account
     * @param  _to     address Account minted to
     * @param  _amount uint256 Amount to mint
     */
    function mint(address _to, uint256 _amount) external onlyRole(MINTER_ROLE) {
        _mint(_to, _amount);
    }

    /**
        @notice Burn tokens
        @param  _amount  uint256  Amount to burn
     */
    function burn(uint256 _amount) external {
        _burn(msg.sender, _amount);
    }
}
