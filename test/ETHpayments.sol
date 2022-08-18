// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "forge-std/Test.sol";
import {Vault} from "../src/Vault.sol";
import {VaultFactory} from "../src/VaultFactory.sol";
import {Controller} from "../src/Controller.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";

import {IWETH} from "./interfaces/IWETH.sol";
import {GovToken} from "./GovToken.sol";

contract Y2KETHTest is Test {
    address assetWETH = 0x207eD1742cc0BeBD03E50e855d3a14E41f93A461;
    address public constant treasury =
        0xEAE1f7b21B7f6c711C441d85eE5ab53E4A626D65;
    address public constant DAI = 0x4dCf5ac4509888714dd43A5cCc46d7ab389D9c23;
    address public constant DAI_oracle =
        0x3e3546c6b5689f7EAa1BA7Bc9571322c3168D786;
    address public constant USDC = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;
    address public constant USDC_oracle =
        0x103a2d37Ea6b3b4dA2F5bb44E001001729E74354;
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

    function CreationNewVaults(
        uint256 fee,
        uint256 withdrawalFee,
        address token,
        int256 strikePrice,
        uint256 epochBegin,
        uint256 epochEnd,
        address token_oracle,
        string memory _name
    ) public returns (address insr, address risk) {
        //uint256 fee = 5;
        //int256 strikePrice = 120000000; //1$ = 100000000
        //uint256 epochBegin = 1656597477;
        //uint256 epochEnd = 1659189477;
        return
            vaultFactory.createNewMarket(
                fee,
                withdrawalFee,
                token,
                strikePrice,
                epochBegin,
                epochEnd,
                token_oracle,
                _name
            );
    }

    function testCreateMoreUSDC() public {
        uint256 fee = 10;
        uint256 withdrawalFee = 50;
        int256 strikePrice = 120000000; //1$ = 100000000
        uint256 epochBegin = block.timestamp + 2 days;
        uint256 epochEnd = block.timestamp + 30 days;
        uint256 epochBegin2 = block.timestamp + 5 days; 
        uint256 epochEnd2 = block.timestamp + 35 days;
        CreationNewVaults(
            fee,
            withdrawalFee,
            USDC,
            strikePrice,
            epochBegin,
            epochEnd,
            USDC_oracle,
            "Y2K.USDC.1.20$"
        );
        vaultFactory.deployMoreAssets(
            vaultFactory.marketIndex(),
            epochBegin2,
            epochEnd2
        );
    }

    /*//////////////////////////////////////////////////////////////
                                Deposit TESTS
    //////////////////////////////////////////////////////////////*/

    function DepositInsurance(
        address user,
        uint256 amount,
        uint256 ID,
        address insurance
    ) public {
        //address user = address(1);
        //uint256 amount = 8225082557140;
        //uint256 ID = 1659189477;

        vm.startPrank(user);
        emit log_named_address("Insurance Deposit User : ", user);
        vm.deal(user, amount);

        uint256 balance = user.balance;
        emit log_named_uint("User Balance before Deposit ", balance);

        ERC20(assetWETH).approve(insurance, amount);
        Vault(insurance).depositETH{value: amount}(ID, user);

        uint256 vaultBalance = ERC20(assetWETH).balanceOf(insurance);
        emit log_named_uint("Vault Balance ", vaultBalance);

        uint256 newbalance =  user.balance;
        emit log_named_uint("User Balance after Deposit ", newbalance);

        uint256 user_vaultbalance = Vault(insurance).balanceOf(user, ID);
        emit log_named_uint("User Vault Balance ", user_vaultbalance);

        uint256 trzbalance = ERC20(assetWETH).balanceOf(treasury);
        emit log_named_uint("Treasury Balance ", trzbalance);

        vm.stopPrank();
    }

    function DepositRisk(
        address user,
        uint256 amount,
        uint256 ID,
        address risk
    ) public {
        //address user = address(2);
        //uint256 amount = 5 ether;
        //uint256 ID = 1659189477;

        vm.startPrank(user);
        emit log_named_address("Risk Deposit User : ", user);
        vm.deal(user, amount);

        uint256 balance = user.balance;
        emit log_named_uint("User Balance before deposit", balance);

        ERC20(assetWETH).approve(risk, amount);
        Vault(risk).depositETH{value: amount}(ID, user);

        uint256 vaultBalance = ERC20(assetWETH).balanceOf(risk);
        emit log_named_uint("Vault Balance ", vaultBalance);

        uint256 newbalance = user.balance;
        emit log_named_uint("User Balance after Deposit", newbalance);

        uint256 user_vaultbalance = Vault(risk).balanceOf(user, ID);
        emit log_named_uint("User Vault Balance ", user_vaultbalance);

        uint256 trzbalance = ERC20(assetWETH).balanceOf(treasury);
        emit log_named_uint("Treasury Balance ", trzbalance);

        vm.stopPrank();
    }

    function testDepositsUSDC() public {
        uint256 fee = 10;
        uint256 withdrawalFee = 50;
        int256 strikePrice = 120000000; //1$ = 100000000
        uint256 epochBegin = block.timestamp + 2 days;
        uint256 epochEnd = block.timestamp + 30 days;
        (address insr, address risk) = CreationNewVaults(
            fee,
            withdrawalFee,
            USDC,
            strikePrice,
            epochBegin,
            epochEnd,
            USDC_oracle,
            "Y2K.USDC.1.20$"
        );
        DepositInsurance(address(2), 10 ether, epochEnd, insr);
        DepositRisk(address(3), 20 ether, epochEnd, risk);
    }

    function testMultipleUsersDepositsUSDC()
        public
        returns (
            uint256 ID,
            address _insr,
            address _risk
        )
    {
        uint256 fee = 10;
        uint256 withdrawalFee = 50;
        int256 strikePrice = 120000000; //1$ = 100000000
        uint256 epochBegin = block.timestamp + 2 days;
        uint256 epochEnd = block.timestamp + 30 days;

        (address insr, address risk) = CreationNewVaults(
            fee,
            withdrawalFee,
            USDC,
            strikePrice,
            epochBegin,
            epochEnd,
            USDC_oracle,
            "Y2K.USDC.1.20$"
        );
        DepositInsurance(address(2), 10 ether, epochEnd, insr);
        DepositRisk(address(3), 20 ether, epochEnd, risk);

        DepositInsurance(address(4), 33 ether, epochEnd, insr);
        DepositRisk(address(5), 7 ether, epochEnd, risk);

        DepositInsurance(address(6), 123 ether, epochEnd, insr);
        DepositRisk(address(7), 301 ether, epochEnd, risk);

        return (epochEnd, insr, risk);
    }

    function testMultipleUsersDepositsUSDC_NoDepeg()
        public
        returns (
            uint256 ID,
            address _insr,
            address _risk
        )
    {
        uint256 fee = 10;
        uint256 withdrawalFee = 50;
        int256 strikePrice = 99000000; //1$ = 100000000
        uint256 epochBegin = block.timestamp + 2 days;
        uint256 epochEnd = block.timestamp + 30 days;

        (address insr, address risk) = CreationNewVaults(
            fee,
            withdrawalFee,
            USDC,
            strikePrice,
            epochBegin,
            epochEnd,
            USDC_oracle,
            "Y2K.USDC.1.20$"
        );
        DepositInsurance(address(2), 10 ether, epochEnd, insr);
        DepositRisk(address(3), 20 ether, epochEnd, risk);

        DepositInsurance(address(4), 33 ether, epochEnd, insr);
        DepositRisk(address(5), 7 ether, epochEnd, risk);

        DepositInsurance(address(6), 123 ether, epochEnd, insr);
        DepositRisk(address(7), 301 ether, epochEnd, risk);

        return (epochEnd, insr, risk);
    }

    function testMultipleEpochsDepositsUSDC() public {
        uint256 epochEnd = block.timestamp + 30 days;
        uint256 epochEnd2 = block.timestamp + 35 days; 

        testCreateMoreUSDC();
        address[] memory vaultings = vaultFactory.getVaults(
            vaultFactory.marketIndex()
        );

        DepositInsurance(address(2), 10 ether, epochEnd, vaultings[0]);
        DepositRisk(address(3), 20 ether, epochEnd, vaultings[1]);

        DepositInsurance(address(4), 50 ether, epochEnd2, vaultings[0]);
        DepositRisk(address(3), 100 ether, epochEnd2, vaultings[1]);
    }

    /*//////////////////////////////////////////////////////////////
                                Keeper TESTS
    //////////////////////////////////////////////////////////////*/

    function DepegKeeper(
        uint256 ID,
        address insurance,
        address risk
    ) public {
        vm.warp(ID - 20 days);

        uint256 index = 1; //vaultFactory.marketIndex();

        Vault insrVault = Vault(insurance);
        Vault riskVault = Vault(risk);

        int256 priceNow = controller.getLatestPrice(insrVault.tokenInsured());
        int256 strikePrice = insrVault.strikePrice();
        emit log_named_int("Strike Price ", strikePrice);
        emit log_named_int("Latest Price ", priceNow);

        uint256 vaultBalance = ERC20(assetWETH).balanceOf(insurance);
        emit log_named_uint("Before Insurance Vault Balance ", vaultBalance);

        uint256 risk_vaultBalance = ERC20(assetWETH).balanceOf(risk);
        emit log_named_uint("Before Risk Vault Balance ", risk_vaultBalance);
        controller.triggerDepeg(index, ID);

        vaultBalance = ERC20(assetWETH).balanceOf(insurance);
        emit log_named_uint("After Insurance Vault Balance ", vaultBalance);

        risk_vaultBalance = ERC20(assetWETH).balanceOf(risk);
        emit log_named_uint("After Risk Vault Balance ", risk_vaultBalance);

        emit log_named_uint("Insurance Claim TVL", insrVault.idClaimTVL(ID));
        emit log_named_uint("Risk Claim TVL", riskVault.idClaimTVL(ID));
    }

    function NODepegKeeper(
        uint256 ID,
        address insurance,
        address risk
    ) public {
        vm.warp(ID);

        uint256 index = 1; //vaultFactory.marketIndex();

        Vault insrVault = Vault(insurance);
        Vault riskVault = Vault(risk);

        int256 priceNow = controller.getLatestPrice(insrVault.tokenInsured());
        int256 strikePrice = insrVault.strikePrice();
        emit log_named_int("Strike Price ", strikePrice);
        emit log_named_int("Latest Price ", priceNow);

        uint256 vaultBalance = ERC20(assetWETH).balanceOf(insurance);
        emit log_named_uint("Before Insurance Vault Balance ", vaultBalance);

        uint256 risk_vaultBalance = ERC20(assetWETH).balanceOf(risk);
        emit log_named_uint("Before Risk Vault Balance ", risk_vaultBalance);
        controller.triggerEndEpoch(index, ID);

        vaultBalance = ERC20(assetWETH).balanceOf(insurance);
        emit log_named_uint("After Insurance Vault Balance ", vaultBalance);

        risk_vaultBalance = ERC20(assetWETH).balanceOf(risk);
        emit log_named_uint("After Risk Vault Balance ", risk_vaultBalance);

        emit log_named_uint("Insurance Claim TVL", insrVault.idClaimTVL(ID));
        emit log_named_uint("Risk Claim TVL", riskVault.idClaimTVL(ID));
    }

    /*//////////////////////////////////////////////////////////////
                                Withdraw TESTS
    //////////////////////////////////////////////////////////////*/

    function WithdrawInsurance(
        uint256 ID,
        address user,
        address _vault
    ) public {
        vm.startPrank(user);
        Vault vault = Vault(_vault);

        emit log_named_address("Insurance Withdraw User : ", user);

        uint256 user_vaultbalance = vault.balanceOf(user, ID);
        emit log_named_uint(
            "Insurance User Vault Balance Before Withdraw ",
            user_vaultbalance
        );

        uint256 finalTVL = vault.idFinalTVL(ID);
        emit log_named_uint("Insurance Final TVL", finalTVL);

        uint256 entitledShares = vault.withdraw(
            ID,
            user_vaultbalance,
            user,
            user
        );
        user_vaultbalance = vault.balanceOf(user, ID);
        emit log_named_uint(
            "Insurance User Vault Balance After Withdraw",
            user_vaultbalance
        );

        emit log_named_uint(
            "Insurance User Entitled Shares of Vault Withdraw",
            entitledShares
        );

        uint256 vaultBalance = ERC20(assetWETH).balanceOf(_vault);
        emit log_named_uint(
            "After  Insurance WETH Vault Balance ",
            vaultBalance
        );

        user_vaultbalance = user.balance;
        emit log_named_uint(
            "After Insurance Receiver WETH Vault Balance ",
            user_vaultbalance
        );

        vm.stopPrank();
    }

    function WithdrawRisk(
        uint256 ID,
        address user,
        address _vault
    ) public {
        vm.startPrank(user);
        Vault vault = Vault(_vault);

        emit log_named_address("Risk Withdraw User : ", user);

        uint256 user_vaultbalance = vault.balanceOf(user, ID);
        emit log_named_uint(
            "Risk User Vault Balance Before Withdraw ",
            user_vaultbalance
        );

        uint256 finalTVL = vault.idFinalTVL(ID);
        emit log_named_uint("Risk Final TVL", finalTVL);

        uint256 entitledShares = vault.withdraw(
            ID,
            user_vaultbalance,
            user,
            user
        );
        user_vaultbalance = vault.balanceOf(user, ID);
        emit log_named_uint(
            "Risk User Vault Balance After Withdraw",
            user_vaultbalance
        );

        emit log_named_uint(
            "Risk User Entitled Shares of Vault Withdraw",
            entitledShares
        );

        uint256 vaultBalance = ERC20(assetWETH).balanceOf(_vault);
        emit log_named_uint("After  Risk WETH Vault Balance ", vaultBalance);

        user_vaultbalance = user.balance;
        emit log_named_uint(
            "After Risk Receiver WETH Vault Balance ",
            user_vaultbalance
        );

        vm.stopPrank();
    }

    function testWithdrawMultipleUsersUSDC() public {
        (
            uint256 ID,
            address insr,
            address risk
        ) = testMultipleUsersDepositsUSDC();
        DepegKeeper(ID, insr, risk);
        /*
        DepositInsurance(address(2), 10 ether, epochEnd, insr);
        DepositRisk(address(3), 20 ether, epochEnd, risk);

        DepositInsurance(address(4), 33 ether, epochEnd, insr);
        DepositRisk(address(5), 7 ether, epochEnd, risk);

        DepositInsurance(address(6), 123 ether, epochEnd, insr);
        DepositRisk(address(7), 301 ether, epochEnd, risk);
        */

        WithdrawInsurance(ID, address(2), insr);
        WithdrawInsurance(ID, address(4), insr);
        WithdrawInsurance(ID, address(6), insr);

        WithdrawRisk(ID, address(3), risk);
        WithdrawRisk(ID, address(5), risk);
        WithdrawRisk(ID, address(7), risk);
    }

    function testWithdrawMultipleUsersUSDCNODepeg() public {
        (
            uint256 ID,
            address insr,
            address risk
        ) = testMultipleUsersDepositsUSDC_NoDepeg();
        NODepegKeeper(ID, insr, risk);
        /*
        DepositInsurance(address(2), 10 ether, epochEnd, insr);
        DepositRisk(address(3), 20 ether, epochEnd, risk);

        DepositInsurance(address(4), 33 ether, epochEnd, insr);
        DepositRisk(address(5), 7 ether, epochEnd, risk);

        DepositInsurance(address(6), 123 ether, epochEnd, insr);
        DepositRisk(address(7), 301 ether, epochEnd, risk);
        */

        WithdrawInsurance(ID, address(2), insr);
        WithdrawInsurance(ID, address(4), insr);
        WithdrawInsurance(ID, address(6), insr);

        WithdrawRisk(ID, address(3), risk);
        WithdrawRisk(ID, address(5), risk);
        WithdrawRisk(ID, address(7), risk);
    }
}
