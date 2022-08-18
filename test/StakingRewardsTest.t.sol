// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "forge-std/Test.sol";
import {Vault} from "../src/Vault.sol";
import {VaultFactory} from "../src/VaultFactory.sol";
import {Controller} from "../src/Controller.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";

import {IWETH} from "./interfaces/IWETH.sol";
import {GovToken} from "./GovToken.sol";
import {StakingRewards} from "../src/rewards/StakingRewards.sol";

contract StakingRewardsTest is Test {
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

    function createStakingRewards(
        address _owner,
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken,
        uint256 _id
    ) public returns (StakingRewards stake) {
        StakingRewards stakeRewards = new StakingRewards(
            _owner,
            _rewardsDistribution,
            _rewardsToken,
            _stakingToken,
            _id
        );

        GovToken(address(govToken)).moneyPrinterGoesBrr(address(stakeRewards));
        vm.prank(address(1));
        stakeRewards.notifyRewardAmount(100 ether);
        uint256 govBalance = govToken.balanceOf(address(stakeRewards));
        emit log_named_uint("GovToken Stake Rewards Balance", govBalance);

        return stakeRewards;
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
        vm.deal(user, amount);
        // swap to weth
        IWETH(assetWETH).deposit{value: amount}();

        ERC20(assetWETH).approve(insurance, amount);
        Vault(insurance).deposit(ID, amount, user);

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
        vm.deal(user, amount);
        // swap to weth
        IWETH(assetWETH).deposit{value: amount}();

        ERC20(assetWETH).approve(risk, amount);
        Vault(risk).deposit(ID, amount, user);

        vm.stopPrank();
    }

    function MultipleUsersDepositsUSDC()
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
            "Y2K_USDC_1.20$"
        );
        DepositInsurance(address(2), 10 ether, epochEnd, insr);
        DepositRisk(address(3), 20 ether, epochEnd, risk);

        DepositInsurance(address(4), 33 ether, epochEnd, insr);
        DepositRisk(address(5), 7 ether, epochEnd, risk);

        DepositInsurance(address(6), 123 ether, epochEnd, insr);
        DepositRisk(address(7), 301 ether, epochEnd, risk);

        return (epochEnd, insr, risk);
    }

    function DepegKeeper(uint256 ID, address risk) public {
        vm.warp(ID - 20 days);

        uint256 index = 1; //vaultFactory.marketIndex();

        uint256 risk_vaultBalance = ERC20(assetWETH).balanceOf(risk);
        controller.triggerDepeg(index, ID);

        risk_vaultBalance = ERC20(assetWETH).balanceOf(risk);
    }

    function WithdrawInsurance(
        uint256 ID,
        address user,
        address _vault
    ) public {
        vm.startPrank(user);
        Vault vault = Vault(_vault);

        uint256 user_vaultbalance = vault.balanceOf(user, ID);

        vault.withdraw(ID, user_vaultbalance, user, user);
        user_vaultbalance = vault.balanceOf(user, ID);

        user_vaultbalance = ERC20(assetWETH).balanceOf(user);

        vm.stopPrank();
    }

    function WithdrawRisk(
        uint256 ID,
        address user,
        address _vault
    ) public {
        vm.startPrank(user);
        Vault vault = Vault(_vault);

        uint256 user_vaultbalance = vault.balanceOf(user, ID);

        vault.withdraw(ID, user_vaultbalance, user, user);
        user_vaultbalance = vault.balanceOf(user, ID);

        user_vaultbalance = ERC20(assetWETH).balanceOf(user);

        vm.stopPrank();
    }

    function WithdrawMultipleUsersUSDC() public {
        (uint256 ID, address insr, address risk) = MultipleUsersDepositsUSDC();
        DepegKeeper(ID, risk);
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

    function testDepositRewards()
        public
        returns (StakingRewards stakeInsr, StakingRewards stakeRsk)
    {
        (uint256 ID, address insr, address risk) = MultipleUsersDepositsUSDC();

        StakingRewards stakeInsurance = createStakingRewards(
            address(1),
            address(1),
            address(govToken),
            insr,
            ID
        );

        StakingRewards stakeRisk = createStakingRewards(
            address(1),
            address(1),
            address(govToken),
            risk,
            ID
        );

        address user = address(2);
        vm.startPrank(user);
        Vault vaultInsurance = Vault(insr);
        vaultInsurance.setApprovalForAll(address(stakeInsurance), true);
        stakeInsurance.stake(vaultInsurance.balanceOf(user, ID));
        uint256 stakeBalance = stakeInsurance.balanceOf(user);
        emit log_named_uint("Insurance Staking", stakeBalance);
        vm.stopPrank();

        user = address(3);
        vm.startPrank(user);
        Vault vaultRisk = Vault(risk);
        vaultRisk.setApprovalForAll(address(stakeRisk), true);
        stakeRisk.stake(vaultRisk.balanceOf(user, ID));
        stakeBalance = stakeRisk.balanceOf(user);
        emit log_named_uint("Risk Staking", stakeBalance);
        vm.stopPrank();

        return (stakeInsurance, stakeRisk);
    }

    function testWithdrawRewards() public {
        (
            StakingRewards stakeInsurance,
            StakingRewards stakeRisk
        ) = testDepositRewards();

        vm.warp(block.timestamp + 8 days);

        address user = address(2);
        emit log_named_address("User", user);
        vm.startPrank(user);
        uint256 stakeBalance = stakeInsurance.balanceOf(user);
        emit log_named_uint("Insurance Staking", stakeBalance);
        stakeInsurance.exit();
        uint256 govBalance = govToken.balanceOf(user);
        emit log_named_uint("GovToken Balance", govBalance);
        /*
        uint256 govEarned = stakeInsurance.earned(user);
        emit log_named_uint("Earned Gov Rewards", govEarned);
        emit log_named_uint(
            "Rewards Per Token",
            stakeInsurance.rewardPerToken()
        );
        emit log_named_uint(
            "User Reward Per Token Paid",
            stakeInsurance.userRewardPerTokenPaid(user)
        );
        emit log_named_uint("Rewards on User", stakeInsurance.rewards(user));
        */
        vm.stopPrank();

        user = address(3);
        vm.startPrank(user);
        emit log_named_address("User", user);
        stakeRisk.exit();
        govBalance = govToken.balanceOf(user);
        emit log_named_uint("GovToken Balance", govBalance);
        vm.stopPrank();
    }
}
