// SPDX-License-Identifier;
pragma solidity ^0.8.13;

import "./Helper.sol";

/// @author MiguelBits
//forge script ConfigEpochsScript --rpc-url $ARBITRUM_RPC_URL --private-key $PRIVATE_KEY --broadcast --skip-simulation --gas-estimate-multiplier 200 --slow -vv
contract ConfigEpochsScript is Script, HelperConfig {


    uint index = 6;

    function run() public {
        vm.startBroadcast();

        ConfigAddresses memory addresses = getConfigAddresses();
        ConfigMarket memory markets = getConfigMarket(index);
        ConfigEpochs memory epochs = getConfigEpochs(index);

        contractToAddresses(addresses);
        verifyConfig(markets, epochs);

        //INDEX
        //get epochs config
        console2.log("Epoch epoch begin", epochs.epochBegin);
        console2.log("Epoch epoch   end", epochs.epochEnd);
        console2.log("Epoch epoch fee", epochs.epochFee);
        console2.log("Farm rewards amount HEDGE", epochs.farmRewardsHEDGE);
        console2.log("Farm rewards amount RISK", epochs.farmRewardsRISK);
        //console2.log("Sender balance amnt", y2k.balanceOf(msg.sender));
        console2.log("\n");
        // create Epoch 
        vaultFactory.deployMoreAssets(index, epochs.epochBegin, epochs.epochEnd, epochs.epochFee);
        (address rHedge, address rRisk) = rewardsFactory.createStakingRewards(index, epochs.epochEnd);
        //sending gov tokens to farms
        y2k.transfer(rHedge, stringToUint(epochs.farmRewardsHEDGE));
        y2k.transfer(rRisk, stringToUint(epochs.farmRewardsRISK));
        //start rewards for farms
        StakingRewards(rHedge).notifyRewardAmount(y2k.balanceOf(rHedge));
        StakingRewards(rRisk).notifyRewardAmount(y2k.balanceOf(rRisk));
        // stop create Epoch
        
        //transfer onwership of farms
        // StakingRewards(rHedge).setRewardsDistribution(addresses.policy);
        // StakingRewards(rRisk).setRewardsDistribution(addresses.policy);
        // StakingRewards(rHedge).nominateNewOwner(addresses.policy);
        // StakingRewards(rRisk).nominateNewOwner(addresses.policy);

        console2.log("Farm Hedge", rHedge);
        console2.log("Farm Risk", rRisk);

        startKeepers(index, epochs.epochEnd);

        console.log("ConfigEpochsScript done");

        vm.stopBroadcast();
    }
}