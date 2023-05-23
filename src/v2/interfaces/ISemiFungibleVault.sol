// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISemiFungibleVault {
    function asset() external view returns (IERC20);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function deposit(
        uint256,
        uint256,
        address
    ) external;

    function withdraw(
        uint256,
        uint256,
        address,
        address
    ) external returns (uint256);

    function totalAssets(uint256) external returns (uint256);

    function previewWithdraw(uint256, uint256) external returns (uint256);

    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /** @notice Deposit into vault when event is emitted
     * @param caller Address of deposit caller
     * @param owner receiver who will own of the tokens representing this deposit
     * @param id Vault id
     * @param assets Amount of owner assets to deposit into vault
     */
    event Deposit(
        address caller,
        address indexed owner,
        uint256 indexed id,
        uint256 assets
    );

    /** @notice Withdraw from vault when event is emitted
     * @param caller Address of withdraw caller
     * @param receiver Address of receiver of assets
     * @param owner Owner of shares
     * @param id Vault id
     * @param assets Amount of owner assets to withdraw from vault
     * @param shares Amount of owner shares to burn
     */
    event Withdraw(
        address caller,
        address receiver,
        address indexed owner,
        uint256 indexed id,
        uint256 assets,
        uint256 shares
    );
}
