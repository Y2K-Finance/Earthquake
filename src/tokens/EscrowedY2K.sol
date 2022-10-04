// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";
import {EscrowedTokenAccessControl} from "./EscrowedTokenAccessControl.sol";

contract EscrowedY2K is EscrowedTokenAccessControl("EscrowedY2K", "esY2K", 18) {
    using SafeTransferLib for EscrowedTokenAccessControl;

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
