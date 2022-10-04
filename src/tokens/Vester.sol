// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {Y2K} from "./Y2K.sol";
import {EscrowedY2K} from "./EscrowedY2K.sol";

contract Vester is AccessControl, Pausable {
    using SafeTransferLib for Y2K;
    using SafeTransferLib for EscrowedY2K;

    EscrowedY2K immutable esY2K;
    Y2K immutable y2k;

    error ZeroAmount();
    error ZeroAddress();

    /**
     * @param _esY2K address Address of EscrowY2K token
     * @param _y2k   address Address of Y2K token
     */
    constructor(address _esY2K, address _y2k) {
        if (_esY2K == address(0) || _y2k == address(0)) revert ZeroAddress();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        //start paused
        _pause();
        esY2K = EscrowedY2K(_esY2K);
        y2k = Y2K(_y2k);
    }

    /**
        @notice Burns escrowed tokens and mints tokens
        @param _amount  uint256  token amount to burn and mint
    */
    function vest(uint256 _amount) external {
        if (_amount == 0) revert ZeroAmount();

        esY2K.safeTransferFrom(msg.sender, address(this), _amount);
        esY2K.burn(_amount);
        y2k.mint(msg.sender, _amount);
    }

    /**
            @notice Set the contract's pause state
            @param _state  bool  Pause state
        */
    function setPauseState(bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_state) {
            _pause();
        } else {
            _unpause();
        }
    }
}
