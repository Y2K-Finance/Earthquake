// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {ERC20} from "@solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "@solmate/utils/FixedPointMathLib.sol";
import {
    ERC1155Supply
} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

abstract contract SemiFungibleVault is ERC1155Supply {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /*///////////////////////////////////////////////////////////////
                               IMMUTABLES AND STORAGE
    //////////////////////////////////////////////////////////////*/
    ERC20 public immutable asset;
    string public name;
    string public symbol;
    bytes internal constant EMPTY = "";

    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    
    /** @notice Deposit into vault when event is emitted
      * @param caller to-do
      * @param owner to-do
      * @param id to-do
      * @param assets to-do
      * @param shares to-do
      */ 
    event Deposit(
        address caller,
        address indexed owner,
        uint256 indexed id,
        uint256 assets,
        uint256 shares
    );

    /** @notice Withdraw from vault when event is emitted
      * @param caller to-do
      * @param receiver to-do
      * @param owner to-do
      * @param id to-do
      * @param assets to-do
      * @param shares to-do
      */ 
    event Withdraw(
        address caller,
        address receiver,
        address indexed owner,
        uint256 indexed id,
        uint256 assets,
        uint256 shares
    );

    /** @notice Contract constructor
      * @param _asset ERC20 token
      * @param _name Token name
      * @param _symbol Token symbol 
      */ 
    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol
    ) ERC1155("") {
        asset = _asset;
        name = _name;
        symbol = _symbol;
    }

    /*///////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    /** @notice Triggers deposit into vault and mints shares for receiver
      * @param id Vault id
      * @param assets Amount of tokens to deposit
      * @param receiver Receiver of shares
      */ 
    function deposit(
        uint256 id,
        uint256 assets,
        address receiver
    ) public virtual returns (uint256 shares) {
        // Check for rounding error since we round down in previewDeposit.
        require((shares = previewDeposit(id, assets)) != 0, "ZERO_SHARES");

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, id, shares, EMPTY);

        emit Deposit(msg.sender, receiver, id, assets, shares);

        afterDeposit(id, assets, shares);
    }

    /** @notice Triggers withdraw from vault and burns receivers' shares
      * @param id Vault id
      * @param assets Amount of tokens to withdraw
      * @param receiver Receiver of shares
      */ 
    function withdraw(
        uint256 id,
        uint256 assets,
        address receiver,
        address owner
    ) external virtual returns (uint256 shares) {
        require(
            msg.sender == owner || isApprovedForAll(owner, receiver),
            "Only owner can withdraw, or owner has approved receiver for all"
        );

        shares = previewWithdraw(id, assets); // No need to check for rounding error, previewWithdraw rounds up.

        beforeWithdraw(id, assets, shares);
        _burn(owner, id, shares);

        emit Withdraw(msg.sender, receiver, owner, id, assets, shares);
        asset.safeTransfer(receiver, assets);
    }

    /*///////////////////////////////////////////////////////////////
                           ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
        @notice returns total assets for token
        @param  _id uint256 token id of token
     */
    function totalAssets(uint256 _id) public view virtual returns (uint256);

    /**
        @notice converts assets to shares
        @param  id uint256 token id of token
        @param assets total number of assets
     */
    function convertToShares(uint256 id, uint256 assets)
        public
        view
        virtual
        returns (uint256)
    {
        uint256 supply = totalSupply(id); // Saves an extra SLOAD if totalSupply is non-zero.

        return
            supply == 0 ? assets : assets.mulDivDown(supply, totalAssets(id));
    }

    /** @notice converts shares to assets
        @param  id uint256 token id of token
        @param shares total number of shares
     */
    function convertToAssets(uint256 id, uint256 shares)
        public
        view
        virtual
        returns (uint256)
    {
        uint256 supply = totalSupply(id); // Saves an extra SLOAD if totalSupply is non-zero.
        return
            supply == 0 ? shares : shares.mulDivDown(totalAssets(id), supply);
    }

     /**
        @notice shows shares conversion output from depositing assets
        @param  id uint256 token id of token
        @param assets total number of assets
     */
    function previewDeposit(uint256 id, uint256 assets)
        public
        view
        virtual
        returns (uint256)
    {
        return convertToShares(id, assets);
    }

     /**
        @notice shows shares conversion output from minting shares
        @param  id uint256 token id of token
        @param shares total number of shares
     */
    function previewMint(uint256 id, uint256 shares)
        public
        view
        virtual
        returns (uint256)
    {
        uint256 supply = totalSupply(id); // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivUp(totalAssets(id), supply);
    }

    /**
        @notice shows assets conversion output from withdrawing assets
        @param  id uint256 token id of token
        @param assets total number of assets
     */
    function previewWithdraw(uint256 id, uint256 assets)
        public
        view
        virtual
        returns (uint256)
    {
        uint256 supply = totalSupply(id); // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivUp(supply, totalAssets(id));
    }

    /**
        @notice shows assets conversion output from burning shares
        @param  id uint256 token id of token
        @param shares total number of shares
     */
    function previewRedeem(uint256 id, uint256 shares)
        public
        view
        virtual
        returns (uint256)
    {
        return convertToAssets(id, shares);
    }

    /*///////////////////////////////////////////////////////////////
                     DEPOSIT/WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/
    
    /**
        @notice Shows max amount of assets depositable into vault
     */
    function maxDeposit(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    /**
        @notice Shows max amount of mintable shares
     */
    function maxMint(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    /**
        @notice Shows max amount of assets withdrawable from vault
     */
    function maxWithdraw(uint256 id, address owner)
        public
        view
        virtual
        returns (uint256)
    {
        return convertToAssets(id, balanceOf(owner, id));
    }

    /**
        @notice Shows max amount of redeemable assets
     */
    function maxRedeem(uint256 id, address owner)
        public
        view
        virtual
        returns (uint256)
    {
        return balanceOf(owner, id);
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HOOKS LOGIC
    //////////////////////////////////////////////////////////////*/
    // solhint-disable no-empty-blocks
    function beforeWithdraw(
        uint256 id,
        uint256 assets,
        uint256 shares
    ) internal virtual {}

    function afterDeposit(
        uint256 id,
        uint256 assets,
        uint256 shares
    ) internal virtual {}
}
