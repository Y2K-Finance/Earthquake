// SPDX-License-Identifier;
pragma solidity ^0.8.13;

import "./Helper.sol";

/// @author MiguelBits
//forge script DeployScript --rpc-url $ARBITRUM_RPC_URL --private-key $PRIVATE_KEY --broadcast --skip-simulation --gas-estimate-multiplier 200 --slow -vv
contract DeployScript is Script, HelperConfig {

    function setupY2K() public{
        ConfigAddresses memory addresses = getConfigAddresses(true); //true if test env
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

    function deploy() payable public {
        // fundKeepers(5000000000000000); // uncomment to fund keepers
        if(configVariables.newMarkets) {
            //deploy new markets
            deployMarkets();
        }
        if(configVariables.newEpochs){
            //deploy new epochs
            deployEpochs();
        }
        if(configVariables.newFarms){
            //deploy new farms
            deployFarms();
        }
    }

    function deployMarkets() public {
        for(uint i = 0; i < configVariables.amountOfNewMarkets;++i){
                uint marketId = configVariables.marketsIds[i];
                ConfigMarket memory markets = getConfigMarket(i);
                //TODO verify
                require(markets.marketId == marketId, "marketId of markets and loop are not the same");
    
                vaultFactory.createNewMarket(
                    1, 
                    markets.token, 
                    markets.strikePrice, 
                    block.timestamp - 2,
                    block.timestamp - 1, 
                    markets.oracle, 
                    markets.name);

                //resolve triggerNullEpoch / endEpoch
                controller.triggerNullEpoch(marketId, block.timestamp - 1);
            }
    }

    function deployEpochs() public {
        for(uint i = 0; i < configVariables.amountOfNewEpochs;++i){
                uint marketId = configVariables.epochsIds[i];
                console2.log("marketId", marketId);
                console2.log("INDEX", i);
                
                ConfigEpochs memory epochs = getConfigEpochs(i);
                //TODO verify
                require(epochs.marketId == marketId, "marketId of epochs and loop are not the same");
                
                vaultFactory.deployMoreAssets(
                    marketId,
                    epochs.epochBegin, 
                    epochs.epochEnd, 
                    epochs.epochFee);

                startKeepers(marketId, epochs.epochEnd);                
            }
    }

    function deployFarms() public {
        for(uint i = 0; i < configVariables.amountOfNewFarms;++i){
            uint marketId = configVariables.farmsIds[i];
            ConfigFarms memory farms = getConfigFarms(i);
            
            require(farms.marketId == marketId, "marketId of farms and loop are not the same");
            
            (address _rHedge, 
            address _rRisk) = rewardsFactory.createStakingRewards(
                marketId, farms.epochEnd);
            
            fundFarms(_rHedge, _rRisk, 
            farms.farmRewardsHEDGE, farms.farmRewardsRISK);
        }
    }

    function fundFarms(address _rHedge, address _rRisk, string memory _rewardsAmountHEDGE, string memory _rewardsAmountRISK) public {
        y2k.transfer(_rHedge, stringToUint(_rewardsAmountHEDGE));
        y2k.transfer(_rRisk, stringToUint(_rewardsAmountRISK));
        //start rewards for farms
        StakingRewards(_rHedge).notifyRewardAmount(stringToUint(_rewardsAmountHEDGE));
        StakingRewards(_rRisk).notifyRewardAmount(stringToUint(_rewardsAmountRISK));

        //unpause
        StakingRewards(_rHedge).unpause();
        StakingRewards(_rRisk).unpause();
    }

}