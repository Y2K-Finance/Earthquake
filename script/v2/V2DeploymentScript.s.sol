// SPDX-License-Identifier;
pragma solidity ^0.8.17;


import "forge-std/Script.sol";
import "forge-std/StdJson.sol";
import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../src/v2/VaultFactoryV2.sol";
import "../../src/v2/Carousel/CarouselFactory.sol";
import "../../src/v2/Controllers/ControllerPeggedAssetV2.sol";
import "../../src/v2/TimeLock.sol";

import "./Helper.sol";




//forge script V2DeploymentScript --rpc-url $ARBITRUM_RPC_URL --broadcast --verify -slow -vv

// forge verify-contract --chain-id 42161 --num-of-optimizations 1000000 --watch --constructor-args $(cast abi-encode "constructor(address,address,address,address,uint256)" 0xaC0D2cF77a8F8869069fc45821483701A264933B 0xaC0D2cF77a8F8869069fc45821483701A264933B 0x65c936f008BC34fE819bce9Fa5afD9dc2d49977f 0x447deddf312ad609e2f85fd23130acd6ba48e8b7 1668384000) --compiler-version v0.8.15+commit.e14f2714 0x69b614f03554c7e0da34645c65852cc55400d0f9 src/rewards/StakingRewards.sol:StakingRewards $arbiscanApiKey 

// forge script script/v2/V2DeploymentScript.s.sol --rpc-url $ARBITRUM_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --skip-simulation --slow -vvvv 
contract V2DeploymentScript is Script, HelperV2 {
    using stdJson for string;

    address policy = 0xCCA23C05a9Cf7e78830F3fd55b1e8CfCCbc5E50F;
    address weth = 0x6BE37a65E46048B1D12C0E08d9722402A5247Ff1;
    address treasury = 0xCCA23C05a9Cf7e78830F3fd55b1e8CfCCbc5E50F;
    address emissionToken = 0x5D59e5837F7e5d0F710178Eda34d9eCF069B36D2;
    address factory;

    address controller;
    function run() public {
        
        ConfigAddresses memory addresses = getConfigAddresses(false);
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
        

        policy = msg.sender;
        treasury  = msg.sender;


        console2.log("Broadcast policy", policy);
        console2.log("Broadcast treasury", treasury);


        // address timeLock = address(new TimeLock(policy));

        // CarouselFactory vaultFactory = new CarouselFactory(weth, treasury, policy, emissionToken);
        factory = 0xAd2f15ff7d167c800281ef52fa098Fae33429cc6;

        controller = 0xDf878548b17429a6e6a3ff66Fb629e347738aA56;

        // VaultFactoryV2 vaultFactory = new VaultFactoryV2(weth, treasury, timeLock);
        // console2.log("Broadcast admin ", addresses.admin);
        // console2.log("Broadcast policy", addresses.policy);
        //start setUp();

        // vaultFactory = new VaultFactory(addresses.treasury, addresses.weth, addresses.policy);
        // controller = address(new ControllerPeggedAssetV2(address(vaultFactory), addresses.arbitrum_sequencer, treasury));

        // vaultFactory.whitelistController(controller);

        console.log("factory", factory);
        console.log("controller", controller);


        // deployMarketsV2(address(vaultFactory));

        //  IERC20(emissionToken).approve(factory, 100 ether);

         
        // ( address prem, address collat, uint256 marketId) =  CarouselFactory(factory).createNewCarouselMarket(
        //     CarouselFactory.CarouselMarketConfigurationCalldata(
        //         addresses.tokenMIM,
        //         999000000000000000,
        //         addresses.oracleMIM,
        //         weth,
        //         "y2kMIM_999*",
        //         "https://y2k.finance",
        //         controller,
        //         1 gwei,
        //         10,
        //         1 ether
        //     )
        // );

        // console.log("Prem", prem);
        // console.log("Collat", collat);
        // console.log("marketId", marketId);


        (uint256 eId, ) = CarouselFactory(factory).createEpochWithEmissions(
            50136727949622076191748106171773774901339026601219072444023567158965921292263,
            1682575989,
            1682748789,
            50,
            1 ether,
            2 ether
        );

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

    function deployMarketsV2( address factory) public {

        ConfigAddresses memory addresses = getConfigAddresses(false);


        IERC20(emissionToken).approve(address(factory), 200 ether);
        
        ( address prem, address collat, uint256 marketId) =  CarouselFactory(factory).createNewCarouselMarket(
            CarouselFactory.CarouselMarketConfigurationCalldata(
                addresses.tokenUSDC,
                1 ether - 1,
                addresses.oracleUSDC,
                weth,
                "y2kUSDC_999*",
                "https://y2k.finance",
                address(controller),
                1 gwei,
                10,
                1 ether
            )
        );

         CarouselFactory(factory).createEpochWithEmissions(
            marketId,
            1683891705,
            1689162105,
            50,
            1 ether,
            10 ether
        );
        
        // CarouselFactory(factory).createEpochWithEmissions(
        //     marketId,
        //     1689419676,
        //     1689506076,
        //     50,
        //     1 ether,
        //     10 ether
        // );

        //  CarouselFactory(factory).createEpochWithEmissions(
        //     marketId,
        //     1689592476,
        //     1689678876,
        //     50,
        //     1 ether,
        //     10 ether
        // );

        (  prem,  collat, marketId) =  CarouselFactory(factory).createNewCarouselMarket(
            CarouselFactory.CarouselMarketConfigurationCalldata(
                addresses.tokenUSDT,
                1 ether - 1,
                addresses.oracleUSDT,
                weth,
                "y2kUSDT_999*",
                "https://y2k.finance",
                address(controller),
                1 gwei,
                10,
                1 ether
            )
        );

        // CarouselFactory(factory).createEpochWithEmissions(
        //     marketId,
        //     1683891705,
        //     1689162105,
        //     50,
        //     1 ether,
        //     10 ether
        // );

         CarouselFactory(factory).createEpochWithEmissions(
            marketId,
            1689419676,
            1689506076,
            50,
            1 ether,
            10 ether
        );

        //  CarouselFactory(factory).createEpochWithEmissions(
        //     marketId,
        //     1689592476,
        //     1689678876,
        //     50,
        //     1 ether,
        //     10 ether
        // );

         (  prem,  collat, marketId) =  CarouselFactory(factory).createNewCarouselMarket(
            CarouselFactory.CarouselMarketConfigurationCalldata(
                addresses.tokenDAI,
                1 ether - 1,
                addresses.oracleDAI,
                weth,
                "y2kDAI_999*",
                "https://y2k.finance",
                address(controller),
                1 gwei,
                10,
                1 ether
            )
        );

        // CarouselFactory(factory).createEpochWithEmissions(
        //     marketId,
        //     1683891705,
        //     1689162105,
        //     50,
        //     1 ether,
        //     10 ether
        // );

        // CarouselFactory(factory).createEpochWithEmissions(
        //     marketId,
        //     1689419676,
        //     1689506076,
        //     50,
        //     1 ether,
        //     10 ether
        // );

         CarouselFactory(factory).createEpochWithEmissions(
            marketId,
            1689592476,
            1689678876,
            50,
            1 ether,
            10 ether
        );


    }

    function deployEpoch( address factory) public {
         
    }
}