// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;



import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from  "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {
    ERC1155Supply
} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

/// @author MiguelBits
/// @author SlumDog

abstract contract SemiFungibleVault is ERC1155Supply {
   using SafeERC20 for IERC20;

    /*///////////////////////////////////////////////////////////////
                               IMMUTABLES AND STORAGE
    //////////////////////////////////////////////////////////////*/
    IERC20 public immutable asset;
    string public name;
    string public symbol;
    bytes internal constant EMPTY = "";

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

    /** @notice Contract constructor
     * @param _asset ERC20 token
     * @param _name Token name
     * @param _symbol Token symbol
     */
    constructor(
        IERC20 _asset,
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) ERC1155(_uri) {
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
    ) public virtual {
        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, id, assets, EMPTY);

        emit Deposit(msg.sender, receiver, id, assets);
    }

    /** @notice Triggers withdraw from vault and burns receivers' shares
     * @param id Vault id
     * @param assets Amount of tokens to withdraw
     * @param receiver Receiver of assets
     * @param owner Owner of shares
     * @return shares Amount of shares burned
     */
    function withdraw(
        uint256 id,
        uint256 assets,
        address receiver,
        address owner
    ) external virtual returns (uint256 shares) {
        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "Only owner can withdraw, or owner has approved receiver for all"
        );

        shares = previewWithdraw(id, assets);

        _burn(owner, id, shares);

        emit Withdraw(msg.sender, receiver, owner, id, assets, shares);
        asset.safeTransfer(receiver, assets);
    }

    /*///////////////////////////////////////////////////////////////
                           ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /**@notice Returns total assets for token
     * @param  _id uint256 token id of token
     */
    function totalAssets(uint256 _id) public view virtual returns (uint256) {
        return totalSupply(_id);
    }

    /**
        @notice Shows assets conversion output from withdrawing assets
        @param  id uint256 token id of token
        @param assets Total number of assets
     */
    function previewWithdraw(uint256 id, uint256 assets)
        public
        view
        virtual
        returns (uint256)
    {}
}
