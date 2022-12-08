// SPDX-License-Identifier;
pragma solidity ^0.8.13;

import "./Helper.sol";

/// @author MiguelBits
//forge script DeployScript --rpc-url $ARBITRUM_RPC_URL --private-key $PRIVATE_KEY --broadcast --skip-simulation --gas-estimate-multiplier 200 --slow -vv
contract DeployScript is Script, HelperConfig {

    mapping (uint => bool) isIndexDeployed;

    function setupY2K() public{
        ConfigAddresses memory addresses = getConfigAddresses();
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
        else if(configVariables.newEpochs){
            //deploy new epochs
            deployEpochs();
        }
    }

    function deployMarkets() public {
        for(uint i = 0; i < configVariables.amountOfNewMarkets;++i){
                uint marketId = configVariables.marketsIds[i];
                ConfigMarket memory markets = getConfigMarket(marketId);
                ConfigEpochs memory epochs = getConfigEpochs(marketId);
                //TODO verify
                require(markets.marketId == epochs.marketId, "marketId of markets and epochs are not the same");
                require(markets.marketId == marketId, "marketId of markets and loop are not the same");
    
                vaultFactory.createNewMarket(
                    epochs.epochFee, 
                    markets.token, 
                    markets.strikePrice, 
                    epochs.epochBegin, 
                    epochs.epochEnd, 
                    markets.oracle, 
                    markets.name);

                isIndexDeployed[marketId] = true;

                if(configVariables.newFarms){
                    ConfigFarms memory farms = getConfigFarms(marketId);
                    require(farms.marketId == marketId, "marketId of farms and loop are not the same");
                    (address _rHedge, 
                    address _rRisk) = rewardsFactory.createStakingRewards(
                        marketId, epochs.epochEnd);
                    fundFarms(_rHedge, _rRisk, 
                    farms.farmRewardsHEDGE, farms.farmRewardsRISK);
                }
            }
    }

    function deployEpochs() public {
        for(uint i = 0; i < configVariables.amountOfNewEpochs;++i){
                uint marketId = configVariables.epochsIds[i];
                ConfigEpochs memory epochs = getConfigEpochs(marketId);

                //TODO verify
                require(epochs.marketId == marketId, "marketId of epochs and loop are not the same");
    
                if(!isIndexDeployed[marketId]){
                    vaultFactory.deployMoreAssets(
                        marketId,
                        epochs.epochBegin, 
                        epochs.epochEnd, 
                        epochs.epochFee);

                    isIndexDeployed[marketId] = true;

                    if(configVariables.newFarms){
                        ConfigFarms memory farms = getConfigFarms(marketId);
                        require(farms.marketId == marketId, "marketId of farms and loop are not the same");
                        (address _rHedge, 
                        address _rRisk) = rewardsFactory.createStakingRewards(
                            marketId, epochs.epochEnd);
                        fundFarms(_rHedge, _rRisk, 
                        farms.farmRewardsHEDGE, farms.farmRewardsRISK);
                    }
                }
            }
    }

    function fundFarms(address _rHedge, address _rRisk, string memory _rewardsAmountHEDGE, string memory _rewardsAmountRISK) public {
        y2k.transfer(_rHedge, stringToUint(_rewardsAmountHEDGE));
        y2k.transfer(_rRisk, stringToUint(_rewardsAmountRISK));
        //start rewards for farms
        StakingRewards(_rHedge).notifyRewardAmount(stringToUint(_rewardsAmountHEDGE));
        StakingRewards(_rRisk).notifyRewardAmount(stringToUint(_rewardsAmountRISK));
    }

}