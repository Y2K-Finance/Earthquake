// SPDX-License-Identifier;
pragma solidity ^0.8.15;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";
import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../src/v2/VaultFactoryV2.sol";
import "../../src/v2/Controllers/ControllerPeggedAssetV2.sol";
import "../../src/v2/Controllers/ControllerGeneric.sol";
import "../../src/v2/oracles/individual/ChainlinkPriceProvider.sol";
import "../../src/v2/oracles/individual/RedstonePriceProvider.sol";
import "../../src/v2/oracles/individual/DIAPriceProvider.sol";
import "../../src/v2/oracles/individual/CVIPriceProvider.sol";
import "../../src/v2/oracles/individual/GdaiPriceProvider.sol";
import "../../src/v2/oracles/individual/UmaV2PriceProvider.sol";
import "../../src/v2/oracles/individual/UmaV2AssertionProvider.sol";
import "../../src/v2/oracles/individual/UmaV3PriceAssertionProvider.sol";
import "../../src/v2/oracles/individual/PythPriceProvider.sol";
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
        ConfigAddressesV2 memory addresses = getConfigAddresses(false);
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
        // ChainlinkPriceProvider chainlinkPriceProviderMIM = new ChainlinkPriceProvider(
        //         arbitrumSequencer,
        //         0xCe74c745DBb3620B9B31A08C6f913ac361d987A7,
        //         0x87121F6c9A9F6E90E59591E4Cf4804873f54A95b,
        //         timeOut
        // );
        //  ChainlinkPriceProvider chainlinkPriceProviderMAI = new ChainlinkPriceProvider(
        //         arbitrumSequencer,
        //         0xCe74c745DBb3620B9B31A08C6f913ac361d987A7,
        //         0x59644ec622243878d1464A9504F9e9a31294128a,
        //         timeOut
        // );

        // address vstPriceFeed = 0xd2F9EB49F563aAacE73eb1D19305dD5812F33179;
        // RedstonePriceProvider redstoneProvider = new RedstonePriceProvider(
        //     addresses.carouselFactory,
        //     vstPriceFeed,
        //     "VST",
        //     timeOut
        // );

        // address gdaiVault = 0xd85E038593d7A098614721EaE955EC2022B9B91B;
        // GdaiPriceProvider gdaiPriceProvider = new GdaiPriceProvider(gdaiVault);

        // address cviOracle = 0x649813B6dc6111D67484BaDeDd377D32e4505F85;
        // uint256 cviDecimals = 0;
        // CVIPriceProvider cviPriceProvider = new CVIPriceProvider(
        //     cviOracle,
        //     timeOut,
        //     cviDecimals
        // );

        // address diaOracleV2 = 0xd041478644048d9281f88558E6088e9da97df624;
        // DIAPriceProvider diaPriceProvider = new DIAPriceProvider(diaOracleV2);

        uint256 timeOut = 2 hours;
        address umaCurrency = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
        address umaV2Finder = 0xB0b9f73B424AD8dc58156C2AE0D7A1115D1EcCd1;
        uint256 reward = 5e6;

        // uint256 umaDecimals = 18;
        // string memory umaDescription = "FUSD/USD";
        // string
        //     memory ancillaryData = 'base:FDUSD,baseAddress:0xc5f0f7b66764F6ec8C8Dff7BA683102295E16409,baseChain: 1,quote:USD,quoteDetails:United States Dollar,rounding:18,fallback:"https://www.coingecko.com/en/coins/first-digital-usd",configuration:{"type": "medianizer","minTimeBetweenUpdates": 60,"twapLength": 600,"medianizedFeeds":[{ "type": "cryptowatch", "exchange": "binance", "pair": "fdusdusdt" }]}';

        // UmaV2PriceProvider umaV2PriceProvider = new UmaV2PriceProvider(
        //     timeOut,
        //     umaDecimals,
        //     umaDescription,
        //     umaV2Finder,
        //     umaCurrency,
        //     ancillaryData,
        //     reward
        // );

        string memory umaDescription = "AAVE aUSDC Hack Market";
        string
            memory ancillaryData = "q: Aave USDC.e pool (address: 0x625E7708f30cA75bfd92586e17077590C60eb4cD) on Arbitrum One was hacked or compromised leading to locked funds or >25% loss in TVL value after the timestamp of: ";
        UmaV2AssertionProvider umaV2AssertionProvider = new UmaV2AssertionProvider(
                timeOut,
                umaDescription,
                umaV2Finder,
                umaCurrency,
                ancillaryData,
                reward
            );

        // uint256 umaDecimals = 18;
        // address umaOOV3 = address(0x123);
        // string memory umaDescription = "USDC";
        // uint256 requiredBond = 1e6;
        // bytes32 defaultIdentifier = bytes32("abc");
        // bytes
        //     memory assertionDescription = "The USDC/USD exchange is above 0.997";
        // address currency = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1; // WETH_ADDRESS
        // UmaV3PriceAssertionProvider umaPriceProvider = new UmaV3PriceAssertionProvider(
        //         umaDecimals,
        //         umaDescription,
        //         timeOut,
        //         umaOOV3,
        //         defaultIdentifier,
        //         currency,
        //         assertionDescription,
        //         requiredBond
        //     );

        // address pythContract = 0xff1a0f4744e8582DF1aE09D5611b887B6a12925C;
        // // bytes32 fdUsdFeedId = 0xccdc1a08923e2e4f4b1e6ea89de6acbc5fe1948e9706f5604b8cb50bc1ed3979;
        // bytes32 cUsdFeedId = 0x8f218655050a1476b780185e89f19d2b1e1f49e9bd629efad6ac547a946bf6ab;
        // PythPriceProvider pythProvider = new PythPriceProvider(
        //     pythContract,
        //     cUsdFeedId,
        //     timeOut
        // );

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
        // KeeperV2Rollover rolloverKeeperPausable = new KeeperV2Rollover(
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
        //     "Chainlink Price Provider MIM",
        //     address(chainlinkPriceProviderMIM)
        // );
        // console2.log(
        //     "Chainlink Price Provider MAI",
        //     address(chainlinkPriceProviderMAI)
        // );
        // console2.log("Redstone Price Provider", address(redstoneProvider));
        // console2.log("Gdai Price Provider", address(gdaiPriceProvider));
        // console2.log("CVI Price Provider", address(cviPriceProvider));
        // console2.log("Dia Price Provider", address(diaPriceProvider));
        // console.log("Pyth Price Provider", address(pythProvider));
        // console2.log("Uma V2 Price Provider", address(umaV2PriceProvider));
        console2.log(
            "Uma V2 Assertion Provider",
            address(umaV2AssertionProvider)
        );
        // console2.log("Uma Price Provider", address(umaPriceProvider));

        // console2.log("resolveKeeper address", address(resolveKeeper));
        // console2.log("resolveKeeperGenericController address", address(resolveKeeperGenericController));
        // console2.log("rolloverKeeper address", address(rolloverKeeperPausable));
        // console2.log("Y2K token address", addresses.y2k);

        console2.log("\n");
    }
}
