// SPDX-License-Identifier;
pragma solidity ^0.8.15;

import "./V2Helper.sol";

/// @author MiguelBits
//forge script V2DeployConfig --rpc-url $ARBITRUM_RPC_URL --private-key $PRIVATE_KEY --broadcast --skip-simulation --slow --verify -vv
contract V2DeployConfig is HelperV2 {
    CarouselFactory factory;
    function setupY2K() public{
        ConfigAddressesV2 memory addresses = getConfigAddresses(true); //true if test env
        console.log("Address admin", addresses.admin);
        console.log("Address arbitrum_sequencer", addresses.arbitrum_sequencer);
        console.log("Address Factory", addresses.carouselFactory);
        factory = CarouselFactory(addresses.carouselFactory);
        contractToAddresses(addresses);
        setVariables();
    }

    function run() public {
        //LOAD json config and check bool deploy new markets
        setupY2K();
        //if true deploy new markets
        vm.startBroadcast();
        
        deploy();

        vm.stopBroadcast();
    }

    function deploy() public {
        fundKeepers(4000000000000000);
        if(configVariables.newMarkets) {
            //deploy new markets
            deployMarkets();
        }
        if(configVariables.epochs){
            IERC20(y2k).approve(address(factory), type(uint256).max);
            //deploy new epochs
            deployEpochs();
        }
        
    }

    function deployMarkets() public {
        ConfigMarketV2[] memory markets = getConfigMarket();
        console2.log("-------------------------DEPLOY MARKETS----------------------");
        
        if(markets.length != configVariables.amountOfNewMarkets){
            console.log("markets.length", markets.length);
            console.log("configVariables.amountOfNewMarkets", configVariables.amountOfNewMarkets);
            revert("markets.length != configVariables.amountOfNewMarkets");
        }
        for(uint i = 0; i < markets.length;++i){
            ConfigMarketV2 memory market = markets[i];
            if(!factory.controllers(market.controller)) {
                console2.log("Controller not whitelisted", market.controller);
                revert("Controller not whitelisted");
            }
            uint256 previewMarketID = factory.getMarketId(
                market.token,
                market.strikePrice,
                market.depositAsset
            );
            address vault =  factory.marketIdToVaults(previewMarketID, 0);
            if(vault != address(0)) {
                console2.log("Market already deployed", previewMarketID);
                console2.log("Market: ", market.token, market.strikePrice, market.depositAsset);
                revert("Market already deployed");
            }
            ( address prem, address collat, uint256 marketId) =  factory.createNewCarouselMarket(
                CarouselFactory.CarouselMarketConfigurationCalldata(
                    market.token,
                    market.strikePrice,
                    market.oracle,
                    market.depositAsset,
                    market.name,
                    market.uri,
                    market.controller,
                    market.relayFee, 
                    market.depositFee, 
                    market.minQueueDeposit
                )
            );
            console2.log("marketId", marketId);
            console2.log("prem", prem);
            console2.log("collat", collat);
            console2.log("----------------------------------------------------------------");
            console2.log("\n");
        }
    }

    function deployEpochs() public {
        ConfigAddressesV2 memory addresses = getConfigAddresses(true);
        ConfigEpochWithEmission[] memory epochs = getConfigEpochs();
        if(IERC20(y2k).allowance(addresses.policy, address(factory)) < configVariables.totalAmountOfEmittedTokens) {
            console2.log("Not enough allowance", IERC20(y2k).allowance(address(this), address(factory)));
            revert("Not enough allowance");
        } 
        console2.log("-------------------------DEPLOY EPOCHS----------------------");
         if(epochs.length != configVariables.amountOfNewEpochs){
            console.log("epochs.length", epochs.length);
            console.log("configVariables.amountOfNewEpochs", configVariables.amountOfNewEpochs);
            revert("epochs.length != configVariables.amountOfNewEpochs");
        }
       for(uint i = 0; i < epochs.length;++i){
            ConfigEpochWithEmission memory epoch = epochs[i];
            uint256 previewMarketID = factory.getMarketId(
                epoch.token,
                epoch.strikePrice,
                epoch.depositAsset
            );
            address vault =  factory.marketIdToVaults(previewMarketID, 0);
            if(vault == address(0)) {
                console2.log("Market not deployed", epoch.token, epoch.strikePrice, epoch.depositAsset);
                revert("Market not deployed");
            }
            (uint256 epochId, address[2] memory vaults) = CarouselFactory(factory).createEpochWithEmissions(
                previewMarketID,
                epoch.epochBegin,
                epoch.epochEnd,
                epoch.withdrawalFee,
                epoch.collatEmissions,
                epoch.premiumEmissions
             );
            if(isTestEnv) {
                IERC20(addresses.weth).approve(vaults[0], 1 ether);
                ICarousel(vaults[0]).deposit(0, 1 ether, 0xCCA23C05a9Cf7e78830F3fd55b1e8CfCCbc5E50F);
                IERC20(addresses.weth).approve(vaults[1], 1 ether);
                ICarousel(vaults[1]).deposit(0, 1 ether, 0xCCA23C05a9Cf7e78830F3fd55b1e8CfCCbc5E50F);
            } 
            startKeepers(previewMarketID, epochId);
            console2.log("epochId", epochId);
            console2.log("----------------------------------------------------------------");
            console2.log("\n");
        }
    }

}