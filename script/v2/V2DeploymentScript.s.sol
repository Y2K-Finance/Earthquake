// SPDX-License-Identifier;
pragma solidity ^0.8.17;


import "forge-std/Script.sol";
import "forge-std/StdJson.sol";
import "forge-std/Test.sol";

import "../../src/v2/VaultFactoryV2.sol";
import "../../src/v2/Carousel/CarouselFactory.sol";
import "../../src/v2/TimeLock.sol";


//forge script V2DeploymentScript --rpc-url $ARBITRUM_RPC_URL --broadcast --verify -slow -vv

// forge verify-contract --chain-id 42161 --num-of-optimizations 1000000 --watch --constructor-args $(cast abi-encode "constructor(address,address,address,address,uint256)" 0xaC0D2cF77a8F8869069fc45821483701A264933B 0xaC0D2cF77a8F8869069fc45821483701A264933B 0x65c936f008BC34fE819bce9Fa5afD9dc2d49977f 0x447deddf312ad609e2f85fd23130acd6ba48e8b7 1668384000) --compiler-version v0.8.15+commit.e14f2714 0x69b614f03554c7e0da34645c65852cc55400d0f9 src/rewards/StakingRewards.sol:StakingRewards $arbiscanApiKey
contract V2DeploymentScript is Script {
    using stdJson for string;

    function run() public {


        // ConfigAddresses memory addresses = getConfigAddresses(false);
        // console2.log("Address admin", addresses.admin);
        // console2.log("Address arbitrum_sequencer", addresses.arbitrum_sequencer);
        // console2.log("Address oracleDAI", addresses.oracleDAI);
        // console2.log("Address oracleFEI", addresses.oracleFEI);
        // console2.log("Address oracleFRAX", addresses.oracleFRAX);
        // console2.log("Address oracleMIM", addresses.oracleMIM);
        // console2.log("Address oracleUSDC", addresses.oracleUSDC);
        // console2.log("Address oracleUSDT", addresses.oracleUSDT);
        // console2.log("Address policy", addresses.policy);
        // console2.log("Address tokenDAI", addresses.tokenDAI);
        // console2.log("Address tokenFEI", addresses.tokenFEI);
        // console2.log("Address tokenFRAX", addresses.tokenFRAX);
        // console2.log("Address tokenMIM", addresses.tokenMIM);
        // console2.log("Address tokenUSDC", addresses.tokenUSDC);
        // console2.log("Address tokenUSDT", addresses.tokenUSDT);
        // console2.log("Address treasury", addresses.treasury);
        // console2.log("Address weth", addresses.weth);
        // console2.log("\n");

        
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        require(privateKey != 0, "PRIVATE_KEY is not set");
        console2.log("Broadcast privateKey", privateKey);
        vm.startBroadcast(privateKey);

        console2.log("Broadcast sender", msg.sender);

        address policy = 0xaC0D2cF77a8F8869069fc45821483701A264933B;
        address weth = 0xaC0D2cF77a8F8869069fc45821483701A264933B;
        address treasury = 0x65c936f008BC34fE819bce9Fa5afD9dc2d49977f;
        address emissionToken = 0xaC0D2cF77a8F8869069fc45821483701A264933B;


        address timeLock = address(new TimeLock(policy));

        // CarouselFactory vaultFactory = new CarouselFactory(policy, weth, treasury, emissionToken);

        VaultFactoryV2 vaultFactory = new VaultFactoryV2(weth, treasury, timeLock);
        // console2.log("Broadcast admin ", addresses.admin);
        // console2.log("Broadcast policy", addresses.policy);
        //start setUp();

        // vaultFactory = new VaultFactory(addresses.treasury, addresses.weth, addresses.policy);
        // controller = new Controller(address(vaultFactory), addresses.arbitrum_sequencer);

        // vaultFactory.setController(address(controller));


        //stop setUp();
                        
        // console2.log("Controller address", address(controller));
        // console2.log("Vault Factory address", address(vaultFactory));
        // console2.log("Rewards Factory address", address(rewardsFactory));
        // console2.log("Y2K token address", addresses.y2k);
        // console2.log("KeeperGelatoDepeg address", address(keeperDepeg));
        // console2.log("KeeperGelatoEndEpoch address", address(keeperEndEpoch));
        // console2.log("\n");
        
        //transfer ownership
        //vaultFactory.transferOwnership(addresses.admin);
        vm.stopBroadcast();

    }
}