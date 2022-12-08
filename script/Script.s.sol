// SPDX-License-Identifier;
pragma solidity ^0.8.13;

import "./Helper.sol";

/// @author MiguelBits
//forge script ConfigScript --rpc-url $ARBITRUM_RPC_URL --private-key $PRIVATE_KEY --broadcast --skip-simulation --gas-estimate-multiplier 200 --slow -vv
contract ConfigScript is Script, HelperConfig {

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
        if(configVariables.newMarkets) {
            //deploy new markets
            for(uint i = 0; i < configVariables.amountOfNewMarkets;++i){
                uint index = configVariables.marketsIds[i];
                ConfigMarket memory markets = getConfigMarket(index);
                ConfigEpochs memory epochs = getConfigEpochs(index);

                //TODO verify
                require(markets.index == epochs.index, "index of markets and epochs are not the same");
                require(markets.index == index, "index of markets and loop are not the same");
    
                vaultFactory.createNewMarket(
                    epochs.epochFee, 
                    markets.token, 
                    markets.strikePrice, 
                    epochs.epochBegin, 
                    epochs.epochEnd, 
                    markets.oracle, 
                    markets.name);

                isIndexDeployed[index] = true;

                if(configVariables.newFarms){
                    ConfigFarms memory farms = getConfigFarms(index);
                    require(farms.index == index, "index of farms and loop are not the same");
                    (address _rHedge, 
                    address _rRisk) = rewardsFactory.createStakingRewards(
                        index, epochs.epochEnd);
                    fundFarms(_rHedge, _rRisk, 
                    farms.farmRewardsHEDGE, farms.farmRewardsRISK);
                }
            }
        }
        else if(configVariables.newEpochs){
            //deploy new markets
            for(uint i = 0; i < configVariables.amountOfNewEpochs;++i){
                uint index = configVariables.epochsIds[i];
                ConfigEpochs memory epochs = getConfigEpochs(index);

                //TODO verify
                require(epochs.index == index, "index of epochs and loop are not the same");
    
                if(!isIndexDeployed[index]){
                    vaultFactory.deployMoreAssets(
                        index,
                        epochs.epochBegin, 
                        epochs.epochEnd, 
                        epochs.epochFee);

                    isIndexDeployed[index] = true;

                    if(configVariables.newFarms){
                        ConfigFarms memory farms = getConfigFarms(index);
                        require(farms.index == index, "index of farms and loop are not the same");
                        (address _rHedge, 
                        address _rRisk) = rewardsFactory.createStakingRewards(
                            index, epochs.epochEnd);
                        fundFarms(_rHedge, _rRisk, 
                        farms.farmRewardsHEDGE, farms.farmRewardsRISK);
                    }
                }
            }
        }

        vm.stopBroadcast();
    }

    function fundFarms(address _rHedge, address _rRisk, string memory _rewardsAmountHEDGE, string memory _rewardsAmountRISK) public {
        y2k.transfer(_rHedge, stringToUint(_rewardsAmountHEDGE));
        y2k.transfer(_rRisk, stringToUint(_rewardsAmountRISK));
        //start rewards for farms
        StakingRewards(_rHedge).notifyRewardAmount(stringToUint(_rewardsAmountHEDGE));
        StakingRewards(_rRisk).notifyRewardAmount(stringToUint(_rewardsAmountRISK));
    }

}