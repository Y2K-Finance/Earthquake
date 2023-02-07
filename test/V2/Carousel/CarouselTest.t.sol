// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../Helper.sol";
import "../../../src/V2/Carousel/Carousel.sol";
import "../../../src/V2/interfaces/ICarousel.sol";
// import "../../../src/v2/VaultV2.sol";


contract CarouselTest is Helper { 
    // VaultV2 vaultv2;
    Carousel vault;
    address controller = address(0x54);
    address relayer = address(0x55);
    address emissionsToken;
    uint256 relayerFee = 2 gwei;
    uint256 closingTimeFrame = 1000;
    uint256 lateDepositFee = 1000;

    function setUp() public {

        emissionsToken = address(new MintableToken("EmissionsToken", "etkn"));

        UNDERLYING = address(new MintableToken("UnderLyingToken", "utkn"));

          vault = new Carousel(
            Carousel.ConstructorArgs(
                UNDERLYING,
                "Vault",
                "v",
                "randomURI",
                TOKEN,
                STRIKE,
                controller,
                TREASURY,
                emissionsToken,
                relayerFee,
                closingTimeFrame,
                lateDepositFee
            )
        );

        // deal(UNDERLYING, address(this), 100 ether, true);

        deal(UNDERLYING, USER, 1000 ether, true);

        deal(UNDERLYING, USER2, 1000 ether, true);
    }

    function testDepositInQueue() public {
        uint40 _epochBegin = uint40(block.timestamp + 1 days);
        uint40 _epochEnd = uint40(block.timestamp + 2 days);
        uint256 _epochId = 1;
        uint256 _emissions = 100 ether;

        deal(emissionsToken, address(vault), 100 ether, true);
        vault.setEpoch(_epochBegin, _epochEnd, _epochId);
        vault.setEmissions( _epochId, _emissions);

        vm.startPrank(USER);
        IERC20(UNDERLYING).approve(address(vault), 10 ether);
        vault.deposit(0, 10 ether, USER);
        vm.stopPrank();

        uint256 _queueLength = 1;
        assertEq(vault.getDepositQueueLenght(), _queueLength);
        // test revert cases
        // should revert if epochId is 0 as this epoch is not supposed to minted ever
        vm.expectRevert();
        vault.mintDepositInQueue(0, _queueLength);
        // should revert if operations are not in queue length
        vm.expectRevert(Carousel.OverflowQueue.selector);
        vault.mintDepositInQueue(_epochId, 2);
        // should revert if operations are not in queue length
        vm.warp(_epochBegin + 100);
        vm.expectRevert(VaultV2.EpochAlreadyStarted.selector);
        vault.mintDepositInQueue(_epochId, 1);

        vm.warp(_epochBegin - 1 days);
        // should revert if epoch does not exist
        vm.expectRevert(VaultV2.EpochDoesNotExist.selector);
        vault.mintDepositInQueue(3, 1);

        vault.mintDepositInQueue(_epochId, _queueLength);
        assertEq(vault.balanceOf(USER, _epochId), 10 ether - relayerFee);
        assertEq(vault.balanceOfEmissions(USER, _epochId), 10 ether - relayerFee);

       

        // // deposit with multiple users
        _epochBegin = uint40(block.timestamp + 1 days);
        _epochEnd = uint40(block.timestamp + 2 days);
        _epochId = 2;
        _emissions = 1000 ether;

        deal(emissionsToken, address(vault), 1000 ether, true);
        vault.setEpoch(_epochBegin, _epochEnd, _epochId);
        vault.setEmissions( _epochId, _emissions);

        vm.startPrank(USER);
        IERC20(UNDERLYING).approve(address(vault), 10 ether);
        vault.deposit(0, 10 ether, USER);
        vm.stopPrank();

        vm.startPrank(USER2);
        IERC20(UNDERLYING).approve(address(vault), 10 ether);
        vault.deposit(0, 10 ether, USER2);
        vm.stopPrank();

        _queueLength = 2;

        assertEq(vault.getDepositQueueLenght(), _queueLength);
        vault.mintDepositInQueue(_epochId, _queueLength);
        assertEq(vault.balanceOf(USER, _epochId), 10 ether - relayerFee);
        assertEq(vault.balanceOfEmissions(USER, _epochId), 10 ether - relayerFee);
        assertEq(vault.balanceOf(USER2, _epochId), 10 ether - relayerFee);
        assertEq(vault.balanceOfEmissions(USER2, _epochId), 10 ether - relayerFee);
    }

    // function testLateDeposit() public { 
    //     uint40 _epochBegin = uint40(block.timestamp);
    //     uint40 _epochEnd = uint40(block.timestamp + 1 days);

    //     uint256 _epochId = 1;
    //     uint256 _emissions = 100 ether;

    //     deal(emissionsToken, address(vault), 100 ether, true);
    //     vault.setEpoch(_epochBegin, _epochEnd, _epochId);
    //     vault.setEmissions( _epochId, _emissions);

    //     vm.startPrank(USER);
    //     vm.warp(_epochEnd - 100);
    //     vault.deposit(0, 10 ether, USER);
    //     vm.stopPrank();
    // }


    function testEnListInRollover() public {
        // create two epochs
        uint40 _epochBegin = uint40(block.timestamp + 1 days);
        uint40 _epochEnd = uint40(block.timestamp + 2 days);
        uint256 _epochId = 2;
        uint256 _emissions = 100 ether;

        deal(emissionsToken, address(vault), 100 ether, true);
        vault.setEpoch(_epochBegin, _epochEnd, _epochId);
        vault.setEmissions( _epochId, _emissions);
    
        helperDepositInEpochs(_epochId,USER, false);
        helperDepositInEpochs(_epochId,USER2, false);

        console.log(vault.epochExists(_epochId));

        // enlist in rollover for next epoch
        vm.startPrank(USER);
        //_epochId == epoch user is depositing in / amount of shares he wants to rollover
        vault.enlistInRollover(_epochId, 10 ether, USER);
        vm.stopPrank();

        // resolve first epoch
        vm.warp(_epochEnd + 1 days);
        vm.startPrank(controller);
        vault.resolveEpoch(_epochId);
        vm.stopPrank();

        

        // create second epoch
        _epochBegin = uint40(block.timestamp + 1 days);
        _epochEnd = uint40(block.timestamp + 2 days);
        _epochId = 3;
        _emissions = 100 ether;

        deal(emissionsToken, address(vault), 100 ether, true);
        vault.setEpoch(_epochBegin, _epochEnd, _epochId);
        vault.setEmissions( _epochId, _emissions);

        // let relayer rollover for user
        vm.startPrank(relayer);
        vault.mintRollovers(_epochId, 1);
        vm.stopPrank();

        assertEq(vault.rolloverAccounting(_epochId), 1);
            
    }

    function helperDepositInEpochs(uint256 _epoch, address user, bool queue) public{
        // deposit for each user in each epoch
        vm.startPrank(user);
        IERC20(UNDERLYING).approve(address(vault), 10 ether);
        vault.deposit(queue ? 0 : _epoch, 10 ether, user);
        vm.stopPrank();

    }

}