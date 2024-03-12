// SPDX-License-Identifier;
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";
import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../test/V2/DummyERC20.sol";
import "../../src/v2/VaultFactoryV2.sol";
import "../../src/v2/Controllers/ControllerPeggedAssetV2.sol";
import "../../src/v2/Controllers/ControllerGeneric.sol";
import "../../src/v2/oracles/individual/AdminPriceProvider.sol";
import "../../src/v2/oracles/individual/ChainlinkPriceProvider.sol";
import "../../src/v2/oracles/individual/RedstonePriceProvider.sol";
import "../../src/v2/oracles/individual/DIAPriceProvider.sol";
import "../../src/v2/oracles/individual/PythPriceProvider.sol";
import "../../src/v2/oracles/individual/CVIPriceProvider.sol";
import "../../src/v2/oracles/individual/GdaiPriceProvider.sol";
import "../../src/v2/oracles/individual/UmaV2PriceProvider.sol";
import "../../src/v2/oracles/individual/UmaV2AssertionProvider.sol";
import "../../src/v2/oracles/individual/UmaV3PriceProvider.sol";
import "../../src/v2/oracles/individual/UmaV3PriceProviderRound.sol";
import "../../src/v2/oracles/individual/UmaV3PriceProviderVol.sol";
import "../../src/v2/oracles/individual/UmaV3AssertionProvider.sol";
import "../../src/v2/oracles/individual/PythPriceProvider.sol";
import "../../src/v2/TimeLock.sol";
import "./V2Helper.sol";
import {KeeperV2GenericController} from "../keepers/KeeperV2GenericController.sol";

//forge script V2DeploymentScript --rpc-url $ARBITRUM_RPC_URL --broadcast --verify -slow -vv

// forge verify-contract --chain-id 42161 --num-of-optimizations 1000000 --watch --constructor-args $(cast abi-encode "constructor(address,address,address,address,uint256)" 0xaC0D2cF77a8F8869069fc45821483701A264933B 0xaC0D2cF77a8F8869069fc45821483701A264933B 0x65c936f008BC34fE819bce9Fa5afD9dc2d49977f 0x447deddf312ad609e2f85fd23130acd6ba48e8b7 1668384000) --compiler-version v0.8.15+commit.e14f2714 0x69b614f03554c7e0da34645c65852cc55400d0f9 src/rewards/StakingRewards.sol:StakingRewards $arbiscanApiKey

// forge script V2DeployContracts --rpc-url $ARBITRUM_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --skip-simulation --slow -vvvv
contract V2DeployContracts is Script, HelperV2 {
    using stdJson for string;

    function run() public {
        ConfigAddressesV2 memory addresses = getConfigAddresses(true); // false = prod, true = testing
        // address weth = addresses.weth;
        // address treasury = addresses.treasury;
        // address emissionToken = addresses.y2k;
        // address policy = addresses.policy;
        address factory = addresses.carouselFactory;

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

        /**
         * Bera Logic Public Testnet
         */
        // address beraPausableFactory = 0x91A9f0D1E66712d56E0fC6E8fAABbd712aeB84f8; // Factory on Bera
        // address beraController = 0x6a734800E9CC915d3305cCfb290c23DdE187cE7F; // Controller on Bera
        // address beraWeth = 0x8239FBb3e3D0C2cDFd7888D8aF7701240Ac4DcA4; // WETH on Bera
        // address beraWbtc = 0x9DAD8A1F64692adeB74ACa26129e0F16897fF4BB; // WBTC on Bera
        // address beraHoney = 0x7EeCA4205fF31f947EdBd49195a7A88E6A91161B; // Honey on Bera
        // address beraWBERA = 0x5806E416dA447b267cEA759358cF22Cc41FAE80F; // WBERA on Bera
        // address beraTreasury = 0x9EF27dB2778690edf94632F1C57d0Bd2fDAadd7f; // Treasury on Bera
        // address beraY2KDummy = 0x22A558bBc6986cD4F9b561089cb0c5AB62f1534e; // Y2K on Bera
        // address beraAdminOracleETH = 0x131d85f66F2f297477Ad22Ea4E222a864Bb122E5; // Admin Oracle on Bera ETH
        // address beraAdminOracleBTC = 0x12f142705a1AeFD7708250e14fe6FA71E73258A5; // Oracle for WBTC on Bera
        address blastETH = 0x9E9950E8c9aFDDE8e3f55B52014b7610faE3BC5a;

        /**
         * Blast testnet
         */
        address blastTreasury = 0x2d244ed7d17AE47886f7f13F53e74b6B0bC16fdC; // EOA on blast

        /**
         * ------ Broadcast ------
         */
        vm.startBroadcast();
        uint256 timeOut = 12 hours;

        // TimeLock timeLock = new TimeLock(policy);
        // // factory.changeTimelocker(address(timeLock));

        /**
         * Dummy or Y2K Token
         */
        // DummyERC20 y2kDummy = new DummyERC20();
        // console2.log("Y2K Dummy address", address(y2kDummy));

        /**
         * Carousel Factory
         */
        // CarouselFactoryPausable deployedVaultFactory = new CarouselFactoryPausable(
        //         blastETH,
        //         blastTreasury,
        //         msg.sender,
        //         address(y2kDummy)
        //     );
        // CarouselFactoryPausable factory = CarouselFactoryPausable(deployedVaultFactory);

        /**
         * Controllers
         */
        // ControllerPeggedAssetV2 controller = new ControllerPeggedAssetV2(
        //     address(deployedVaultFactory),
        //     addresses.arbitrum_sequencer
        // );
        // vaultFactory.whitelistController(address(controller));

        // ControllerGeneric controllerGeneric = new ControllerGeneric(
        //     address(deployedVaultFactory),
        //     blastTreasury
        // );
        // console.log("Controller Generic address", address(controllerGeneric));
        // deployedVaultFactory.whitelistController(address(controllerGeneric));
        // deployedVaultFactory.whitelistController(address(controller));
        // carouselFactory.whitelistController(address(controllerGeneric));

        /**
         * New Markets
         */
        // CarouselFactoryPausable factory = CarouselFactoryPausable(
        //     pausableFactory
        // );
        // (address prem, address collat, uint256 marketId) = factory
        //     .createNewCarouselMarket(
        //         CarouselFactoryPausable.CarouselMarketConfigurationCalldata(
        //             beraWbtc,
        //             50_000e8, // Strike price
        //             beraAdminOracleBTC,
        //             beraWBERA,
        //             "y2kBTC_3000_WBERA*", // marketName
        //             "https://y2k.finance", // marketUri
        //             address(beraController),
        //             200000000000000, // relayFee
        //             0, // depositFee
        //             25000000000000000 // minQueueDeposit
        //         )
        //     );
        // console2.log("Carousel Market prem", prem);
        // console2.log("Carousel Market collateral", collat);
        // console2.log("Carousel Market marketId", marketId);
        // // IERC20(beraY2KDummy).approve(address(factory), type(uint256).max);

        // uint256 marketId = 75423911543813429950440277204588325011001806362079737252920180136286107657801;
        // uint40 epochBegin = 1707868800;
        // uint40 epochEnd = 1708232400;
        // (uint256 epochId, address[2] memory vaults) = CarouselFactory(
        //     beraPausableFactory
        // ).createEpochWithEmissions(marketId, epochBegin, epochEnd, 500, 0, 0);
        // console.log("Epoch Id", epochId);
        // console.log("Vault 1", vaults[0]);
        // console.log("Vault 2", vaults[1]);

        /**
         * Chainlink Oracle
         */
        // address arbitrumSequencer = 0xFdB631F5EE196F0ed6FAa767959853A9F217697D;
        // address crvUSDFeed = 0x0a32255dd4BB6177C994bAAc73E0606fDD568f66;
        // ChainlinkPriceProvider chainlinkPriceProvider =
        //     new ChainlinkPriceProvider(arbitrumSequencer, factory, crvUSDFeed, timeOut);
        // console2.log(
        //     "Chainlink Price Provider",
        //     address(chainlinkPriceProvider)
        // );

        /**
         * Admin Oracle
         */
        // AdminPriceProvider adminProvider = new AdminPriceProvider(
        //     beraPausableFactory,
        //     timeOut,
        //     8,
        //     "BTC/USD"
        // );
        // console2.log("Admin Price provider", address(adminProvider));

        /**
         * Redstone Oracles
         */
        // address vstPriceFeed = 0xd2F9EB49F563aAacE73eb1D19305dD5812F33179;
        // RedstonePriceProvider redstoneProvider = new RedstonePriceProvider(
        //     addresses.carouselFactory,
        //     vstPriceFeed,
        //     "VST",
        //     timeOut
        // );
        // console2.log("Redstone Price Provider", address(redstoneProvider));

        /**
         * GDAI Oracle
         */
        // address gdaiVault = 0xd85E038593d7A098614721EaE955EC2022B9B91B;
        // GdaiPriceProvider gdaiPriceProvider = new GdaiPriceProvider(gdaiVault);
        // console2.log("Gdai Price Provider", address(gdaiPriceProvider));

        /**
         * CVI Oracle
         */
        // address cviOracle = 0x649813B6dc6111D67484BaDeDd377D32e4505F85;
        // uint256 cviDecimals = 0;
        // CVIPriceProvider cviPriceProvider = new CVIPriceProvider(
        //     cviOracle,
        //     timeOut,
        //     cviDecimals
        // );
        // console2.log("CVI Price Provider", address(cviPriceProvider));

        /**
         * Dia Oracle
         */
        // address diaOracleV2 = 0xd041478644048d9281f88558E6088e9da97df624;
        // DIAPriceProvider diaPriceProvider = new DIAPriceProvider(diaOracleV2);
        // console2.log("Dia Price Provider", address(diaPriceProvider));

        /**
         * Uma V2 Oracles
         */
        // address umaCurrency = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
        // address umaV2Finder = 0xB0b9f73B424AD8dc58156C2AE0D7A1115D1EcCd1;
        // uint128 reward = 5e6;
        // uint256 umaDecimals = 18;

        // string memory umaPriceDescription = "FUSD/USD";
        // string memory umaAssertDescription = "AAVE aUSDC Hack Market";

        // string
        //     memory priceAncillaryData = 'base:FDUSD,baseAddress:0xc5f0f7b66764F6ec8C8Dff7BA683102295E16409,baseChain: 1,quote:USD,quoteDetails:United States Dollar,rounding:18,fallback:"https://www.coingecko.com/en/coins/first-digital-usd",configuration:{"type": "medianizer","minTimeBetweenUpdates": 60,"twapLength": 600,"medianizedFeeds":[{ "type": "cryptowatch", "exchange": "binance", "pair": "fdusdusdt" }]}';
        // string
        //     memory assertAncillaryData = "q: Aave USDC.e pool (address: 0x625E7708f30cA75bfd92586e17077590C60eb4cD) on Arbitrum One was hacked or compromised leading to locked funds or >25% loss in TVL value after the timestamp of: ";

        // UmaV2PriceProvider umaV2PriceProvider = new UmaV2PriceProvider(
        //     timeOut,
        //     umaDecimals,
        //     umaPriceDescription,
        //     umaV2Finder,
        //     umaCurrency,
        //     priceAncillaryData,
        //     reward
        // );
        // console2.log("Uma V2 Price Provider", address(umaV2PriceProvider));

        // UmaV2AssertionProvider umaV2AssertionProvider = new UmaV2AssertionProvider(
        //         timeOut,
        //         umaAssertDescription,
        //         umaV2Finder,
        //         umaCurrency,
        //         assertAncillaryData,
        //         reward
        //     );
        // console2.log(
        //     "Uma V2 Assertion Provider",
        //     address(umaV2AssertionProvider)
        // );

        /**
         * Uma V3 Oracles
         */
        // timeOut = 6 hours;
        // uint256 umaDecimals = 18;
        // address currency = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1; // WETH_ADDRESS on Arb
        // address currency = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8; // USDC.e on Arb
        // address currency = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F; // USDC on Goerli

        // address umaOOV3 = 0xa6147867264374F324524E30C02C331cF28aa879; // Arbitrum One
        // address umaOOV3 = 0x9923D42eF695B5dd9911D05Ac944d4cAca3c4EAB; // Goerli

        // uint256 requiredBond = 0; // USDC bond on Goerli
        // uint256 requiredBond = 500e6; // USDC.e bond on Arb

        // Descriptions & Assertions for Uma
        // string memory umaDescription = "crvUSD/USD";
        // string memory umaDescription = "ETH Realised Volatility (30-day)";
        // string memory umaDescription = "BTC Realised Volatility (30-day)";

        // string
        //     memory assertionDescription = ". Using the following resources for validation {chain: Ethereum, dataSource: Chainlink, assetIdOnDataSource: CRVUSD/USD, methodologyUrl: https://shorturl.at/cIP39}. The price of crvUSD/USD is ";
        // string
        //     memory assertionDescription = ". Using the following resources for validation {chain: Arbitrum, dataSource: Chainlink, assetIdOnDataSource: ETH/USD, methodologyUrl: https://shorturl.at/cqBJS, scriptUrl: https://shorturl.at/afim8}. The annualised 30-day realised volatility price for Ethereum (ETH) is: ";
        // string
        // memory assertionDescription = ". Using the following resources for validation {chain: Arbitrum, dataSource: Chainlink, assetIdOnDataSource: BTC/USD, methodologyUrl: https://shorturl.at/cqBJS , scriptUrl: https://shorturl.at/afim8}. The annualised 30-day realised volatility price for Bitcoin (BTC) is: ";

        // UmaV3PriceProviderVol umaV3Provider = new UmaV3PriceProviderVol(
        //     umaDecimals,
        //     umaDescription,
        //     assertionDescription,
        //     timeOut,
        //     umaOOV3,
        //     currency,
        //     requiredBond
        // );

        // UmaV3PriceProviderRound umaV3Provider = new UmaV3PriceProviderRound(
        //     umaDecimals,
        //     umaDescription,
        //     assertionDescription,
        //     timeOut,
        //     umaOOV3,
        //     currency,
        //     requiredBond
        // );

        // console2.log("Uma V3 Provider", address(umaV3Provider));

        /**
         * Pyth Oracles
         */
        address pythContract = 0xff1a0f4744e8582DF1aE09D5611b887B6a12925C;
        bytes32 feed = 0x6ec879b1e9963de5ee97e9c8710b742d6228252a5e2ca12d4ae81d7fe5ee8c5d;
        PythPriceProvider pythProvider = new PythPriceProvider(pythContract, feed, timeOut);
        console.log("Pyth Price Provider", address(pythProvider));

        /**
         * Whitelisting controllers  & Keepers
         */
        // vaultFactory.whitelistController(address(controller));

        /*//////////////////////////////////////////////////////////////
                                ORACLES
        //////////////////////////////////////////////////////////////*/

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

        // address cviOracle = 0x649813B6dc6111D67484BaDeDd377D32e4505F85;
        // uint256 cviDecimals = 0;
        // CVIPriceProvider cviPriceProvider = new CVIPriceProvider(
        //     cviOracle,
        //     timeOut,
        //     cviDecimals
        // );

        address _pyth = 0xff1a0f4744e8582DF1aE09D5611b887B6a12925C;
        bytes32 _priceFeedId = 0x5bc91f13e412c07599167bae86f07543f076a638962b8d6017ec19dab4a82814;
        uint256 _timeOut = 24 hours;
        PythPriceProvider pythPriceProvider = new PythPriceProvider(_pyth, _priceFeedId, _timeOut);

        /*//////////////////////////////////////////////////////////////
                                KEEPERS
        //////////////////////////////////////////////////////////////*/

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

        /**
         * Timelock, Controller & Factory logs
         */
        // console2.log("TimeLock address", timeLock);
        // console2.log("Vault Factory address", address(deployedVaultFactory));
        // console2.log("Controller address", address(controller));
        // console2.log("Controller Generic address", address(controllerGeneric));

        /**
         * Keeper logs
         */
        // console2.log("resolveKeeper address", address(resolveKeeper));
        // console2.log("resolveKeeperGenericController address", address(resolveKeeperGenericController));
        // console2.log("rolloverKeeper address", address(rolloverKeeperPausable));
        // console2.log("Y2K token address", addresses.y2k);

        console2.log("\n");
    }
}
