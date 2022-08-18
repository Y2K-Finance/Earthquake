// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "forge-std/Test.sol";
import {Vault} from "../src/Vault.sol";
import {VaultFactory} from "../src/VaultFactory.sol";
import {Controller} from "../src/Controller.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";

import {IWETH} from "./interfaces/IWETH.sol";
import {GovToken} from "./GovToken.sol";

contract SemiFungibleVaultTest is Test {

    struct UserInfo{
        address user;
        address receiver;
        address real_user;
    }

    //mainnet weth address
    address assetWETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant treasury =
        0xEAE1f7b21B7f6c711C441d85eE5ab53E4A626D65;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant USDT_oracle =
        0x3E7d1eAB13ad0104d2750B8863b489D65364e32D;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant USDC_oracle =
        0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6;
    VaultFactory vaultFactory;
    Controller controller;
    ERC20 govToken;
    
    //address WETH = 0xEBbc3452Cc911591e4F18f3b36727Df45d6bd1f9;

    /*//////////////////////////////////////////////////////////////
                                Creation TESTS
    //////////////////////////////////////////////////////////////*/

    function setUp() public {
        vaultFactory = new VaultFactory(treasury, assetWETH, address(this));
        govToken = new GovToken();
        controller = new Controller(address(vaultFactory), address(this));
        vaultFactory.setController(address(controller));
    }

    function testCreationNewVaultsDepeg()
        public
        returns (address insr, address risk)
    {
        uint256 fee = 5;
        uint256 withdrawalFee = 50;
        int256 strikePrice = 120000000; //1$ = 100000000
        uint256 epochBegin = block.timestamp + 2 days;
        uint256 epochEnd = block.timestamp + 30 days;
        return
            vaultFactory.createNewMarket(
                fee,
                withdrawalFee,
                USDC,
                strikePrice,
                epochBegin,
                epochEnd,
                USDC_oracle,
                "Y2K.USDC.1,20$"
            );
    }

    function testCreationNewVaultsNODepeg()
        public
        returns (address insr, address risk)
    {
        uint256 fee = 5;
        uint256 withdrawalFee = 50;
        int256 strikePrice = 90000000; //1$ = 100000000
        uint256 epochBegin = block.timestamp + 2 days; 
        uint256 epochEnd = block.timestamp + 30 days;
        return
            vaultFactory.createNewMarket(
                fee,
                withdrawalFee,
                USDC,
                strikePrice,
                epochBegin,
                epochEnd,
                USDC_oracle,
                "Y2K.USDC.0.90$"
            );
    }

    /*//////////////////////////////////////////////////////////////
                                Deposit TESTS
    //////////////////////////////////////////////////////////////*/

    function testDepositInsurance() public {
        address user = address(1);
        uint256 amount = 8225082557140;
        uint256 ID = block.timestamp + 30 days;

        (address insurance, ) = testCreationNewVaultsDepeg();

        emit log(Vault(insurance).name());

        vm.startPrank(user);

        uint256 balance = ERC20(assetWETH).balanceOf(user);
        emit log_named_uint("Balance ", balance);

        ERC20(assetWETH).approve(insurance, amount);
        Vault(insurance).deposit(ID, amount, user);

        uint256 vaultBalance = ERC20(assetWETH).balanceOf(insurance);
        emit log_named_uint("Vault Balance ", vaultBalance);

        uint256 newbalance = ERC20(assetWETH).balanceOf(user);
        emit log_named_uint("Balance ", newbalance);

        uint256 user_vaultbalance = Vault(insurance).balanceOf(user, ID);
        emit log_named_uint("User Vault Balance ", user_vaultbalance);

        uint256 trzbalance = ERC20(assetWETH).balanceOf(treasury);
        emit log_named_uint("Treasury Balance ", trzbalance);

        vm.stopPrank();
    }

    function testFailDepositWrongID() public {
        address user = address(1);
        uint256 amount = 8225082557140;
        uint256 ID = 1; //Wrong ID

        (address insurance, ) = testCreationNewVaultsDepeg();

        vm.startPrank(user);

        ERC20(assetWETH).approve(insurance, amount);
        Vault(insurance).deposit(ID, amount, user);

        vm.stopPrank();
    }

    function testFailDepositOutOfTime() public {
        address user = address(1);
        uint256 amount = 8225082557140;
        uint256 ID = block.timestamp + 30 days;
        uint256 warpTime = ID;

        (address insurance, ) = testCreationNewVaultsDepeg();
        emit log_named_uint("Block ", block.timestamp);
        vm.warp(warpTime);
        emit log_named_uint("Block Warp", block.timestamp);

        vm.startPrank(user);

        ERC20(assetWETH).approve(insurance, amount);
        Vault(insurance).deposit(ID, amount, user);

        vm.stopPrank();
    }

    function testDepositRisk() public {
        address user = address(2);
        uint256 amount = 5 ether;
        uint256 ID = block.timestamp + 30 days;
        (, address risk) = testCreationNewVaultsDepeg();

        vm.startPrank(user);
        vm.deal(user, amount);
        // swap to weth
        IWETH(assetWETH).deposit{value: amount}();

        uint256 balance = ERC20(assetWETH).balanceOf(user);
        emit log_named_uint("Balance ", balance);

        ERC20(assetWETH).approve(risk, amount);
        Vault(risk).deposit(ID, amount, user);

        uint256 vaultBalance = ERC20(assetWETH).balanceOf(risk);
        emit log_named_uint("Vault Balance ", vaultBalance);

        uint256 newbalance = ERC20(assetWETH).balanceOf(user);
        emit log_named_uint("Balance ", newbalance);

        uint256 user_vaultbalance = Vault(risk).balanceOf(user, ID);
        emit log_named_uint("User Vault Balance ", user_vaultbalance);

        uint256 trzbalance = ERC20(assetWETH).balanceOf(treasury);
        emit log_named_uint("Treasury Balance ", trzbalance);

        vm.stopPrank();
    }

    function testDepositBothVaults()
        public
        returns (
            uint256 epoch,
            address _insurance,
            address _risk
        )
    {
        address user = address(1);
        uint256 amount = 8225082557140;
        uint256 ID = block.timestamp + 30 days;

        (address insurance, address risk) = testCreationNewVaultsDepeg();

        vm.startPrank(user);

        uint256 balance = ERC20(assetWETH).balanceOf(user);
        emit log_named_uint("Balance ", balance);

        ERC20(assetWETH).approve(insurance, amount);
        Vault(insurance).deposit(ID, amount, user);

        uint256 insr_vaultBalance = ERC20(assetWETH).balanceOf(insurance);
        emit log_named_uint("Vault Balance ", insr_vaultBalance);
        uint256 newbalance = ERC20(assetWETH).balanceOf(user);
        emit log_named_uint("Balance ", newbalance);

        uint256 user_vaultbalance = Vault(insurance).balanceOf(user, ID);
        emit log_named_uint("User Vault Balance ", user_vaultbalance);

        uint256 trzbalance = ERC20(assetWETH).balanceOf(treasury);
        emit log_named_uint("Treasury Balance ", trzbalance);

        vm.stopPrank();

        user = address(2);
        amount = 5 ether;
        ID = block.timestamp + 30 days;

        vm.startPrank(user);
        vm.deal(user, amount);
        // swap to weth
        IWETH(assetWETH).deposit{value: amount}();

        balance = ERC20(assetWETH).balanceOf(user);
        emit log_named_uint("Balance ", balance);

        ERC20(assetWETH).approve(risk, amount);
        Vault(risk).deposit(ID, amount, user);

        uint256 risk_vaultBalance = ERC20(assetWETH).balanceOf(risk);
        emit log_named_uint("Vault Balance ", risk_vaultBalance);

        newbalance = ERC20(assetWETH).balanceOf(user);
        emit log_named_uint("Balance ", newbalance);

        user_vaultbalance = Vault(risk).balanceOf(user, ID);
        emit log_named_uint("User Vault Balance ", user_vaultbalance);

        trzbalance = ERC20(assetWETH).balanceOf(treasury);
        emit log_named_uint("Treasury Balance ", trzbalance);

        vm.stopPrank();

        return (ID, insurance, risk);
    }

    function testDepositBothVaultsNODepeg()
        public
        returns (
            uint256 epoch,
            address _insurance,
            address _risk
        )
    {
        address user = address(1);
        uint256 amount = 8225082557140;
        uint256 ID = block.timestamp + 30 days;

        (address insurance, address risk) = testCreationNewVaultsNODepeg();

        vm.startPrank(user);

        uint256 balance = ERC20(assetWETH).balanceOf(user);
        emit log_named_uint("Balance ", balance);

        ERC20(assetWETH).approve(insurance, amount);
        Vault(insurance).deposit(ID, amount, user);

        uint256 insr_vaultBalance = ERC20(assetWETH).balanceOf(insurance);
        emit log_named_uint("Vault Balance ", insr_vaultBalance);
        uint256 newbalance = ERC20(assetWETH).balanceOf(user);
        emit log_named_uint("Balance ", newbalance);

        uint256 user_vaultbalance = Vault(insurance).balanceOf(user, ID);
        emit log_named_uint("User Vault Balance ", user_vaultbalance);

        uint256 trzbalance = ERC20(assetWETH).balanceOf(treasury);
        emit log_named_uint("Treasury Balance ", trzbalance);

        vm.stopPrank();

        user = address(2);
        amount = 5 ether;
        ID = block.timestamp + 30 days;

        vm.startPrank(user);
        vm.deal(user, amount);
        // swap to weth
        IWETH(assetWETH).deposit{value: amount}();

        balance = ERC20(assetWETH).balanceOf(user);
        emit log_named_uint("Balance ", balance);

        ERC20(assetWETH).approve(risk, amount);
        Vault(risk).deposit(ID, amount, user);

        uint256 risk_vaultBalance = ERC20(assetWETH).balanceOf(risk);
        emit log_named_uint("Vault Balance ", risk_vaultBalance);

        newbalance = ERC20(assetWETH).balanceOf(user);
        emit log_named_uint("Balance ", newbalance);

        user_vaultbalance = Vault(risk).balanceOf(user, ID);
        emit log_named_uint("User Vault Balance ", user_vaultbalance);

        trzbalance = ERC20(assetWETH).balanceOf(treasury);
        emit log_named_uint("Treasury Balance ", trzbalance);

        vm.stopPrank();

        return (ID, insurance, risk);
    }

    /*//////////////////////////////////////////////////////////////
                                Mint TESTS
    //////////////////////////////////////////////////////////////*/

    function testMintInsurance() public {
        address user = address(1);
        uint256 amount = 8225082557140;
        uint256 ID = block.timestamp + 30 days;

        (address insurance, ) = testCreationNewVaultsDepeg();

        vm.startPrank(user);

        uint256 balance = ERC20(assetWETH).balanceOf(user);
        emit log_named_uint("Balance ", balance);

        ERC20(assetWETH).approve(insurance, amount);
        Vault(insurance).mint(ID, amount, user);

        uint256 insr_vaultBalance = ERC20(assetWETH).balanceOf(insurance);
        emit log_named_uint("Vault Balance ", insr_vaultBalance);
        uint256 newbalance = ERC20(assetWETH).balanceOf(user);
        emit log_named_uint("Balance ", newbalance);

        uint256 user_vaultbalance = Vault(insurance).balanceOf(user, ID);
        emit log_named_uint("User Vault Balance ", user_vaultbalance);

        uint256 trzbalance = ERC20(assetWETH).balanceOf(treasury);
        emit log_named_uint("Treasury Balance ", trzbalance);

        vm.stopPrank();
    }

    function testFailMintWrongID() public {
        address user = address(1);
        uint256 amount = 8225082557140;
        uint256 ID = 1; //Wrong ID

        (address insurance, ) = testCreationNewVaultsDepeg();

        vm.startPrank(user);

        ERC20(assetWETH).approve(insurance, amount);
        Vault(insurance).mint(ID, amount, user);

        vm.stopPrank();
    }

    function testFailMintOutOfTime() public {
        address user = address(1);
        uint256 amount = 8225082557140;
        uint256 ID = block.timestamp + 30 days;
        uint256 warpTime = ID;

        (address insurance, ) = testCreationNewVaultsDepeg();
        emit log_named_uint("Block ", block.timestamp );
        vm.warp(warpTime);
        emit log_named_uint("Block Warp", block.timestamp);

        vm.startPrank(user);

        ERC20(assetWETH).approve(insurance, amount);
        Vault(insurance).mint(ID, amount, user);

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                                Keeper TESTS
    //////////////////////////////////////////////////////////////*/

    function testDepegKeeper()
        public
        returns (
            uint256 _id,
            address _insurance,
            address _risk
        )
    {
        (uint256 ID, address insurance, address risk) = testDepositBothVaults();

        vm.warp(ID - 10 days);

        uint256 index = 1; //vaultFactory.marketIndex();

        Vault insrVault = Vault(insurance);

        int256 priceNow = controller.getLatestPrice(insrVault.tokenInsured());
        int256 strikePrice = insrVault.strikePrice();
        emit log_named_int("Strike Price ", strikePrice);
        emit log_named_int("Latest Price ", priceNow);

        uint256 insr_vaultBalance = ERC20(assetWETH).balanceOf(insurance);
        emit log_named_uint(
            "Before Insurance Vault Balance ",
            insr_vaultBalance
        );

        uint256 risk_vaultBalance = ERC20(assetWETH).balanceOf(risk);
        emit log_named_uint("Before Risk Vault Balance ", risk_vaultBalance);
        controller.triggerDepeg(index, ID);

        insr_vaultBalance = ERC20(assetWETH).balanceOf(insurance);
        emit log_named_uint(
            "After Insurance Vault Balance ",
            insr_vaultBalance
        );

        risk_vaultBalance = ERC20(assetWETH).balanceOf(risk);
        emit log_named_uint("After Risk Vault Balance ", risk_vaultBalance);

        return (ID, insurance, risk);
    }

    function testFailDepegKeeper()
        public
        returns (
            uint256 _id,
            address _insurance,
            address _risk
        )
    {
        (
            uint256 ID,
            address insurance,
            address risk
        ) = testDepositBothVaultsNODepeg();

        uint256 index = 1; //vaultFactory.marketIndex();

        vm.warp(ID - 5 days);

        Vault insrVault = Vault(insurance);

        int256 priceNow = controller.getLatestPrice(insrVault.tokenInsured());
        int256 strikePrice = insrVault.strikePrice();
        emit log_named_int("Strike Price ", strikePrice);
        emit log_named_int("Latest Price ", priceNow);

        uint256 insr_vaultBalance = ERC20(assetWETH).balanceOf(insurance);
        emit log_named_uint(
            "Before Insurance Vault Balance ",
            insr_vaultBalance
        );

        uint256 risk_vaultBalance = ERC20(assetWETH).balanceOf(risk);
        emit log_named_uint("Before Risk Vault Balance ", risk_vaultBalance);
        controller.triggerDepeg(index, ID);

        insr_vaultBalance = ERC20(assetWETH).balanceOf(insurance);
        emit log_named_uint(
            "After Insurance Vault Balance ",
            insr_vaultBalance
        );

        risk_vaultBalance = ERC20(assetWETH).balanceOf(risk);
        emit log_named_uint("After Risk Vault Balance ", risk_vaultBalance);

        return (ID, insurance, risk);
    }

    function testEndEpochKeeper()
        public
        returns (
            uint256 _id,
            address _insurance,
            address _risk
        )
    {
        (
            uint256 ID,
            address insurance,
            address risk
        ) = testDepositBothVaultsNODepeg();

        uint256 index = 1; //vaultFactory.marketIndex();

        vm.warp(ID);

        Vault insrVault = Vault(insurance);

        int256 priceNow = controller.getLatestPrice(insrVault.tokenInsured());
        int256 strikePrice = insrVault.strikePrice();
        emit log_named_int("Strike Price ", strikePrice);
        emit log_named_int("Latest Price ", priceNow);

        uint256 insr_vaultBalance = ERC20(assetWETH).balanceOf(insurance);
        emit log_named_uint(
            "Before Insurance Vault Balance ",
            insr_vaultBalance
        );

        uint256 risk_vaultBalance = ERC20(assetWETH).balanceOf(risk);
        emit log_named_uint("Before Risk Vault Balance ", risk_vaultBalance);
        controller.triggerEndEpoch(index, ID);

        insr_vaultBalance = ERC20(assetWETH).balanceOf(insurance);
        emit log_named_uint(
            "After Insurance Vault Balance ",
            insr_vaultBalance
        );

        risk_vaultBalance = ERC20(assetWETH).balanceOf(risk);
        emit log_named_uint("After Risk Vault Balance ", risk_vaultBalance);

        return (ID, insurance, risk);
    }

    /*//////////////////////////////////////////////////////////////
                                Withdraw TESTS
    //////////////////////////////////////////////////////////////*/

    function testWithdrawBoth() public {
        (uint256 ID, address insurance, address risk) = testDepegKeeper();
        Vault insrVault = Vault(insurance);
        Vault riskVault = Vault(risk);

        //INSURANCE WITHDRAW
        address user = address(1);
        address receiver = address(3);
        vm.startPrank(user);

        uint256 user_insr_vaultbalance = insrVault.balanceOf(
            user,
            ID
        );
        emit log_named_uint(
            "Insurance User Vault Balance Before Withdraw ",
            user_insr_vaultbalance
        );

        uint256 insr_finalTVL = insrVault.idFinalTVL(ID);
        emit log_named_uint("Insurance Final TVL", insr_finalTVL);

        uint256 insr_vaultBalance = ERC20(assetWETH).balanceOf(insurance);
        emit log_named_uint(
            "Before Insurance WETH Vault Balance ",
            insr_vaultBalance
        );
        uint256 entitledShares = insrVault.withdraw(
            ID,
            user_insr_vaultbalance,
            receiver,
            user
        );

        user_insr_vaultbalance = insrVault.balanceOf(user, ID);
        emit log_named_uint(
            "Insurance User Vault Balance After Withdraw",
            user_insr_vaultbalance
        );

        emit log_named_uint(
            "Insurance User Entitled Shares of Vault Withdraw",
            entitledShares
        );

        insr_vaultBalance = ERC20(assetWETH).balanceOf(insurance);
        emit log_named_uint(
            "After  Insurance WETH Vault Balance ",
            insr_vaultBalance
        );

        user_insr_vaultbalance = ERC20(assetWETH).balanceOf(receiver);
        emit log_named_uint(
            "After Insurance Receiver WETH Vault Balance ",
            user_insr_vaultbalance
        );

        vm.stopPrank();

        //RISK WITHDRAW
        address risk_user = address(2);
        vm.startPrank(risk_user);

        uint256 user_risk_vaultbalance = riskVault.balanceOf(risk_user, ID);
        emit log_named_uint(
            "Risk User Vault Balance Before Withdraw ",
            user_risk_vaultbalance
        );

        riskVault.withdraw(ID, user_risk_vaultbalance, risk_user, risk_user);

        user_risk_vaultbalance = riskVault.balanceOf(risk_user, ID);
        emit log_named_uint(
            "Risk User Vault Balance After Withdraw ",
            user_risk_vaultbalance
        );

        uint256 user_risk_balance = ERC20(assetWETH).balanceOf(risk_user);
        emit log_named_uint(
            "Risk User WETH Balance After Withdraw ",
            user_risk_balance
        );

        vm.stopPrank();

        uint256 risk_vaultBalance = ERC20(assetWETH).balanceOf(risk);
        emit log_named_uint(
            "Risk Vault WETH Balance After Withdraw",
            risk_vaultBalance
        );
    }

    function testWithdrawBothNODepeg() public {
        (uint256 ID, address insurance, address risk) = testEndEpochKeeper();
        Vault insrVault = Vault(insurance);
        Vault riskVault = Vault(risk);

        vm.warp(ID);

        //INSURANCE WITHDRAW
        address user = address(1);
        address receiver = address(3);
        vm.startPrank(user);

        uint256 user_insr_vaultbalance = insrVault.balanceOf(
            user,
            ID
        );
        emit log_named_uint(
            "Insurance User Vault Balance Before Withdraw ",
            user_insr_vaultbalance
        );

        uint256 insr_finalTVL = insrVault.idFinalTVL(ID);
        emit log_named_uint("Insurance Final TVL", insr_finalTVL);

        uint256 insr_vaultBalance = ERC20(assetWETH).balanceOf(insurance);
        emit log_named_uint(
            "Before Insurance WETH Vault Balance ",
            insr_vaultBalance
        );
        uint256 entitledShares = insrVault.withdraw(
            ID,
            user_insr_vaultbalance,
            receiver,
            user
        );

        user_insr_vaultbalance = insrVault.balanceOf(user, ID);
        emit log_named_uint(
            "Insurance User Vault Balance After Withdraw",
            user_insr_vaultbalance
        );

        emit log_named_uint(
            "Insurance User Entitled Shares of Vault Withdraw",
            entitledShares
        );

        insr_vaultBalance = ERC20(assetWETH).balanceOf(insurance);
        emit log_named_uint(
            "After  Insurance WETH Vault Balance ",
            insr_vaultBalance
        );

        user_insr_vaultbalance = ERC20(assetWETH).balanceOf(receiver);
        emit log_named_uint(
            "After Insurance Receiver WETH Vault Balance ",
            user_insr_vaultbalance
        );

        vm.stopPrank();

        //RISK WITHDRAW
        address risk_user = address(2);
        vm.startPrank(risk_user);

        uint256 user_risk_vaultbalance = riskVault.balanceOf(risk_user, ID);
        emit log_named_uint(
            "Risk User Vault Balance Before Withdraw ",
            user_risk_vaultbalance
        );

        riskVault.withdraw(ID, user_risk_vaultbalance, risk_user, risk_user);

        user_risk_vaultbalance = riskVault.balanceOf(risk_user, ID);
        emit log_named_uint(
            "Risk User Vault Balance After Withdraw ",
            user_risk_vaultbalance
        );

        uint256 user_risk_balance = ERC20(assetWETH).balanceOf(risk_user);
        emit log_named_uint(
            "Risk User WETH Balance After Withdraw ",
            user_risk_balance
        );

        vm.stopPrank();

        uint256 risk_vaultBalance = ERC20(assetWETH).balanceOf(risk);
        emit log_named_uint(
            "Risk Vault WETH Balance After Withdraw",
            risk_vaultBalance
        );
    }

    function testWithdrawForSomeone() public{
        (uint256 ID, address insurance, address risk) = testDepegKeeper();
        Vault insrVault = Vault(insurance);
        Vault riskVault = Vault(risk);

        //INSURANCE WITHDRAW
        UserInfo memory insr_user_info = UserInfo(
            address(6),
            address(5),
            address(1)
        );

        vm.prank(insr_user_info.real_user);
        insrVault.setApprovalForAll(insr_user_info.user, true);

        vm.startPrank(insr_user_info.user);        

        // Is Approved For All ?
        bool isApproved = insrVault.isApprovedForAll(insr_user_info.real_user, insr_user_info.user);
        if(!isApproved){
            emit log_named_string("INSURANCE Is Approved", "No");
        }
        else{
            emit log_named_string("INSURANCE Is Approved", "Yes");
        }

        uint256 user_insr_vaultbalance = insrVault.balanceOf(
            insr_user_info.real_user,
            ID
        );
        emit log_named_uint(
            "Insurance Real User 1 Vault Balance Before Withdraw ",
            user_insr_vaultbalance
        );

        uint256 insr_finalTVL = insrVault.idFinalTVL(ID);
        emit log_named_uint("Insurance Final TVL", insr_finalTVL);

        uint256 insr_vaultBalance = ERC20(assetWETH).balanceOf(insurance);
        emit log_named_uint(
            "Before Insurance WETH Vault Balance ",
            insr_vaultBalance
        );
        uint256 entitledShares = insrVault.withdraw(
            ID,
            user_insr_vaultbalance,
            insr_user_info.user,
            insr_user_info.real_user
        );

        user_insr_vaultbalance = insrVault.balanceOf(insr_user_info.real_user, ID);
        emit log_named_uint(
            "Insurance Real User 1 Vault Balance After Withdraw",
            user_insr_vaultbalance
        );

        emit log_named_uint(
            "Insurance User Entitled Shares of Vault Withdraw",
            entitledShares
        );

        insr_vaultBalance = ERC20(assetWETH).balanceOf(insurance);
        emit log_named_uint(
            "After  Insurance WETH Vault Balance ",
            insr_vaultBalance
        );

        user_insr_vaultbalance = ERC20(assetWETH).balanceOf(insr_user_info.user);
        emit log_named_uint(
            "After Insurance Bad User 6 WETH Vault Balance ",
            user_insr_vaultbalance
        );

        vm.stopPrank();

        //RISK WITHDRAW
        UserInfo memory risk_user_info = UserInfo(
            address(8),
            address(7),
            address(2)
        );
        
        vm.prank(risk_user_info.real_user);
        riskVault.setApprovalForAll(risk_user_info.user, true);

        vm.startPrank(risk_user_info.user);
        
        // Is Approved For All ?
        isApproved = riskVault.isApprovedForAll(risk_user_info.real_user, risk_user_info.user);
        if(!isApproved){
            emit log_named_string("RISK Is Approved", "No");
        }
        else{
            emit log_named_string("RISK Is Approved", "Yes");
        }

        uint256 user_risk_vaultbalance = riskVault.balanceOf(risk_user_info.real_user, ID);
        emit log_named_uint(
            "Risk Real User 2 Vault Balance Before Withdraw ",
            user_risk_vaultbalance
        );

        riskVault.withdraw(ID, user_risk_vaultbalance, risk_user_info.user, risk_user_info.real_user);

        user_risk_vaultbalance = riskVault.balanceOf(risk_user_info.real_user, ID);
        emit log_named_uint(
            "Risk Real User 2 Vault Balance After Withdraw ",
            user_risk_vaultbalance
        );

        uint256 user_risk_balance = ERC20(assetWETH).balanceOf(risk_user_info.user);
        emit log_named_uint(
            "Bad Risk User 8 WETH Balance After Withdraw ",
            user_risk_balance
        );

        vm.stopPrank();

        uint256 risk_vaultBalance = ERC20(assetWETH).balanceOf(risk);
        emit log_named_uint(
            "Risk Vault WETH Balance After Withdraw",
            risk_vaultBalance
        );
    }

    function testFailWithdrawForSomeone() public{
        (uint256 ID, address insurance, address risk) = testDepegKeeper();
        Vault insrVault = Vault(insurance);
        Vault riskVault = Vault(risk);

        //INSURANCE WITHDRAW
        UserInfo memory insr_user_info = UserInfo(
            address(6),
            address(5),
            address(1)
        );

        //vm.prank(insr_user_info.real_user);
        //insrVault.setApprovalForAll(insr_user_info.user, true);

        vm.startPrank(insr_user_info.user);        

        // Is Approved For All ?
        bool isApproved = insrVault.isApprovedForAll(insr_user_info.real_user, insr_user_info.user);
        if(!isApproved){
            emit log_named_string("INSURANCE Is Approved", "No");
        }
        else{
            emit log_named_string("INSURANCE Is Approved", "Yes");
        }

        uint256 user_insr_vaultbalance = insrVault.balanceOf(
            insr_user_info.real_user,
            ID
        );
        emit log_named_uint(
            "Insurance Real User 1 Vault Balance Before Withdraw ",
            user_insr_vaultbalance
        );

        uint256 insr_finalTVL = insrVault.idFinalTVL(ID);
        emit log_named_uint("Insurance Final TVL", insr_finalTVL);

        uint256 insr_vaultBalance = ERC20(assetWETH).balanceOf(insurance);
        emit log_named_uint(
            "Before Insurance WETH Vault Balance ",
            insr_vaultBalance
        );

        uint256 entitledShares = insrVault.withdraw(
            ID,
            user_insr_vaultbalance,
            insr_user_info.user,
            insr_user_info.real_user
        );

        user_insr_vaultbalance = insrVault.balanceOf(insr_user_info.real_user, ID);
        emit log_named_uint(
            "Insurance Real User 1 Vault Balance After Withdraw",
            user_insr_vaultbalance
        );

        emit log_named_uint(
            "Insurance User Entitled Shares of Vault Withdraw",
            entitledShares
        );

        insr_vaultBalance = ERC20(assetWETH).balanceOf(insurance);
        emit log_named_uint(
            "After  Insurance WETH Vault Balance ",
            insr_vaultBalance
        );

        user_insr_vaultbalance = ERC20(assetWETH).balanceOf(insr_user_info.user);
        emit log_named_uint(
            "After Insurance Bad User 6 WETH Vault Balance ",
            user_insr_vaultbalance
        );

        vm.stopPrank();

        //RISK WITHDRAW
        UserInfo memory risk_user_info = UserInfo(
            address(8),
            address(7),
            address(2)
        );
        
        //vm.prank(risk_user_info.real_user);
        //riskVault.setApprovalForAll(risk_user_info.user, true);

        vm.startPrank(risk_user_info.user);
        
        // Is Approved For All ?
        isApproved = riskVault.isApprovedForAll(risk_user_info.real_user, risk_user_info.user);
        if(!isApproved){
            emit log_named_string("RISK Is Approved", "No");
        }
        else{
            emit log_named_string("RISK Is Approved", "Yes");
        }

        uint256 user_risk_vaultbalance = riskVault.balanceOf(risk_user_info.real_user, ID);
        emit log_named_uint(
            "Risk Real User 2 Vault Balance Before Withdraw ",
            user_risk_vaultbalance
        );

        riskVault.withdraw(ID, user_risk_vaultbalance, risk_user_info.user, risk_user_info.real_user);

        user_risk_vaultbalance = riskVault.balanceOf(risk_user_info.real_user, ID);
        emit log_named_uint(
            "Risk Real User 2 Vault Balance After Withdraw ",
            user_risk_vaultbalance
        );

        uint256 user_risk_balance = ERC20(assetWETH).balanceOf(risk_user_info.user);
        emit log_named_uint(
            "Bad Risk User 8 WETH Balance After Withdraw ",
            user_risk_balance
        );

        vm.stopPrank();

        uint256 risk_vaultBalance = ERC20(assetWETH).balanceOf(risk);
        emit log_named_uint(
            "Risk Vault WETH Balance After Withdraw",
            risk_vaultBalance
        );
    }
}
