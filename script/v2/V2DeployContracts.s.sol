// SPDX-License-Identifier;
pragma solidity ^0.8.15;


import "forge-std/Script.sol";
import "forge-std/StdJson.sol";
import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../src/v2/VaultFactoryV2.sol";
import "../../src/v2/Controllers/ControllerPeggedAssetV2.sol";
import "../../src/v2/TimeLock.sol";

import "./V2Helper.sol";


//forge script V2DeploymentScript --rpc-url $ARBITRUM_RPC_URL --broadcast --verify -slow -vv

// forge verify-contract --chain-id 42161 --num-of-optimizations 1000000 --watch --constructor-args $(cast abi-encode "constructor(address,address,address,address,uint256)" 0xaC0D2cF77a8F8869069fc45821483701A264933B 0xaC0D2cF77a8F8869069fc45821483701A264933B 0x65c936f008BC34fE819bce9Fa5afD9dc2d49977f 0x447deddf312ad609e2f85fd23130acd6ba48e8b7 1668384000) --compiler-version v0.8.15+commit.e14f2714 0x69b614f03554c7e0da34645c65852cc55400d0f9 src/rewards/StakingRewards.sol:StakingRewards $arbiscanApiKey 

// forge script V2DeployContracts --rpc-url $ARBITRUM_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --skip-simulation --slow -vvvv 
contract V2DeployContracts is Script, HelperV2 {
    using stdJson for string;

    address policy = 0xCCA23C05a9Cf7e78830F3fd55b1e8CfCCbc5E50F;
    address weth = 0x6BE37a65E46048B1D12C0E08d9722402A5247Ff1;
    address treasury = 0xCCA23C05a9Cf7e78830F3fd55b1e8CfCCbc5E50F;
    address emissionToken = 0x5D59e5837F7e5d0F710178Eda34d9eCF069B36D2;

    function run() public {
        
        ConfigAddressesV2 memory addresses = getConfigAddresses(true);
        // console2.log("Address admin", addresses.admin);
        // console2.log("Address arbitrum_sequencer", addresses.arbitrum_sequencer);
        // console2.log("\n");

        
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        require(privateKey != 0, "PRIVATE_KEY is not set");
        // console2.log("Broadcast privateKey", privateKey);
        // vm.startBroadcast(privateKey);

        console2.log("Broadcast sender", msg.sender);
        

        policy = msg.sender;
        treasury  = msg.sender;


        console2.log("Broadcast policy", policy);
        console2.log("Broadcast treasury", treasury);

        vm.startBroadcast();   

        // address timeLock = address(new TimeLock(policy));

        CarouselFactory vaultFactory = CarouselFactory(addresses.carouselFactory);

        // ControllerPeggedAssetV2 controller = new ControllerPeggedAssetV2(address(vaultFactory), addresses.arbitrum_sequencer);
        ControllerPeggedAssetV2 controller = ControllerPeggedAssetV2(0x68620dD41351Ff8d31702CE9B77d04805179eCe1);

        // vaultFactory.whitelistController(address(controller), true);

        vaultFactory.changeController(12447459829889661654709778517204204639729615077731522221602069492157540324035, address(controller));

        // console.log("factory", address(vaultFactory));
        // console.log("controller", controller);

        // KeeperV2 resolveKeeper = new KeeperV2(payable(addresses.gelatoOpsV2), payable(addresses.gelatoTaskTreasury), address(controller));
        // KeeperV2Rollover rolloverKeeper = new KeeperV2Rollover(payable(addresses.gelatoOpsV2), payable(addresses.gelatoTaskTreasury), addresses.carouselFactory);

        // console2.log("resolveKeeper address", address(resolveKeeper));
        // console2.log("rolloverKeeper address", address(rolloverKeeper));
                        
        // console2.log("Controller address", address(controller));
        // console2.log("Vault Factory address", address(vaultFactory));
        // console2.log("Rewards Factory address", address(rewardsFactory));
        // console2.log("Y2K token address", addresses.y2k);
  
        // console2.log("\n");
        
        //transfer ownership
        //vaultFactory.transferOwnership(addresses.admin);
        vm.stopBroadcast();

    }
}