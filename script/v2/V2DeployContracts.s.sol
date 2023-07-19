// SPDX-License-Identifier;
pragma solidity ^0.8.15;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";
import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../src/v2/VaultFactoryV2.sol";
import "../../src/v2/Controllers/ControllerPeggedAssetV2.sol";
import "../../src/v2/Controllers/ControllerGeneric.sol";
import "../../src/v2/oracles/ChainlinkPriceProvider.sol";
import "../../src/v2/oracles/RedstonePriceProvider.sol";
import "../../src/v2/oracles/DIAPriceProvider.sol";
import "../../src/v2/oracles/CVIPriceProvider.sol";
import "../../src/v2/oracles/GdaiPriceProvider.sol";
import "../../src/v2/TimeLock.sol";
import "./V2Helper.sol";
import {
    KeeperV2GenericController
} from "../keepers/KeeperV2GenericController.sol";

//forge script V2DeploymentScript --rpc-url $ARBITRUM_RPC_URL --broadcast --verify -slow -vv

// forge verify-contract --chain-id 42161 --num-of-optimizations 1000000 --watch --constructor-args $(cast abi-encode "constructor(address,address,address,address,uint256)" 0xaC0D2cF77a8F8869069fc45821483701A264933B 0xaC0D2cF77a8F8869069fc45821483701A264933B 0x65c936f008BC34fE819bce9Fa5afD9dc2d49977f 0x447deddf312ad609e2f85fd23130acd6ba48e8b7 1668384000) --compiler-version v0.8.15+commit.e14f2714 0x69b614f03554c7e0da34645c65852cc55400d0f9 src/rewards/StakingRewards.sol:StakingRewards $arbiscanApiKey

// forge script V2DeployContracts --rpc-url $ARBITRUM_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --skip-simulation --slow -vvvv
contract V2DeployContracts is Script, HelperV2 {
    using stdJson for string;

    function run() public {
        ConfigAddressesV2 memory addresses = getConfigAddresses(true);
        // address weth = addresses.weth;
        // address treasury = addresses.treasury;
        // address emissionToken = addresses.y2k;
        // address policy = addresses.policy;

        // console2.log("Address admin", addresses.admin);
        // console2.log(
        //     "Address arbitrum_sequencer",
        //     addresses.arbitrum_sequencer
        // );
        // console2.log("Address gelatoOpsV2", addresses.gelatoOpsV2);
        // console2.log(
        //     "Address gelatoTaskTreasury",
        //     addresses.gelatoTaskTreasury
        // );
        console2.log("\n");

        // uint256 privateKey = vm.envUint("PRIVATE_KEY");
        // require(privateKey != 0, "PRIVATE_KEY is not set");
        // console2.log("Broadcast privateKey", privateKey);
        // vm.startBroadcast(privateKey);

        // console2.log("Broadcast sender", msg.sender);
        // console2.log("Broadcast policy", policy);
        // console2.log("Broadcast treasury", treasury);

        vm.startBroadcast();

        // TimeLock timeLock = new TimeLock(policy);
        // factory.changeTimelocker(address(timeLock));

        // CarouselFactoryPausable deployedVaultFactory = new CarouselFactoryPausable(
        //     addresses.weth,
        //     addresses.treasury,
        //     msg.sender,
        //     addresses.y2k
        // );

        // ControllerPeggedAssetV2 controller = new ControllerPeggedAssetV2(
        //     address(vaultFactory),
        //     addresses.arbitrum_sequencer
        // );
        // ControllerPeggedAssetV2 controller = ControllerPeggedAssetV2(0x68620dD41351Ff8d31702CE9B77d04805179eCe1);

        // vaultFactory.whitelistController(address(controller));

        // ControllerGeneric controllerGeneric = new ControllerGeneric(
        //     addresses.carouselFactory,
        //     addresses.treasury);

        // ControllerGeneric controllerGeneric = new ControllerGeneric(
        //     address(deployedVaultFactory),
        //     addresses.treasury
        // );

        // deployedVaultFactory.whitelistController(address(controllerGeneric));
        // carouselFactory.whitelistController(address(controllerGeneric));

        // uint256 timeOut = 12 hours;
        // address arbitrumSequencer = 0xFdB631F5EE196F0ed6FAa767959853A9F217697D;
        // address btcFeed = 0x6ce185860a4963106506C203335A2910413708e9;
        // ChainlinkPriceProvider chainlinkPriceProvider = new ChainlinkPriceProvider(
        //         arbitrumSequencer,
        //         addresses.pausableCarouselFactory,
        //         0x6ce185860a4963106506C203335A2910413708e9,
        //         timeOut
        //     );

        // address vstPriceFeed = 0xd2F9EB49F563aAacE73eb1D19305dD5812F33179;
        // RedstonePriceProvider redstoneProvider = new RedstonePriceProvider(
        //     addresses.carouselFactory,
        //     vstPriceFeed,
        //     "VST",
        //     timeOut
        // );

        address gdaiVault = 0xd85E038593d7A098614721EaE955EC2022B9B91B;
        GdaiPriceProvider gdaiPriceProvider = new GdaiPriceProvider(gdaiVault);

        // address cviOracle = 0x649813B6dc6111D67484BaDeDd377D32e4505F85;
        // uint256 cviDecimals = 0;
        // CVIPriceProvider cviPriceProvider = new CVIPriceProvider(
        //     cviOracle,
        //     timeOut,
        //     cviDecimals
        // );

        // address diaOracleV2 = 0xd041478644048d9281f88558E6088e9da97df624;
        // DIAPriceProvider diaPriceProvider = new DIAPriceProvider(diaOracleV2);

        // vaultFactory.whitelistController(address(controller));
        // KeeperV2 resolveKeeper = new KeeperV2(
        //     payable(addresses.gelatoOpsV2),
        //     payable(addresses.gelatoTaskTreasury),
        //     address(controller)
        // );
        // KeeperV2GenericController(0x030754953308DC6782F7A04653929Fd25359ebCc).withdraw(3060778887280000);
        // KeeperV2GenericController resolveKeeperGenericController = new KeeperV2GenericController(
        //     payable(addresses.gelatoOpsV2),
        //     payable(addresses.gelatoTaskTreasury),
        //     address(controllerGeneric)
        // );
        // resolveKeeperGenericController.deposit{
        //     value: 50000000000000000
        // }(50000000000000000);
        // KeeperV2Rollover(0xd061b747fD59368B31BE377CD995BdeF023705A3).withdraw(1000000000000000);
        // KeeperV2Rollover rolloverKeeper = new KeeperV2Rollover(
        //     payable(addresses.gelatoOpsV2),
        //     payable(addresses.gelatoTaskTreasury),
        //     address(deployedVaultFactory)
        // );

        vm.stopBroadcast();

        // console2.log("TimeLock address", timeLock);
        // console2.log("Vault Factory address", address(deployedVaultFactory));
        // console2.log("Controller address", address(controller));
        // console2.log("Controller Generic address", address(controllerGeneric));

        // console2.log(
        //     "Chainlink Price Provider",
        //     address(chainlinkPriceProvider)
        // );
        // console2.log("Redstone Price Provider", address(redstoneProvider));
        console2.log("Gdai Price Provider", address(gdaiPriceProvider));
        // console2.log("CVI Price Provider", address(cviPriceProvider));
        // console2.log("Dia Price Provider", address(diaPriceProvider));

        // console2.log("resolveKeeper address", address(resolveKeeper));
        // console2.log("resolveKeeperGenericController address", address(resolveKeeperGenericController));
        // console2.log("rolloverKeeper address", address(rolloverKeeper));
        // console2.log("Y2K token address", addresses.y2k);

        console2.log("\n");
    }
}
