// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {ERC20} from "@solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "@solmate/utils/FixedPointMathLib.sol";
import {ERC1155Supply} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

abstract contract SemiFungibleVault is ERC1155Supply {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event Deposit(
        address caller,
        address indexed owner,
        uint256 indexed id,
        uint256 assets,
        uint256 shares
    );
    event Withdraw(
        address caller,
        address receiver,
        address indexed owner,
        uint256 indexed id,
        uint256 assets,
        uint256 shares
    );

    /*///////////////////////////////////////////////////////////////
                               IMMUTABLES AND STORAGE
    //////////////////////////////////////////////////////////////*/
    ERC20 public immutable asset;
    bytes constant EMPTY = "";
    string public name;
    string public symbol;

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

    function mint(
        uint256 id,
        uint256 shares,
        address receiver
    ) public virtual returns (uint256 assets) {
        assets = previewMint(id, shares); // No need to check for rounding error, previewMint rounds up.

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, id, assets, EMPTY);

        emit Deposit(msg.sender, receiver, id, assets, shares);

        afterDeposit(id, assets, shares);
    }

    function withdraw(
        uint256 id,
        uint256 assets,
        address receiver,
        address owner
    ) public virtual returns (uint256 shares) {
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

    function redeem(
        uint256 id,
        uint256 shares,
        address receiver,
        address owner
    ) public virtual returns (uint256 assets) {
        require(
            msg.sender == owner || isApprovedForAll(owner, receiver),
            "Only owner can withdraw, or owner has approved receiver for all"
        );

        // Check for rounding error since we round down in previewRedeem.
        require((assets = previewRedeem(id, shares)) != 0, "ZERO_ASSETS");
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
        @notice returns total assets for token
        @param  id uint256 token id of token
        @param assets total number of asset
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

    function previewDeposit(uint256 id, uint256 assets)
        public
        view
        virtual
        returns (uint256)
    {
        return convertToShares(id, assets);
    }

    function previewMint(uint256 id, uint256 shares)
        public
        view
        virtual
        returns (uint256)
    {
        uint256 supply = totalSupply(id); // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivUp(totalAssets(id), supply);
    }

    function previewWithdraw(uint256 id, uint256 assets)
        public
        view
        virtual
        returns (uint256)
    {
        uint256 supply = totalSupply(id); // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivUp(supply, totalAssets(id));
    }

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
    function maxDeposit(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxMint(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(uint256 id, address owner)
        public
        view
        virtual
        returns (uint256)
    {
        return convertToAssets(id, balanceOf(owner, id));
    }

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
