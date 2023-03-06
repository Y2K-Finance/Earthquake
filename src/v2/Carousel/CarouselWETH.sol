// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.17;

// import {IWETH} from "../interfaces/IWETH.sol";
// import {Carousel} from "./Carousel.sol";
// import {CarouselCreator} from "../libraries/CarouselCreator.sol";

// /// @author Y2K Finance Team

// contract CarouselWETH is Carousel {
//     /*//////////////////////////////////////////////////////////////
//                                  CONSTRUCTOR
//     //////////////////////////////////////////////////////////////*/

//     /** @notice constructor
//         @param _data  Carousel.ConstructorArgs struct containing the data to be used in the constructor;
//      */
//     constructor(
//         bool _isWETH,
//         address _assetAddress,
//         string memory _name,
//         string memory _symbol,
//         string memory _tokenURI,
//         address _token,
//         uint256 _strike,
//         address _controller,
//         address _treasury,
//         bytes calldata _data 
//     )
//         Carousel(
//             _isWETH,
//             _assetAddress,
//             _name,
//             _symbol,
//             _tokenURI,
//             _token,
//             _strike,
//             _controller,
//             _treasury,
//             _data
//         )
//     {}

//     /**
//         @notice Deposit ETH function
//         @param  _id ;
//         @param _receiver  address of the receiver of the shares provided by this function, that represent the ownership of the deposited asset;
//      */
//     function depositETH(uint256 _id, address _receiver)
//         external
//         payable
//         minRequiredDeposit(msg.value)
//         epochIdExists(_id)
//         epochHasNotStarted(_id)
//         nonReentrant
//     {
//         if(!isWETH) revert CanNotDepositETH();
//         if (_receiver == address(0)) revert AddressZero();

//         IWETH(address(asset)).deposit{value: msg.value}();

//         uint256 assets = msg.value;

//         _deposit(_id, assets, _receiver);
//     }
// }
