// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../VaultFactoryV2.sol";
import "./Carousel.sol";
import {ICarousel} from "../interfaces/ICarousel.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @author Y2K Finance Team

contract CarouselFactory is VaultFactoryV2 {
    using SafeERC20 for IERC20;
    IERC20 public emissionsToken;

    constructor(
        address _policy,
        address _weth,
        address _treasury,
        address _emissoinsToken
    ) VaultFactoryV2(_policy, _weth, _treasury) {
        emissionsToken = IERC20(_emissoinsToken);
    }
    
    function createEpochWithEmissions(
        uint256 _marketId,
        uint40 _epochBegin,
        uint40 _epochEnd,
        uint16 _withdrawalFee,
        uint256 _emissions1,
        uint256 _emissions2
    ) public returns (uint256 epochId, address[2] memory vaults) {

        // no need for onlyOwner modifier as createEpoch already has modifier
        (epochId, vaults) = createEpoch(_marketId, _epochBegin, _epochEnd, _withdrawalFee);

        emissionsToken.safeTransferFrom(msg.sender, vaults[0], _emissions1);
        ICarousel(vaults[0]).setEmissions(epochId, _emissions1);

        emissionsToken.safeTransferFrom(msg.sender, vaults[1], _emissions2);
        ICarousel(vaults[1]).setEmissions(epochId, _emissions2);

        
    }

    

}