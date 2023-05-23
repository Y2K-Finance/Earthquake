pragma solidity 0.8.17;

import "../Helper.sol";
import "../../../src/v2/TimeLock.sol";
import "../../../src/v2/Carousel/CarouselFactory.sol";
import "../../../src/v2/interfaces/ICarousel.sol";
import "../../../src/v2/Carousel/Carousel.sol";
import "../../../src/v2/Controllers/ControllerPeggedAssetV2.sol";
import "../../../script/keepers/KeeperV2Rollover.sol";
import "../../../script/keepers/KeeperV2.sol";

contract EndToEndCarouselTest is Helper {
    using stdStorage for StdStorage;

    CarouselFactory public factory;
    ControllerPeggedAssetV2 public controller;
    KeeperV2Rollover public keeper;

    address public emissionsToken;
    address public oracle;
    address public premium;
    address public collateral;

    uint256 public relayerFee;
    uint256 public depositFee;
    uint256 public strike;
    uint256 public marketId;
    uint256 public premiumEmissions;
    uint256 public collatEmissions;
    uint256 public epochId;
    uint256 public nextEpochId;
    uint256 public collateralQueueLength;
    uint256 public premiumQueueLength;
    uint256 public arbForkId;

    uint40 public begin;
    uint40 public end;
    uint40 public nextEpochBegin;
    uint40 public nextEpochEnd;

    uint16 public fee;

    string public arbitrumRpcUrl = vm.envString("ARBITRUM_RPC_URL");

    function setUp() public {
        arbForkId = vm.createFork(arbitrumRpcUrl);
        vm.selectFork(arbForkId);

        emissionsToken = address(new MintableToken("Emissions Token", "EMT"));
        UNDERLYING = address(new MintableToken("UnderLyingToken", "utkn"));

        TimeLock timelock = new TimeLock(ADMIN);

        factory = new CarouselFactory(
            WETH,
            TREASURY,
            address(timelock),
            emissionsToken
        );

        controller = new ControllerPeggedAssetV2(address(factory), ARBITRUM_SEQUENCER);
        factory.whitelistController(address(controller));

        relayerFee = 2 gwei;
        depositFee = 50; // 0,5%

        //oracle = address(0x3);
        //strike = uint256(0x2);
        string memory name = string("USD Coin");
        string memory symbol = string("USDC");

        // deploy market
        (
            premium,
            collateral,
            marketId
        ) = factory.createNewCarouselMarket(
            CarouselFactory.CarouselMarketConfigurationCalldata(
                USDC_TOKEN,
                STRIKE,
                USDC_CHAINLINK,
                UNDERLYING,
                name,
                symbol,
                address(controller),
                relayerFee,
                depositFee,
                1 ether)
        );

        // deploy epoch
        begin = uint40(block.timestamp - 5 days);
        end = uint40(block.timestamp - 3 days);
        fee = uint16(50); //0,5%
        premiumEmissions = 1000 ether;
        collatEmissions = 100 ether;

        // approve emissions token to factory
        vm.startPrank(TREASURY);

        MintableToken(emissionsToken).mint(address(TREASURY), 5000);
        MintableToken(emissionsToken).approve(address(factory),  5000 ether);

        vm.stopPrank();

       ( epochId, ) = factory.createEpochWithEmissions(
                marketId,
                begin,
                end,
                fee,
                premiumEmissions,
                collatEmissions
        );

        //deploy second epoch
        nextEpochBegin = uint40(block.timestamp - 10 hours);
        nextEpochEnd = uint40(block.timestamp - 5 hours);

        ( nextEpochId, ) = factory.createEpochWithEmissions(
                marketId,
                nextEpochBegin,
                nextEpochEnd,
                fee,
                premiumEmissions,
                collatEmissions
        );

        deal(UNDERLYING, USER, 18 ether, true);
        deal(UNDERLYING, USER2, 10 ether, true);


       keeper = new KeeperV2Rollover(payable(ops), payable(treasuryTask), address(factory));
       keeper.startTask(marketId, epochId);
       keeper.startTask(marketId, nextEpochId);

    }


    function testRealVault() public {
        // vm.startPrank(0xCCA23C05a9Cf7e78830F3fd55b1e8CfCCbc5E50F);
        // Carousel(0xDd08cb5A0be3Cc2c6aF567e0D6bDaAE9FA6bb822).enlistInRollover(
        //     31112705580645966551877757450832888924960016498693986711100423123206632918881,
        //     uint256(0x06f02de04b74e000),
        //     0xCCA23C05a9Cf7e78830F3fd55b1e8CfCCbc5E50F
        // );
        // console.log(ICarousel(0xDd08cb5A0be3Cc2c6aF567e0D6bDaAE9FA6bb822).asset());
        // uint256 balanceBefore = IERC20(ICarousel(0xDd08cb5A0be3Cc2c6aF567e0D6bDaAE9FA6bb822).asset()).balanceOf(address(this));

        // (bool canExec, bytes memory execPayload) = KeeperV2(0x1D8E6a60eE80f4fDD65c4377C9dd2F2C62DF3f58).checker(110788007100077306759356690218326038626284721750366921456204435275195769181459, 15803113041142907307017304074354905923746011177789603169554150192158286557592);
        //trigger end of epoch with keeper
        // if(canExec) address(0x1D8E6a60eE80f4fDD65c4377C9dd2F2C62DF3f58).call(execPayload); 

        // Carousel(0xDd08cb5A0be3Cc2c6aF567e0D6bDaAE9FA6bb822).getRolloverTVL();
        // (bool canExec, bytes memory execPayload) = KeeperV2Rollover(0xd061b747fD59368B31BE377CD995BdeF023705A3).checker(104539733070968503208825746187343215845456686552083697493706031226049768240009, 102245315311433893058817552423319371153653735781902521982789438665989751054437);
        //trigger end of epoch with keeper
        // if(canExec) address(keeper).call(execPayload); 

        address vault = CarouselFactory(0x820877E5b1Ee55123c6c6AC2b197fD0A3697A6aB).marketIdToVaults(104539733070968503208825746187343215845456686552083697493706031226049768240009, 1);
        console.log("getRolloverQueueLength", Carousel(vault).getRolloverQueueLength());
        console.log("rolloverAccounting", Carousel(vault).rolloverAccounting(103601628178979418007908754735707002583381016495670010042370412917058389199285));
        console.log("getRolloverIndex", Carousel(vault).getRolloverIndex(0xCCA23C05a9Cf7e78830F3fd55b1e8CfCCbc5E50F));
        (uint256 enlistedAmount,) = Carousel(vault).getRolloverPosition(0xCCA23C05a9Cf7e78830F3fd55b1e8CfCCbc5E50F);
        console.log("enlistedAmount", enlistedAmount);
        console.log("rolloverTVL", Carousel(vault).getRolloverTVL());
        uint256 balanceBefore = IERC20(ICarousel(vault).asset()).balanceOf(0x1F124d3f656aea4a829EE789c7a5328baFEF641e);
        // Carousel(vault).mintRollovers(48615284262728488872268506276546633161776424798518002717091976367836849364943, 100);
        (bool canExec, bytes memory execPayload) = KeeperV2Rollover(0x1F124d3f656aea4a829EE789c7a5328baFEF641e).checker(103315341651798820417043057093748085438159677267937636361440225860324413300936, 103601628178979418007908754735707002583381016495670010042370412917058389199285);
        //trigger end of epoch with keeper
        if(canExec) address(keeper).call(execPayload); 
        uint256 balanceAfter = IERC20(ICarousel(vault).asset()).balanceOf(0x1F124d3f656aea4a829EE789c7a5328baFEF641e);
        console.log("balanceAfter", balanceAfter);
        console.log("balanceBefore", balanceBefore);
        // vm.stopPrank();
    }

    function testEndToEndCarousel(bool keeperExecution) public {
        vm.startPrank(USER);

        //warp to deposit period
        vm.warp(begin - 1 days);

        //approve ether deposit
        IERC20(UNDERLYING).approve(premium, 2 ether);
        IERC20(UNDERLYING).approve(collateral, 10 ether);

        //deposit in carousel vaults
        Carousel(premium).deposit(0, 2 ether, USER);
        Carousel(collateral).deposit(0, 10 ether, USER);

        vm.stopPrank();

        vm.startPrank(USER2);

         //warp to deposit period
        vm.warp(begin - 1 days);

        //approve ether deposit
        IERC20(UNDERLYING).approve(collateral, 10 ether);

        //deposit in carousel vault
        Carousel(collateral).deposit(0, 10 ether, USER2);

        vm.stopPrank();

        //warp to deposit period
        vm.warp(begin - 1 days);

        //assert queue length
        collateralQueueLength = 2;
        premiumQueueLength = 1;
        assertEq(Carousel(collateral).getDepositQueueLength(), collateralQueueLength);
        assertEq(Carousel(premium).getDepositQueueLength(), premiumQueueLength);

        //mint deposit in queue
        if(keeperExecution) {
            bool loop = true;
            while(loop) {
                (bool canExec, bytes memory execPayload) = keeper.checker(marketId, epochId);
                //trigger end of epoch with keeper
                if(canExec) address(keeper).call(execPayload); 
                loop = canExec;
            }

            (bool canExec, ) = keeper.checker(marketId, epochId);
            assertTrue(!canExec);

        } else {
            Carousel(collateral).mintDepositInQueue(epochId, collateralQueueLength);
            Carousel(premium).mintDepositInQueue(epochId, premiumQueueLength);
        }        

        (,uint256 collatBalanceAfterFee) = Carousel(collateral).getEpochDepositFee(epochId, 10 ether);
        (,uint256 premiumBalanceAfterFee) = Carousel(premium).getEpochDepositFee(epochId, 2 ether);

        //assert balance and emissions
        assertEq(Carousel(collateral).balanceOf(USER, epochId), collatBalanceAfterFee - relayerFee);
        assertEq(Carousel(collateral).balanceOf(USER2, epochId), collatBalanceAfterFee - relayerFee);
        assertEq(Carousel(premium).balanceOf(USER, epochId), premiumBalanceAfterFee - relayerFee);
        assertEq(Carousel(premium).balanceOf(USER2, epochId), 0);

        vm.startPrank(USER);

        //enlist in rollover for next epoch
        Carousel(collateral).enlistInRollover(epochId, 8 ether, USER);

        bool isEnlisted = Carousel(collateral).isEnlistedInRolloverQueue(USER);
        (uint256 enlistedAmount,) = Carousel(collateral).getRolloverPosition(USER);

        assertEq(isEnlisted, true);
        assertEq(enlistedAmount, 8 ether);

        vm.stopPrank();

        vm.startPrank(USER2);

        //enlist in rollover for next epoch
        Carousel(collateral).enlistInRollover(epochId, 8 ether, USER2);

        vm.stopPrank();

        //warp to end of epoch
        vm.warp(end + 1 days);

        //trigger end epoch
        controller.triggerEndEpoch(marketId, epochId);

        //check vault balances on withdraw
        assertEq(Carousel(premium).previewWithdraw(epochId, 12 ether), 0);
        assertEq(Carousel(collateral).previewWithdraw(epochId, 20 ether), COLLATERAL_MINUS_FEES);

        // let relayer rollover for users
        if(keeperExecution) {
            bool loop = true;
            while(loop) {
                (bool canExec, bytes memory execPayload) = keeper.checker(marketId, nextEpochId);
                //trigger end of epoch with keeper
                if(canExec) address(keeper).call(execPayload); 
                loop = canExec;
            }

            (bool canExec, ) = keeper.checker(marketId, nextEpochId);
            assertTrue(!canExec);
        } else {
              Carousel(collateral).mintRollovers(nextEpochId, 2);
        }
      
        //assert rollover accounting
        assertEq(Carousel(collateral).rolloverAccounting(nextEpochId), 2);

        vm.startPrank(USER);

        //check shares from premium, withdraw first epoch
        assertEq(Carousel(collateral).previewWithdraw(epochId, 2 ether), COLLATERAL_MINUS_FEES_DIV10);
        Carousel(collateral).withdraw(epochId, 2 ether - depositFee - relayerFee, USER, USER);

        vm.stopPrank();

        vm.startPrank(USER2);

        //withdraw first epoch
        Carousel(collateral).withdraw(epochId, 2 ether - depositFee - relayerFee, USER2, USER2);

        vm.stopPrank();

        vm.startPrank(USER);

        //approve ether deposit
        IERC20(UNDERLYING).approve(premium, 6 ether);

        //premium deposit for assertions - PLEASE CHECK THIS
        Carousel(premium).deposit(nextEpochId, 6 ether, USER);

        vm.stopPrank();

        //warp to nextEpochEnd
        vm.warp(nextEpochEnd + 1 minutes);

        //trigger next epoch end
        controller.triggerEndEpoch(marketId, nextEpochId);

        //check vault balances on withdraw
        assertEq(Carousel(premium).previewWithdraw(nextEpochId, 6 ether), 0);
        assertEq(Carousel(collateral).previewWithdraw(nextEpochId, 16 ether), NEXT_COLLATERAL_MINUS_FEES);

        //withdraw USER1
        vm.startPrank(USER);

        //delist rollover
        uint256 beforeQueueLength = Carousel(collateral).getRolloverQueueLength();
        Carousel(collateral).delistInRollover(USER);

        //assert delisted rollover position in queue assets are 0
        bool ie = Carousel(collateral).isEnlistedInRolloverQueue(USER);
        ( uint256 amountAfterDelisting,) = Carousel(collateral).getRolloverPosition(USER);
        assertTrue(!ie);
        assertEq(amountAfterDelisting, 0);        

        //assert balance in next epoch
        uint256 balanceInNextEpoch = Carousel(collateral).balanceOf(USER, nextEpochId);

        //assert rollover minus relayer fee which is subtracted based on the value of the shares of the prev epoch
        assertEq(balanceInNextEpoch, (8 ether - relayerFee));

        //withdraw after rollover
        Carousel(collateral).withdraw(nextEpochId, balanceInNextEpoch, USER, USER);
        Carousel(premium).withdraw(nextEpochId, Carousel(premium).balanceOf(USER, nextEpochId), USER, USER);

        vm.stopPrank();

        // cleanup queue from delisted users
        vm.startPrank(address(factory));
        uint256 beforeQueueLength2 = Carousel(collateral).getRolloverQueueLength();
        assertEq(beforeQueueLength2, 2);
        address[] memory addressesToDelist = new address[](1);
        addressesToDelist[0] = USER;
        Carousel(collateral).cleanUpRolloverQueue(addressesToDelist);
        uint256 afterQueueLength2 = Carousel(collateral).getRolloverQueueLength();
        assertEq(afterQueueLength2, 1);
        vm.stopPrank();

        //withdraw USER2
        vm.startPrank(USER2);

        //assert rollover index, should be 0 since USER1 lising was cleaned up
        assertTrue(Carousel(collateral).getRolloverIndex(USER2) == 0);

        //delist rollover
        beforeQueueLength = Carousel(collateral).getRolloverQueueLength();
        Carousel(collateral).delistInRollover(USER2);

        //assert balance in next epoch
        balanceInNextEpoch = Carousel(collateral).balanceOf(USER2, nextEpochId);

        //assert rollover minus relayer fee which is subtracted based on the value of the shares of the prev epoch
        assertTrue(balanceInNextEpoch == 8 ether - relayerFee); 

        //withdraw after rollover
        Carousel(collateral).withdraw(nextEpochId, balanceInNextEpoch, USER2, USER2);

        vm.stopPrank();

        //check vaults balance
        assertEq(Carousel(premium).balanceOf(USER, nextEpochId), 0);
        assertEq(Carousel(collateral).balanceOf(USER, nextEpochId), 0);
        assertEq(Carousel(premium).balanceOf(USER2, nextEpochId), 0);
        assertEq(Carousel(collateral).balanceOf(USER2, nextEpochId), 0);

        //assert emissions balance of treasury and users
        assertEq(IERC20(emissionsToken).balanceOf(TREASURY), 2800 ether);
        assertEq(IERC20(emissionsToken).balanceOf(USER), USER1_EMISSIONS_AFTER_WITHDRAW);
        assertEq(IERC20(emissionsToken).balanceOf(USER2), USER2_EMISSIONS_AFTER_WITHDRAW);

        //assert UNDERLYING users balance
        assertEq(IERC20(UNDERLYING).balanceOf(USER), USER_AMOUNT_AFTER_WITHDRAW);
        assertEq(IERC20(UNDERLYING).balanceOf(USER2), USER_AMOUNT_AFTER_WITHDRAW);
    }
}