// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {SemiFungibleVault} from "./SemiFungibleVault.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "@solmate/utils/FixedPointMathLib.sol";
import {
    ReentrancyGuard
} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {FixedPointMathLib} from "@solmate/utils/FixedPointMathLib.sol";

import {
    ERC1155Supply
} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {VaultOverhaul} from "./VaultOverhaul.sol";

/// @author Y2K Finance Team

contract VaultOverhaultWETH is VaultOverhaul {   
   
    /*//////////////////////////////////////////////////////////////
                                 initialize
    //////////////////////////////////////////////////////////////*/

    /**
        @notice initialize 
        @param  _assetAddress    token address representing your asset to be deposited;
        @param  _name   token name for the ERC1155 mints. Insert the name of your token; Example: Y2K_USDC_1.2$
        @param  _symbol token symbol for the ERC1155 mints. insert here if risk or hedge + Symbol. Example: HedgeY2K or riskY2K;
        @param  _token  address of the oracle to lookup the price in chainlink oracles;
        @param  _strikePrice    uint256 representing the price to trigger the depeg event;
        @param _controller  address of the controller contract, this contract can trigger the depeg events;
     */
    function initialize( 
        address _assetAddress,
        string memory _name,
        string memory _symbol,
        address _token,
        int256 _strikePrice,
        address _controller) external {
        if(_initialized) revert AlreadyInitialized();
        if (_controller == address(0)) revert AddressZero();
        if (_token == address(0)) revert AddressZero();
        if (_assetAddress == address(0)) revert AddressZero();
            tokenInsured = _token;
            strikePrice = _strikePrice;
            factory = msg.sender;
            controller = _controller;
            asset = ERC20(_assetAddress);
            name = _name;
            symbol = _symbol;
            _initialized = true;
        }
        
    /**
        @notice Deposit ETH function
        @param  id  uint256 in UNIX timestamp, representing the end date of the epoch. Example: Epoch ends in 30th June 2022 at 00h 00min 00sec: 1654038000;
        @param receiver  address of the receiver of the shares provided by this function, that represent the ownership of the deposited asset;
     */
    function depositETH(uint256 id, address receiver)
        external
        payable
        marketExists(id)
        epochHasNotStarted(id)
        nonReentrant
    {
        require(msg.value > 0, "ZeroValue");
        if (receiver == address(0)) revert AddressZero();

        IWETH(address(asset)).deposit{value: msg.value}();
        _mint(receiver, id, msg.value, EMPTY);

        emit Deposit(msg.sender, receiver, id, msg.value);
    }
}
