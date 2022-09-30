// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {ERC20} from "@solmate/tokens/ERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";

abstract contract EscrowedTokenAccessControl is ERC20, AccessControl {
    bytes32 public constant TRANSFER_ROLE = "TRANSFER_ROLE";

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) ERC20(_name, _symbol, _decimals) {}

    /**
     * @notice Transfer function override with access control
     * @param to     address account to recieve tokens
     * @param amount uint256 amount of tokens
     */
    function transfer(address to, uint256 amount)
        public
        override
        onlyRole(TRANSFER_ROLE)
        returns (bool)
    {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    /**
     * @notice transferFrom function override with access control
     * @param to     address account to recieve tokens
     * @param amount uint256 amount of tokens
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override onlyRole(TRANSFER_ROLE) returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max)
            allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }
}
