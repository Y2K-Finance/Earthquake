// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IWETH} from "../interfaces/IWETH.sol";
import {Carousel} from "./Carousel.sol";

/// @author Y2K Finance Team

contract CarouselWETH is Carousel {
    /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /** @notice constructor
        @param _data  Carousel.ConstructorArgs struct containing the data to be used in the constructor;
     */
    constructor(
       Carousel.ConstructorArgs memory _data
    )
        Carousel(
           _data
        )
    {}

    /**
        @notice Deposit ETH function
        @param  _id ;
        @param _receiver  address of the receiver of the shares provided by this function, that represent the ownership of the deposited asset;
     */
    function depositETH(uint256 _id, address _receiver)
        external
        payable
        minRequiredDeposit(msg.value)
        epochIdExists(_id)
        epochHasNotStarted(_id)
        nonReentrant
    {
        if (_receiver == address(0)) revert AddressZero();

        IWETH(address(asset)).deposit{value: msg.value}();

        uint256 assets = msg.value;

        _deposit(_id, assets, _receiver);
    }
}
