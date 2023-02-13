// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../Helper.sol";
import "../../../src/V2/Carousel/Carousel.sol";
import "../../../src/V2/interfaces/ICarousel.sol";
// import "../../../src/v2/VaultV2.sol";


contract CarouselTest is Helper { 
    using stdStorage for StdStorage;

    // VaultV2 vaultv2;
    Carousel vault;
    address controller = address(0x54);
    address relayer = address(0x55);
    address emissionsToken;
    uint256 relayerFee = 2 gwei;
    uint256 depositFee = 50;
    address USER3 = address(0x123);
    address USER4 = address(0x345);
    address USER5 = address(0x567);
    address USER6 = address(0x789);

    function setUp() public {

        vm.warp(1675884389);

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
                depositFee
            )
        );

        // deal(UNDERLYING, address(this), 100 ether, true);

        deal(UNDERLYING, USER, 1000 ether, true);
        deal(UNDERLYING, USER2, 1000 ether, true);
        deal(UNDERLYING, USER3, 1000 ether, true);
        deal(UNDERLYING, USER4, 1000 ether, true);
        deal(UNDERLYING, USER5, 1000 ether, true);
        deal(UNDERLYING, USER6, 1000 ether, true);
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
        vm.expectRevert(Carousel.InvalidEpochId.selector);
        vault.mintDepositInQueue(0, _queueLength);
        // should revert if operations are not in queue length
        vm.expectRevert(Carousel.OverflowQueue.selector);
        vault.mintDepositInQueue(_epochId, 2);
        // should revert if epoch already started
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

        vm.warp(_epochBegin - 10 minutes);
    
        helperDepositInEpochs(_epochId,USER, false);
        helperDepositInEpochs(_epochId,USER2, false);

        // enlist in rollover for next epoch
        vm.startPrank(USER);
        //_epochId == epoch user is depositing in / amount of shares he wants to rollover
        vault.enlistInRollover(_epochId, 8 ether, USER);
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

        // let relayer rollover for user but not mit as prev epoch has not won
        vm.startPrank(relayer);
        vault.mintRollovers(_epochId, 1);
        vm.stopPrank();

        assertEq(vault.rolloverAccounting(_epochId), 0);

        // simulate prev epoch win
        stdstore
            .target(address(vault))
            .sig("claimTVL(uint256)")
            .with_key(2)
            .checked_write(1000 ether);

        // resolve second epoch
        // let relayer rollover for user
        vm.startPrank(relayer);
        vault.mintRollovers(_epochId, 1);
        vm.stopPrank();

        assertEq(vault.rolloverAccounting(_epochId), 1);
    }

    function testDepositIntoQueueMultiple() public {
        // test multiple deposits into queue
        uint40 _epochBegin = uint40(block.timestamp + 1 days);
        uint40 _epochEnd = uint40(block.timestamp + 2 days);
        uint256 _epochId = 2;
        uint256 _emissions = 100 ether;

        deal(emissionsToken, address(vault), 100 ether, true);
        vault.setEpoch(_epochBegin, _epochEnd, _epochId);
        vault.setEmissions( _epochId, _emissions);

        helperDepositInEpochs(_epochId,USER, true);
        helperDepositInEpochs(_epochId,USER2, true);
        helperDepositInEpochs(_epochId,USER3, true);
        helperDepositInEpochs(_epochId,USER4, true);
        helperDepositInEpochs(_epochId,USER5, true);
        helperDepositInEpochs(_epochId,USER6, true);

        assertEq(vault.getDepositQueueLenght(), 6);
        
        // check balance of relayer
        uint256 balanceBefore = IERC20(UNDERLYING).balanceOf(address(this));

        // mint deposit in queue
        vault.mintDepositInQueue(_epochId, 6);

        // check balance of relayer
        uint256 balanceAfter = IERC20(UNDERLYING).balanceOf(address(this));

        // check relayer fee
        uint256 _relayerFee = (balanceAfter - balanceBefore) / 6;
        assertEq(_relayerFee, relayerFee);

        // check balances
        assertEq(vault.balanceOf(USER, _epochId), 10 ether - relayerFee);
        assertEq(vault.balanceOfEmissions(USER, _epochId), 10 ether - relayerFee);
        assertEq(vault.balanceOf(USER2, _epochId), 10 ether - relayerFee);
        assertEq(vault.balanceOfEmissions(USER2, _epochId), 10 ether - relayerFee);
        assertEq(vault.balanceOf(USER3, _epochId), 10 ether - relayerFee);
        assertEq(vault.balanceOfEmissions(USER3, _epochId), 10 ether - relayerFee);
        assertEq(vault.balanceOf(USER4, _epochId), 10 ether - relayerFee);
        assertEq(vault.balanceOfEmissions(USER4, _epochId), 10 ether - relayerFee);
        assertEq(vault.balanceOf(USER5, _epochId), 10 ether - relayerFee);
        assertEq(vault.balanceOfEmissions(USER5, _epochId), 10 ether - relayerFee);
        assertEq(vault.balanceOf(USER6, _epochId), 10 ether - relayerFee);
        assertEq(vault.balanceOfEmissions(USER6, _epochId), 10 ether - relayerFee);
    }

    function testRolloverMultiple() public {
        // test multiple rollovers
        // roll over users from testDepositIntoQueueMultiple test
        testDepositIntoQueueMultiple();

        // create new epoch
        uint40 _epochBegin = uint40(block.timestamp + 3 days);
        uint40 _epochEnd = uint40(block.timestamp + 4 days);
        uint256 _epochId = 3;
        uint256 _emissions = 100 ether;

        deal(emissionsToken, address(vault), 100 ether, true);
        vault.setEpoch(_epochBegin, _epochEnd, _epochId);
        vault.setEmissions( _epochId, _emissions);

        uint256 prevEpochUserBalance = 10 ether - relayerFee;

        uint256 prevEpoch = 2;
        // enlist in rollover for next epoch
        helperRolloverFromEpoch(prevEpoch, USER,  prevEpochUserBalance);
        helperRolloverFromEpoch(prevEpoch, USER2, prevEpochUserBalance);
        helperRolloverFromEpoch(prevEpoch, USER3, prevEpochUserBalance);
        helperRolloverFromEpoch(prevEpoch, USER4, prevEpochUserBalance);
        helperRolloverFromEpoch(prevEpoch, USER5, prevEpochUserBalance);
        helperRolloverFromEpoch(prevEpoch, USER6, prevEpochUserBalance);

        // check balance of relayer
        uint256 balanceBefore = IERC20(UNDERLYING).balanceOf(address(this));

        // expect revert as prev epoch is not resolved
        vm.expectRevert(VaultV2.EpochNotResolved.selector);
        vault.mintRollovers(_epochId, 6);

        // resolve prev epoch
        vm.warp(block.timestamp + 2 days + 1 hours); // warp to one hour after prev epoch end
        vm.startPrank(controller);
        vault.resolveEpoch(prevEpoch);
        vm.stopPrank();

        // mint rollovers
        // this should not mint any shares as prev epoch is not in profit
        vault.mintRollovers(_epochId, 6);
        
        // check balance of relayer
        uint256 balanceAfter = IERC20(UNDERLYING).balanceOf(address(this));
        assertEq(balanceBefore, balanceAfter);

        // check balances
        assertEq(vault.balanceOf(USER, _epochId), 0);
        assertEq(vault.balanceOfEmissions(USER, _epochId), 0);
        assertEq(vault.balanceOf(USER2, _epochId), 0);
        assertEq(vault.balanceOfEmissions(USER2, _epochId), 0);

        // simulate prev epoch win
        stdstore
            .target(address(vault))
            .sig("claimTVL(uint256)")
            .with_key(prevEpoch)
            .checked_write(1000 ether);

        console.log("rollover queue length", vault.getRolloverQueueLenght());

        // mint rollovers again
        // this should mint shares as prev epoch is in profit
        vault.mintRollovers(_epochId, 6);

        // check balance of relayer
        balanceAfter = IERC20(UNDERLYING).balanceOf(address(this));

        // check relayer fee
        uint256 _relayerFee = (balanceAfter - balanceBefore) / 6;
        assertEq(_relayerFee, relayerFee);

        // check balances
        assertEq(vault.balanceOf(USER, _epochId), prevEpochUserBalance - relayerFee);
        assertEq(vault.balanceOfEmissions(USER, _epochId), prevEpochUserBalance - relayerFee);
        assertEq(vault.balanceOf(USER2, _epochId), prevEpochUserBalance - relayerFee);
        assertEq(vault.balanceOfEmissions(USER2, _epochId), prevEpochUserBalance - relayerFee);
        assertEq(vault.balanceOf(USER3, _epochId), prevEpochUserBalance - relayerFee);
        assertEq(vault.balanceOfEmissions(USER3, _epochId), prevEpochUserBalance - relayerFee);
        assertEq(vault.balanceOf(USER4, _epochId), prevEpochUserBalance - relayerFee);
        assertEq(vault.balanceOfEmissions(USER4, _epochId), prevEpochUserBalance - relayerFee);
        assertEq(vault.balanceOf(USER5, _epochId), prevEpochUserBalance - relayerFee);
        assertEq(vault.balanceOfEmissions(USER5, _epochId), prevEpochUserBalance - relayerFee);
        assertEq(vault.balanceOf(USER6, _epochId), prevEpochUserBalance - relayerFee);
        assertEq(vault.balanceOfEmissions(USER6, _epochId), prevEpochUserBalance - relayerFee);

        
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

    function helperDepositInEpochs(uint256 _epoch, address user, bool queue) public{
        // deposit for each user in each epoch
        vm.startPrank(user);
        IERC20(UNDERLYING).approve(address(vault), 10 ether);
        vault.deposit(queue ? 0 : _epoch, 10 ether, user);
        vm.stopPrank();
    }

        function helperRolloverFromEpoch(uint256 _epoch, address user, uint256 amount) public{
        // enlist user in rollover
        vm.startPrank(user);
        vault.enlistInRollover(_epoch, amount, user);
        vm.stopPrank();   
    }


}