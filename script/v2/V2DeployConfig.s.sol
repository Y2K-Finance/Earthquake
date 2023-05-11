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
        if(configVariables.newMarkets) {
            //deploy new markets
            deployMarkets();
        }
        if(configVariables.epochs){
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
                console2.log("Market already deployed", market.token);
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
                console2.log("Market not deployed", epoch.token);
                revert("Market not deployed");
            }
            (uint256 epochId, ) = CarouselFactory(factory).createEpochWithEmissions(
                previewMarketID,
                epoch.epochBegin,
                epoch.epochEnd,
                epoch.withdrawalFee,
                epoch.collatEmissions,
                epoch.premiumEmissions
             );
            console2.log("epochId", epochId);
            console2.log("----------------------------------------------------------------");
            console2.log("\n");
        }
        // for(uint i = 0; i < configVariables.amountOfNewEpochs;++i){
        //         uint marketId = configVariables.epochsIds[i];
        //         console2.log("marketId", marketId);
        //         console2.log("INDEX", i);
                
        //         ConfigEpochs memory epochs = getConfigEpochs(i);
        //         //TODO verify
        //         require(epochs.marketId == marketId, "marketId of epochs and loop are not the same");
                
        //         vaultFactory.deployMoreAssets(
        //             marketId,
        //             epochs.epochBegin, 
        //             epochs.epochEnd, 
        //             epochs.epochFee);

        //         startKeepers(marketId, epochs.epochEnd);                
        //     }
    }

    function deployFarms() public {
        // for(uint i = 0; i < configVariables.amountOfNewFarms;++i){
        //     uint marketId = configVariables.farmsIds[i];
        //     ConfigFarms memory farms = getConfigFarms(i);
            
        //     require(farms.marketId == marketId, "marketId of farms and loop are not the same");
            
        //     (address _rHedge, 
        //     address _rRisk) = rewardsFactory.createStakingRewards(
        //         marketId, farms.epochEnd);
            
        //     fundFarms(_rHedge, _rRisk, 
        //     farms.farmRewardsHEDGE, farms.farmRewardsRISK);
        // }
    }

    function fundFarms(address _rHedge, address _rRisk, string memory _rewardsAmountHEDGE, string memory _rewardsAmountRISK) public {
        // y2k.transfer(_rHedge, stringToUint(_rewardsAmountHEDGE));
        // y2k.transfer(_rRisk, stringToUint(_rewardsAmountRISK));
        //start rewards for farms
        // StakingRewards(_rHedge).notifyRewardAmount(stringToUint(_rewardsAmountHEDGE));
        // StakingRewards(_rRisk).notifyRewardAmount(stringToUint(_rewardsAmountRISK));

        //unpause
        // StakingRewards(_rHedge).unpause();
        // StakingRewards(_rRisk).unpause();
    }

}