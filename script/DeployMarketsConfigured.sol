// SPDX-License-Identifier;
pragma solidity ^0.8.13;

import "./Helper.sol";

/// @author MiguelBits
//forge script ConfigMarketsScript --rpc-url $ARBITRUM_RPC_URL --private-key $PRIVATE_KEY --broadcast --skip-simulation --gas-estimate-multiplier 200 --slow -vv
contract ConfigMarketsScript is Script, HelperConfig {

    uint256[2] public marketIndexesToDeploy = [13,14];

    function run() public {
        vm.startBroadcast();

        ConfigAddresses memory addresses = getConfigAddresses();
        contractToAddresses(addresses);
        for(uint256 index = 0; index < marketIndexesToDeploy.length; ++index){

            console.log("Deploying market index", marketIndexesToDeploy[index]);
            ConfigMarket memory markets = getConfigMarket(marketIndexesToDeploy[index]);

            if(marketIndexesToDeploy[index] == markets.index){
                verifyConfig(markets);
                //INDEX
                //get markets config
                console2.log("Market index", index);
                console2.log("Market name", markets.name);
                console2.log("Adress token", addresses.tokenFRAX);
                console2.log("Market token", markets.token);
                console2.log("Adress oracle", addresses.oracleFRAX);
                console2.log("Market oracle", markets.oracle);
                console2.log("Market strike price", uint256(markets.strikePrice));
                console2.log("Market epoch begin", markets.epochBegin);
                console2.log("Market epoch   end", markets.epochEnd);
                console2.log("Market epoch fee", markets.epochFee);
                console2.log("Farm rewards amount HEDGE", markets.farmRewardsHEDGE);
                console2.log("Farm rewards amount RISK", markets.farmRewardsRISK);
                //console2.log("Sender balance amnt", y2k.balanceOf(msg.sender));
                console2.log("\n");
                // create market 
                createMarket(markets, index);
            }
            
        }

        console.log("ConfigMarketsScript done");

        vm.stopBroadcast();
    }

    function createMarket(ConfigMarket memory markets, uint256 index) internal {
        //create market
         vaultFactory.createNewMarket(markets.epochFee, markets.token, markets.strikePrice, markets.epochBegin, markets.epochEnd, markets.oracle, markets.name);
        (address rHedge, address rRisk) = rewardsFactory.createStakingRewards(index, markets.epochEnd);
        // //sending gov tokens to farms
        y2k.transfer(rHedge, stringToUint(markets.farmRewardsHEDGE));
        y2k.transfer(rRisk, stringToUint(markets.farmRewardsRISK));
        //start rewards for farms
        StakingRewards(rHedge).notifyRewardAmount(stringToUint(markets.farmRewardsHEDGE));
        StakingRewards(rRisk).notifyRewardAmount(stringToUint(markets.farmRewardsRISK));
        // // stop create market

        //transfer onwership of farms
        // StakingRewards(rHedge).setRewardsDistribution(addresses.policy);
        // StakingRewards(rRisk).setRewardsDistribution(addresses.policy);
        // StakingRewards(rHedge).nominateNewOwner(addresses.policy);
        // StakingRewards(rRisk).nominateNewOwner(addresses.policy);

        console2.log("Farm Hedge", rHedge);
        console2.log("Farm Risk", rRisk);
        
        startKeepers(index, markets.epochEnd);
    }

}