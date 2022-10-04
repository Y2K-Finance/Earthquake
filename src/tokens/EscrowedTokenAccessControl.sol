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
     * @return s    bool    if transaction is succesful
     */
    function transfer(address to, uint256 amount)
        public
        override
        onlyRole(TRANSFER_ROLE)
        returns (bool)
    {
        bool s = super.transfer(to, amount);
        return s;
    }

    /**
     * @notice transferFrom function override with access control
     * @param to     address account to recieve tokens
     * @param amount uint256 amount of tokens
     * @return s    bool    if transaction is succesful 

     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override onlyRole(TRANSFER_ROLE) returns (bool) {
        bool s = super.transferFrom(from, to, amount);
        return s;
    }
}
