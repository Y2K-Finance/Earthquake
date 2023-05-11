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
        // console2.log("Broadcast privateKey", privateKey);
        // vm.startBroadcast(privateKey);

        console2.log("Broadcast sender", msg.sender);
        

        policy = msg.sender;
        treasury  = msg.sender;


        console2.log("Broadcast policy", policy);
        console2.log("Broadcast treasury", treasury);

        vm.startBroadcast();   

        // address timeLock = address(new TimeLock(policy));

        CarouselFactory vaultFactory = CarouselFactory(0xC2F85bBe4FF1aB820cd9C056C19b54A521558c5d);

        ControllerPeggedAssetV2 controller = new ControllerPeggedAssetV2(address(vaultFactory), addresses.arbitrum_sequencer);

        console2.log("Broadcast controller", address(controller));

        vaultFactory.whitelistController(address(controller));

        vaultFactory.changeController(13432959644290212464144746086652692024951059320543618081087108994402299554162, address(controller));

        vaultFactory.changeController(111161626055803429424605937377234648176040888937634193811038123696245682044300, address(controller));

        vaultFactory.changeController(104539733070968503208825746187343215845456686552083697493706031226049768240009, address(controller));

        vaultFactory.changeController(110788007100077306759356690218326038626284721750366921456204435275195769181459, address(controller));

        // vaultFactory.changeController(marketId, address(controller));

        // vaultFactory.changeController(marketId, address(controller));

        // console.log("factory", address(vaultFactory));
        // console.log("controller", controller);


        // deployMarketsV2(address(vaultFactory));

        //  IERC20(emissionToken).approve(factory, 100 ether);

         
        // ( address prem, address collat, uint256 marketId) =  vaultFactory.createNewCarouselMarket(
        //     CarouselFactory.CarouselMarketConfigurationCalldata(
        //         addresses.tokenUSDC,
        //         980000000000000000,
        //         addresses.oracleUSDC,
        //         addresses.weth,
        //         "y2kUSDC_980*",
        //         "https://y2k.finance",
        //         address(controller),
        //         200000000000000, // 0.0002 Ether
        //         10, // 0.1%
        //         500000000000000000 // 0.5 Ether
        //     )
        // );

        // console2.log("CarouselFactory address", addresses.carouselFactoryV2);

        // IERC20(addresses.y2k).approve(addresses.carouselFactoryV2, 200 ether);

        //  CarouselFactory(factory).createEpochWithEmissions(
        //     marketId,
        //     block.timestamp + 1 days,
        //     block.timestamp + 2 days,
        //     50,
        //     1 ether,
        //     10 ether
        // );

        // console.log("eId", eId);

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