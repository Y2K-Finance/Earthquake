// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Test.sol";
import {Vault} from "../src/Vault.sol";
import {VaultFactory} from "../src/VaultFactory.sol";
import {Controller} from "../src/Controller.sol";
import {PegOracle} from "../src/oracles/PegOracle.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";
import "@chainlink/interfaces/AggregatorV3Interface.sol";
import {Helper} from "./Helper.sol";

import {FakeOracle} from "./oracles/FakeOracle.sol";
import {DepegOracle} from "./oracles/DepegOracle.sol";
import {IWETH} from "./interfaces/IWETH.sol";


contract AssertTest is Helper {
	
	/*///////////////////////////////////////////////////////////////
                           CREATION functions
    //////////////////////////////////////////////////////////////*/
    function testOraclesShit() public {
        PegOracle pegOracle = new PegOracle(oracleSTETH, oracleETH);
        //PegOracle pegOracle2 = new PegOracle(oracleFRAX, oracleFEI);

        int256 oracle1price1 = pegOracle.getOracle1_Price();
        int256 oracle1price2 = pegOracle.getOracle2_Price();
        emit log_named_int("oracle1price1", oracle1price1);
        emit log_named_int("oracle1price2", oracle1price2);
        (
            ,
            int256 price,
            ,
            ,
            
        ) = pegOracle.latestRoundData();
        emit log_named_int("oracle?price?", price);

        vm.startPrank(admin);
        vaultFactory.createNewMarket(FEE, tokenSTETH, DEPEG_AAA, beginEpoch, endEpoch, address(pegOracle), "y2kSTETH_99*");
        vm.stopPrank();

        int256 nowPrice = controller.getLatestPrice(tokenSTETH);

        emit log_named_int("Controller Price: ", nowPrice);
        emit log_named_int("Token      Price: ", DEPEG_AAA);
        console2.log("Decimals: ", pegOracle.decimals());

    }
    
    function testPegOracleMarketCreation() public {
        PegOracle pegOracle = new PegOracle(oracleSTETH, oracleETH);
        PegOracle pegOracle2 = new PegOracle(oracleFRAX, oracleFEI);

        // //Eth price feed minus something to trigger depeg
        FakeOracle fakeOracle = new FakeOracle(oracleETH, CREATION_STRK);
        PegOracle pegOracle3 = new PegOracle(address(fakeOracle), oracleETH);

        vm.startPrank(admin);
        vaultFactory.createNewMarket(FEE, tokenSTETH, DEPEG_AAA, beginEpoch, endEpoch, address(pegOracle), "y2kSTETH_99*");
        vaultFactory.createNewMarket(FEE, tokenFEI, DEPEG_BBB, beginEpoch, endEpoch, address(pegOracle2), "y2kSTETH_97*");
        vaultFactory.createNewMarket(FEE, WETH, DEPEG_CCC, beginEpoch, endEpoch, address(pegOracle3), "y2kSTETH_95*");
        vm.stopPrank();

        Deposit(1);
        Deposit(2);
        Deposit(3);

        int256 oracle1price1 = pegOracle.getOracle1_Price();
        int256 oracle1price2 = pegOracle.getOracle2_Price();
        emit log_named_int("oracle1price1", oracle1price1);
        emit log_named_int("oracle1price2", oracle1price2);
        (
            ,
            int256 price,
            ,
            ,
            
        ) = pegOracle.latestRoundData();
        emit log_named_int("oracle1price1 / oracle1price2", price);

        int256 oracle2price1 = pegOracle2.getOracle1_Price();
        int256 oracle2price2 = pegOracle2.getOracle2_Price();
        emit log_named_int("oracle2price1", oracle2price1);
        emit log_named_int("oracle2price2", oracle2price2);
        (
            ,
            price,
            ,
            ,
            
        ) = pegOracle2.latestRoundData();
        emit log_named_int("oracle2price1 / oracle2price2", price);

        int256 oracle3price1 = pegOracle3.getOracle1_Price();
        int256 oracle3price2 = pegOracle3.getOracle2_Price();
        emit log_named_int("oracle3price1", oracle3price1);
        emit log_named_int("oracle3price2", oracle3price2);
        (
            ,
            price,
            ,
            ,
            
        ) = pegOracle3.latestRoundData();
        emit log_named_int("oracle3price1 / oracle3price2", price);

        ControllerEndEpoch(tokenSTETH,1);
        ControllerEndEpoch(tokenFEI,2);
        ControllerEndEpoch(WETH,3);

        Withdraw();
    }

    function testAllMarketsCreation() public {
        vm.startPrank(admin);

        // Create FRAX market
        //index 1
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_99*");
        //index 2
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_BBB, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_97*");
        //index 3
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_CCC, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_95*");

        // Create MIM market
        //index 4
        vaultFactory.createNewMarket(FEE, tokenMIM, DEPEG_AAA, beginEpoch, endEpoch, oracleMIM, "y2kMIM_99*");
        //index 5
        vaultFactory.createNewMarket(FEE, tokenMIM, DEPEG_BBB, beginEpoch, endEpoch, oracleMIM, "y2kMIM_97*");
        //index 6
        vaultFactory.createNewMarket(FEE, tokenMIM, DEPEG_CCC, beginEpoch, endEpoch, oracleMIM, "y2kMIM_95*");

        // Create FEI market
        //index 7
        vaultFactory.createNewMarket(FEE, tokenFEI, DEPEG_AAA, beginEpoch, endEpoch, oracleFEI, "y2kFEI_99*");
        //index 8
        vaultFactory.createNewMarket(FEE, tokenFEI, DEPEG_BBB, beginEpoch, endEpoch, oracleFEI, "y2kFEI_97*");
        //index 9
        vaultFactory.createNewMarket(FEE, tokenFEI, DEPEG_CCC, beginEpoch, endEpoch, oracleFEI, "y2kFEI_95*");

        // Create USDC market
        //index 10
        vaultFactory.createNewMarket(FEE, tokenUSDC, DEPEG_AAA, beginEpoch, endEpoch, oracleUSDC, "y2kUSDC_99*");
        //index 11
        vaultFactory.createNewMarket(FEE, tokenUSDC, DEPEG_BBB, beginEpoch, endEpoch, oracleUSDC, "y2kUSDC_97*");
        //index 12
        vaultFactory.createNewMarket(FEE, tokenUSDC, DEPEG_CCC, beginEpoch, endEpoch, oracleUSDC, "y2kUSDC_95*");

        // Create DAI market
        //index 13
        vaultFactory.createNewMarket(FEE, tokenDAI, DEPEG_AAA, beginEpoch, endEpoch, oracleDAI, "y2kDAI_99*");
        //index 14
        vaultFactory.createNewMarket(FEE, tokenDAI, DEPEG_BBB, beginEpoch, endEpoch, oracleDAI, "y2kDAI_97*");
        //index 15
        vaultFactory.createNewMarket(FEE, tokenDAI, DEPEG_CCC, beginEpoch, endEpoch, oracleDAI, "y2kDAI_95*");
        
        vm.stopPrank();
    }

    function testAllMarketsDeployMore() public {

        testAllMarketsCreation();

        vm.startPrank(admin);

        // Deploy more FRAX market
        vaultFactory.deployMoreAssets(SINGLE_MARKET_INDEX, beginEpoch + END_DAYS, endEpoch + END_DAYS, FEE);
        vaultFactory.deployMoreAssets(2, beginEpoch + END_DAYS, endEpoch + END_DAYS, FEE);
        vaultFactory.deployMoreAssets(3, beginEpoch + END_DAYS, endEpoch + END_DAYS, FEE);

        // Deploy more MIM market
        vaultFactory.deployMoreAssets(4, beginEpoch + END_DAYS, endEpoch + END_DAYS, FEE);
        vaultFactory.deployMoreAssets(5, beginEpoch + END_DAYS, endEpoch + END_DAYS, FEE);
        vaultFactory.deployMoreAssets(6, beginEpoch + END_DAYS, endEpoch + END_DAYS, FEE);

        // Deploy more FEI market
        vaultFactory.deployMoreAssets(7, beginEpoch + END_DAYS, endEpoch + END_DAYS, FEE);
        vaultFactory.deployMoreAssets(8, beginEpoch + END_DAYS, endEpoch + END_DAYS, FEE);
        vaultFactory.deployMoreAssets(9, beginEpoch + END_DAYS, endEpoch + END_DAYS, FEE);

        // Deploy more USDC market
        vaultFactory.deployMoreAssets(10, beginEpoch + END_DAYS, endEpoch + END_DAYS, FEE);
        vaultFactory.deployMoreAssets(11, beginEpoch + END_DAYS, endEpoch + END_DAYS, FEE);
        vaultFactory.deployMoreAssets(12, beginEpoch + END_DAYS, endEpoch + END_DAYS, FEE);

        // Deploy more DAI market
        vaultFactory.deployMoreAssets(13, beginEpoch + END_DAYS, endEpoch + END_DAYS, FEE);
        vaultFactory.deployMoreAssets(14, beginEpoch + END_DAYS, endEpoch + END_DAYS, FEE);
        vaultFactory.deployMoreAssets(ALL_MARKETS_INDEX, beginEpoch + END_DAYS, endEpoch + END_DAYS, FEE);

        vm.stopPrank();
    }

    /*///////////////////////////////////////////////////////////////
                           DEPOSIT functions
    //////////////////////////////////////////////////////////////*/

    function testDeposit() public {
        vm.deal(alice, AMOUNT);
        vm.deal(bob, AMOUNT * BOB_MULTIPLIER);
        vm.deal(chad, AMOUNT * CHAD_MULTIPLIER);
        vm.deal(degen, AMOUNT * DEGEN_MULTIPLIER);

        vm.prank(admin);
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_99*");

        address hedge = vaultFactory.getVaults(1)[0];
        address risk = vaultFactory.getVaults(1)[1];
        
        Vault vHedge = Vault(hedge);
        Vault vRisk = Vault(risk);

        //ALICE hedge DEPOSIT
        vm.startPrank(alice);
        ERC20(WETH).approve(hedge, AMOUNT);
        vHedge.depositETH{value: AMOUNT}(endEpoch, alice);
        vm.stopPrank();

        //BOB hedge DEPOSIT
        vm.startPrank(bob);
        ERC20(WETH).approve(hedge, AMOUNT * BOB_MULTIPLIER);
        vHedge.depositETH{value: AMOUNT * BOB_MULTIPLIER}(endEpoch, bob);

        assertTrue(vHedge.balanceOf(bob,endEpoch) == AMOUNT * BOB_MULTIPLIER);
        vm.stopPrank();

        //CHAD risk DEPOSIT
        vm.startPrank(chad);
        ERC20(WETH).approve(risk, AMOUNT * CHAD_MULTIPLIER);
        vRisk.depositETH{value: AMOUNT * CHAD_MULTIPLIER}(endEpoch, chad);

        assertTrue(vRisk.balanceOf(chad,endEpoch) == (AMOUNT * CHAD_MULTIPLIER));
        vm.stopPrank();

        //DEGEN risk DEPOSIT
        vm.startPrank(degen);
        ERC20(WETH).approve(risk, AMOUNT * DEGEN_MULTIPLIER);
        vRisk.depositETH{value: AMOUNT * DEGEN_MULTIPLIER}(endEpoch, degen);

        assertTrue(vRisk.balanceOf(degen,endEpoch) == (AMOUNT * DEGEN_MULTIPLIER));
        vm.stopPrank();
    }

    /*///////////////////////////////////////////////////////////////
                           CONTROLLER functions
    //////////////////////////////////////////////////////////////*/

    function testControllerDepeg() public{

        DepositDepeg();

        address hedge = vaultFactory.getVaults(1)[0];
        address risk = vaultFactory.getVaults(1)[1];

        Vault vHedge = Vault(hedge);
        Vault vRisk = Vault(risk);

        vm.warp(beginEpoch + 10 days);

        emit log_named_int("strike price", vHedge.strikePrice());
        emit log_named_int("oracle price", controller.getLatestPrice(tokenFRAX));

        controller.triggerDepeg(SINGLE_MARKET_INDEX, endEpoch);

        assertTrue(vHedge.totalAssets(endEpoch) == vRisk.idClaimTVL(endEpoch), "Claim TVL Risk not equal to Total Tvl Hedge");
        assertTrue(vRisk.totalAssets(endEpoch) == vHedge.idClaimTVL(endEpoch), "Claim TVL Hedge not equal to Total Tvl Risk");
    }

    function testControllerEndEpoch() public{

        testDeposit();

        address hedge = vaultFactory.getVaults(1)[0];
        address risk = vaultFactory.getVaults(1)[1];

        Vault vHedge = Vault(hedge);
        Vault vRisk = Vault(risk);

        vm.warp(endEpoch + 1 days);

        emit log_named_int("strike price", vHedge.strikePrice());
        emit log_named_int("oracle price", controller.getLatestPrice(tokenFRAX));

        controller.triggerEndEpoch(SINGLE_MARKET_INDEX, endEpoch);
        
        emit log_named_uint("total assets value", vHedge.totalAssets(endEpoch));
        

        assertTrue(vHedge.totalAssets(endEpoch) == vHedge.idFinalTVL(endEpoch), "Claim TVL not equal");
        //emit log_named_uint("claim tvl", vHedge.idClaimTVL(endEpoch));
        assertTrue(vRisk.idClaimTVL(endEpoch) == vHedge.idFinalTVL(endEpoch) + vRisk.idFinalTVL(endEpoch), "Claim TVL not equal");
        assertTrue(NULL_BALANCE == vHedge.idClaimTVL(endEpoch), "Hedge Claim TVL not zero");
    }

    function testCreateController() public {
        vm.startPrank(admin);
        Controller test_controller = new Controller(address(vaultFactory),admin, arbitrum_sequencer);
        assertEq(address(vaultFactory), address(test_controller.vaultFactory()));
        assertEq(admin, test_controller.admin());
        vm.stopPrank();
    }

    

    /*function testTriggerDepeg() public {
        DepositDepeg();
        vm.startPrank(admin);
        DepegOracle depegOracle = new DepegOracle(address(oracleFRAX), address(admin));
        Controller controller = new Controller(address(vaultFactory),admin, arbitrum_sequencer);
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, address(depegOracle), "y2kFRAX_99*");
        vaultFactory.setController(address(controller));
        vm.stopPrank();

        vm.warp(beginEpoch + 1 days);
        controller.triggerDepeg(vaultFactory.marketIndex(), endEpoch);
        VaultFactory testFactory = controller.vaultFactory();
        assertEq(vaultFactory.getVaults(vaultFactory.marketIndex()), testFactory.getVaults(testFactory.marketIndex()));

    }*/

    function testTriggerEndEpoch() public {
        DepositDepeg();
        vm.startPrank(admin);
        Controller test_controller = new Controller(address(vaultFactory),admin, arbitrum_sequencer);
        vaultFactory.setController(address(test_controller));
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_99*");
        vm.warp(endEpoch + 1 days);
        controller.triggerEndEpoch(SINGLE_MARKET_INDEX, endEpoch);
        VaultFactory testFactory = controller.vaultFactory();
        assertEq(vaultFactory.getVaults(vaultFactory.marketIndex()), testFactory.getVaults(testFactory.marketIndex()));
        vm.stopPrank();
    }

    /*///////////////////////////////////////////////////////////////
                           WITHDRAW functions
    //////////////////////////////////////////////////////////////*/

    function testWithdrawDepeg() public {
        testControllerDepeg();

        address hedge = vaultFactory.getVaults(1)[0];
        address risk = vaultFactory.getVaults(1)[1];

        Vault vHedge = Vault(hedge);
        Vault vRisk = Vault(risk);

        uint assets;

        //ALICE hedge WITHDRAW
        vm.startPrank(alice);
        assets = vHedge.balanceOf(alice,endEpoch);
        vHedge.withdraw(endEpoch, assets, alice, alice);

        assertTrue(vHedge.balanceOf(alice,endEpoch) == NULL_BALANCE);
        uint256 entitledShares = vHedge.previewWithdraw(endEpoch, assets);
        assertTrue(entitledShares - vHedge.calculateWithdrawalFeeValue(entitledShares,endEpoch) == ERC20(WETH).balanceOf(alice));

        vm.stopPrank();

        //BOB hedge WITHDRAW
        vm.startPrank(bob);
        assets = vHedge.balanceOf(bob,endEpoch);
        vHedge.withdraw(endEpoch, assets, bob, bob);
        
        assertTrue(vHedge.balanceOf(bob,endEpoch) == NULL_BALANCE);
        entitledShares = vHedge.previewWithdraw(endEpoch, assets);
        assertTrue(entitledShares - vHedge.calculateWithdrawalFeeValue(entitledShares,endEpoch) == ERC20(WETH).balanceOf(bob));

        vm.stopPrank();

        emit log_named_uint("hedge balance", ERC20(WETH).balanceOf(address(vHedge)));

        //CHAD risk WITHDRAW
        vm.startPrank(chad);
        assets = vRisk.balanceOf(chad,endEpoch);
        vRisk.withdraw(endEpoch, assets, chad, chad);

        assertTrue(vRisk.balanceOf(chad,endEpoch) == NULL_BALANCE);
        entitledShares = vRisk.previewWithdraw(endEpoch, assets);
        assertTrue(entitledShares - vRisk.calculateWithdrawalFeeValue(entitledShares,endEpoch) == ERC20(WETH).balanceOf(chad));

        vm.stopPrank();

        //DEGEN risk WITHDRAW
        vm.startPrank(degen);
        assets = vRisk.balanceOf(degen,endEpoch);
        vRisk.withdraw(endEpoch, assets, degen, degen);

        assertTrue(vRisk.balanceOf(degen,endEpoch) == NULL_BALANCE);
        entitledShares = vRisk.previewWithdraw(endEpoch, assets);
        assertTrue(entitledShares - vRisk.calculateWithdrawalFeeValue(entitledShares,endEpoch) == ERC20(WETH).balanceOf(degen));

        vm.stopPrank();

        emit log_named_uint("risk balance", ERC20(WETH).balanceOf(address(vRisk)));
    }


    /*///////////////////////////////////////////////////////////////
                           VAULTFACTORY functions
    //////////////////////////////////////////////////////////////*/
    
    function testCreateVaultFactory() public {
        vm.startPrank(admin);
        VaultFactory testFactory = new VaultFactory(address(controller), address(tokenFRAX), address(admin));
        assertEq(address(controller), testFactory.treasury());
        assertEq(address(tokenFRAX), testFactory.WETH());
        assertEq(address(admin), testFactory.Admin());
        vm.stopPrank();
    }


    /*///////////////////////////////////////////////////////////////
                           GOVTOKEN functions
    //////////////////////////////////////////////////////////////*/

    function testMintGovToken() public {
        vm.startPrank(admin);
        vaultFactory.createNewMarket(NULL_BALANCE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, oracleFRAX, "y2kSTETH_99*");
        rewardsFactory.createStakingRewards(SINGLE_MARKET_INDEX, endEpoch, REWARDS_DURATION, REWARD_RATE);
        govToken.moneyPrinterGoesBrr(alice);
        uint256 aliceBalance = ERC20(address(govToken)).balanceOf(alice);
        emit log_named_int("Alice Balance", int256(aliceBalance));
        assert(aliceBalance != NULL_BALANCE);
        vm.stopPrank();
    }

    /*///////////////////////////////////////////////////////////////
                           REWARDSFACTORY functions
    //////////////////////////////////////////////////////////////*/

    function testStakingRewards() public {
        //address exists
        vm.startPrank(admin);
        vaultFactory.createNewMarket(FEE, tokenSTETH, DEPEG_AAA, beginEpoch, endEpoch, oracleFRAX, "y2kSTETH_99*");
        //to-do:expect emit CreatedStakingReward
        rewardsFactory.createStakingRewards(SINGLE_MARKET_INDEX, endEpoch, REWARDS_DURATION, REWARD_RATE);
        //to-do: assert if rewards exist and != 0
        (,address firstAdd) = rewardsFactory.createStakingRewards(SINGLE_MARKET_INDEX, endEpoch, REWARDS_DURATION, REWARD_RATE);
        (address secondAdd,) = rewardsFactory.createStakingRewards(SINGLE_MARKET_INDEX, endEpoch, REWARDS_DURATION, REWARD_RATE);
        assert((firstAdd != address(0)) && (secondAdd != address(0)));
        vm.stopPrank();

        //works for multiple/all markets
        vm.startPrank(admin);
        // Create FRAX markets
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_99*");
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_BBB, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_97*");
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_CCC, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_95*");

        // Create MIM markets
        vaultFactory.createNewMarket(FEE, tokenMIM, DEPEG_AAA, beginEpoch, endEpoch, oracleMIM, "y2kMIM_99*");
        vaultFactory.createNewMarket(FEE, tokenMIM, DEPEG_BBB, beginEpoch, endEpoch, oracleMIM, "y2kMIM_97*");
        vaultFactory.createNewMarket(FEE, tokenMIM, DEPEG_CCC, beginEpoch, endEpoch, oracleMIM, "y2kMIM_95*");

        // Create FEI markets
        vaultFactory.createNewMarket(FEE, tokenFEI, DEPEG_AAA, beginEpoch, endEpoch, oracleFEI, "y2kFEI_99*");
        vaultFactory.createNewMarket(FEE, tokenFEI, DEPEG_BBB, beginEpoch, endEpoch, oracleFEI, "y2kFEI_97*");
        vaultFactory.createNewMarket(FEE, tokenFEI, DEPEG_CCC, beginEpoch, endEpoch, oracleFEI, "y2kFEI_95*");

        // Create USDC markets
        vaultFactory.createNewMarket(FEE, tokenUSDC, DEPEG_AAA, beginEpoch, endEpoch, oracleUSDC, "y2kUSDC_99*");
        vaultFactory.createNewMarket(FEE, tokenUSDC, DEPEG_BBB, beginEpoch, endEpoch, oracleUSDC, "y2kUSDC_97*");
        vaultFactory.createNewMarket(FEE, tokenUSDC, DEPEG_CCC, beginEpoch, endEpoch, oracleUSDC, "y2kUSDC_95*");

        // Create DAI markets
        vaultFactory.createNewMarket(FEE, tokenDAI, DEPEG_AAA, beginEpoch, endEpoch, oracleDAI, "y2kDAI_99*");
        vaultFactory.createNewMarket(FEE, tokenDAI, DEPEG_BBB, beginEpoch, endEpoch, oracleDAI, "y2kDAI_97*");
        vaultFactory.createNewMarket(FEE, tokenDAI, DEPEG_CCC, beginEpoch, endEpoch, oracleDAI, "y2kDAI_95*");

        //to-do:change counter to non static variable
        for (uint256 i = SINGLE_MARKET_INDEX; i <= ALL_MARKETS_INDEX; i++){
            rewardsFactory.createStakingRewards(i, endEpoch, REWARDS_DURATION, REWARD_RATE);
            (,address firstAddLoop) = rewardsFactory.createStakingRewards(SINGLE_MARKET_INDEX, endEpoch, REWARDS_DURATION, REWARD_RATE);
            (address secondAddLoop,) = rewardsFactory.createStakingRewards(SINGLE_MARKET_INDEX, endEpoch, REWARDS_DURATION, REWARD_RATE);
            assert(((firstAddLoop != address(0))) && (secondAddLoop != address(0)));
        }
        vm.stopPrank();
    
    }


    function testGetHashedIndex() public{
        vm.startPrank(admin);
        bytes32 hashedIndex = rewardsFactory.getHashedIndex(SINGLE_MARKET_INDEX, beginEpoch);
        assertEq(hashedIndex, keccak256(abi.encode(SINGLE_MARKET_INDEX, beginEpoch)));
        vm.stopPrank();
    }


    /*//////////////////////////////////////////////////////////////
                           PEGORACLE functions
    //////////////////////////////////////////////////////////////*/

    function testCreatePegOracle() public {
        PegOracle pegOracle = new PegOracle(oracleSTETH, oracleETH);
        assertEq(address(pegOracle.oracle1()), oracleSTETH);
        assertEq(address(pegOracle.oracle2()), oracleETH);
    }

    function testLatestRoundData() public {
        vm.startPrank(admin);
        PegOracle pegOracle = new PegOracle(oracleSTETH, oracleETH);
        pegOracle.latestRoundData();
        vm.stopPrank();

    }

    function testOracle1Price() public {
        vm.startPrank(admin);
        PegOracle pegOracle = new PegOracle(oracleSTETH, oracleETH);
        pegOracle.getOracle1_Price();
        vm.stopPrank();

    }

    function testPegOracleDecimals() public {
        vm.startPrank(admin);
        PegOracle pegOracle = new PegOracle(oracleSTETH, oracleETH);
        emit log_named_uint("PegOracle decimals", pegOracle.decimals());
        assertTrue(pegOracle.decimals() == DECIMALS);
        AggregatorV3Interface testOracle1 = AggregatorV3Interface(oracleSTETH);
        AggregatorV3Interface testOracle2 = AggregatorV3Interface(oracleETH);
        assertTrue(testOracle1.decimals() == testOracle2.decimals());
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                           AUTHORIZATION functions
    //////////////////////////////////////////////////////////////*/
    

    function testOwnerAuthorize() public {
        vm.deal(alice, 10 ether);
        
        vm.startPrank(admin);
        FakeOracle fakeOracle = new FakeOracle(oracleFRAX, STRIKE_PRICE_FAKE_ORACLE);
        vaultFactory.createNewMarket(FEE, tokenFRAX, DEPEG_AAA, beginEpoch, endEpoch, address(fakeOracle), "y2kFRAX_99*");
        vm.stopPrank();

        address hedge = vaultFactory.getVaults(1)[0];
        Vault vHedge = Vault(hedge);

        vm.startPrank(alice);
        ERC20(WETH).approve(hedge, 10 ether);
        vHedge.depositETH{value: 10 ether}(endEpoch, alice);

        assertTrue(vHedge.balanceOf(alice,endEpoch) == (10 ether));
        vm.stopPrank();

        vm.startPrank(alice);
        vm.warp(endEpoch + 1 days);
        controller.triggerEndEpoch(vaultFactory.marketIndex(), endEpoch);
        vHedge.setApprovalForAll(bob, true);
        if(vHedge.isApprovedForAll(alice, bob)){
            emit log_named_uint("Can continue", 1);
        }

        else {
            emit log_named_uint("Cannot continue", 0);
        }
        vm.stopPrank();
        
        vm.startPrank(bob);
        vHedge.withdraw(endEpoch, 10 ether, bob, alice);
        vm.stopPrank();
    }

    
}