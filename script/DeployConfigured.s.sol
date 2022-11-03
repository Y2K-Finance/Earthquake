// SPDX-License-Identifier;
pragma solidity ^0.8.13;

import "./Helper.sol";

/// @author MiguelBits

//forge script ConfigScript --rpc-url $ARBITRUM_RPC_URL --private-key $PRIVATE_KEY --broadcast --etherscan-api-key $arbiscanApiKey --verify --skip-simulation --gas-estimate-multiplier 200 --slow -vv

// forge verify-contract --chain-id 42161 --num-of-optimizations 1000000 --watch --constructor-args $(cast abi-encode "constructor(address,address,address,address,uint256)" 0xaC0D2cF77a8F8869069fc45821483701A264933B 0xaC0D2cF77a8F8869069fc45821483701A264933B 0x65c936f008BC34fE819bce9Fa5afD9dc2d49977f 0x447deddf312ad609e2f85fd23130acd6ba48e8b7 1668384000) --compiler-version v0.8.15+commit.e14f2714 0x69b614f03554c7e0da34645c65852cc55400d0f9 src/rewards/StakingRewards.sol:StakingRewards $arbiscanApiKey
contract ConfigScript is Script, HelperConfig {
    using stdJson for string;

    function run() public {

        ConfigAddresses memory addresses = getConfigAddresses();
        console2.log("Address admin", addresses.admin);
        console2.log("Address arbitrum_sequencer", addresses.arbitrum_sequencer);
        console2.log("Address oracleDAI", addresses.oracleDAI);
        console2.log("Address oracleFEI", addresses.oracleFEI);
        console2.log("Address oracleFRAX", addresses.oracleFRAX);
        console2.log("Address oracleMIM", addresses.oracleMIM);
        console2.log("Address oracleUSDC", addresses.oracleUSDC);
        console2.log("Address oracleUSDT", addresses.oracleUSDT);
        console2.log("Address policy", addresses.policy);
        console2.log("Address tokenDAI", addresses.tokenDAI);
        console2.log("Address tokenFEI", addresses.tokenFEI);
        console2.log("Address tokenFRAX", addresses.tokenFRAX);
        console2.log("Address tokenMIM", addresses.tokenMIM);
        console2.log("Address tokenUSDC", addresses.tokenUSDC);
        console2.log("Address tokenUSDT", addresses.tokenUSDT);
        console2.log("Address treasury", addresses.treasury);
        console2.log("Address weth", addresses.weth);
        console2.log("\n");

        vm.startBroadcast();

        console2.log("Broadcast sender", msg.sender);
        console2.log("Broadcast admin ", addresses.admin);
        console2.log("Broadcast policy", addresses.policy);
        //start setUp();

        vaultFactory = new VaultFactory(addresses.treasury, addresses.weth, addresses.policy);
        controller = new Controller(address(vaultFactory), addresses.arbitrum_sequencer);

        vaultFactory.setController(address(controller));

        rewardsFactory = new RewardsFactory(addresses.y2k, address(vaultFactory));
        keeperDepeg = new KeeperGelatoDepeg(payable(addresses.gelatoOpsV2), payable(addresses.gelatoTaskTreasury), address(controller));
        keeperEndEpoch = new KeeperGelatoEndEpoch(payable(addresses.gelatoOpsV2), payable(addresses.gelatoTaskTreasury), address(controller));
        //stop setUp();
                        
        console2.log("Controller address", address(controller));
        console2.log("Vault Factory address", address(vaultFactory));
        console2.log("Rewards Factory address", address(rewardsFactory));
        console2.log("Y2K token address", addresses.y2k);
        console2.log("KeeperGelatoDepeg address", address(keeperDepeg));
        console2.log("KeeperGelatoEndEpoch address", address(keeperEndEpoch));
        console2.log("\n");
        
        //transfer ownership
        //vaultFactory.transferOwnership(addresses.admin);

    }
}