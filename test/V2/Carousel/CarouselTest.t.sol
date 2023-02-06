// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../Helper.sol";
import "../../../src/V2/Carousel/Carousel.sol";
import "../../../src/V2/interfaces/ICarousel.sol";

contract CarouselTest is Helper { 
    Carousel vault;
    address controller = address(0x54);
    address emissionsToken;
    uint256 relayerFee = 1000;
    uint256 closingTimeFrame = 1000;
    uint256 lateDepositFee = 1000;

    function setUp() public {

        emissionsToken = address(new MintableToken("EmissionsToken", "etkn"));

        UNDERLYING = address(new MintableToken("UnderLyingToken", "utkn"));

        vault = new Carousel(
            address(0),
            "Vault",
            "v",
            "randomURI",
             address(0),
            STRIKE,
            controller,
            TREASURY,
            abi.encode(
                emissionsToken,
                relayerFee,
                closingTimeFrame,
                lateDepositFee
            )
        );

        vm.warp(120000);

        deal(UNDERLYING, address(this), 100 ether, true);

        deal(UNDERLYING, USER, 100 ether, true);
    }

    function testDepositInQueue() public {
        uint40 _epochBegin = uint40(block.timestamp);
        uint40 _epochEnd = uint40(block.timestamp + 1 days);
        uint256 _epochId = 1;
        uint256 _emissions = 100 ether;

        deal(emissionsToken, address(vault), 100 ether, true);
        vault.setEpoch(_epochBegin, _epochEnd, _epochId);
        vault.setEmissions( _epochId, _emissions);

        vm.startPrank(USER);
        vault.deposit(0, 10 ether, USER);
        vm.stopPrank();

        assertEq(vault.balanceOf(USER, _epochId), 10 ether);
        assertEq(vault.balanceOfEmissions(USER, _epochId), 10 ether);

    }

    function testLateDeposit() public { 
        uint40 _epochBegin = uint40(block.timestamp);
        uint40 _epochEnd = uint40(block.timestamp + 1 days);

        uint256 _epochId = 1;
        uint256 _emissions = 100 ether;

        deal(emissionsToken, address(vault), 100 ether, true);
        vault.setEpoch(_epochBegin, _epochEnd, _epochId);
        vault.setEmissions( _epochId, _emissions);

        vm.startPrank(USER);
        vm.warp(_epochEnd - 100);
        vault.deposit(0, 10 ether, USER);
        vm.stopPrank();
    }


    // function testEnListInRollover() public {
        
    // }

}