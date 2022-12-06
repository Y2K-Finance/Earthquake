// SPDX-License-Identifier;
pragma solidity ^0.8.13;

import "./Helper.sol";

/// @author MiguelBits
//forge script ConfigEpochsScript --rpc-url $ARBITRUM_RPC_URL --private-key $PRIVATE_KEY --broadcast --skip-simulation --gas-estimate-multiplier 200 --slow -vv
contract ConfigEpochsScript is Script, HelperConfig {


    uint index = 8;

    function run() public {
        vm.startBroadcast();

        ConfigAddresses memory addresses = getConfigAddresses();
        ConfigEpochs memory epochs = getConfigEpochs(index);
        ConfigFarm memory farms = getConfigFarm(index);

        contractToAddresses(addresses);

        //INDEX
        //get epochs config
        console2.log("Epoch epoch begin", epochs.epochBegin);
        console2.log("Epoch epoch   end", epochs.epochEnd);
        console2.log("Epoch epoch fee", epochs.epochFee);
        console2.log("Farm rewards amount HEDGE", farms.rewardsAmountHEDGE);
        console2.log("Farm rewards amount RISK", farms.rewardsAmountRISK);
        //console2.log("Sender balance amnt", y2k.balanceOf(msg.sender));
        console2.log("\n");
        // create Epoch 
        vaultFactory.deployMoreAssets(index, epochs.epochBegin, epochs.epochEnd, epochs.epochFee);
        (address rHedge, address rRisk) = rewardsFactory.createStakingRewards(index, epochs.epochEnd);
        //sending gov tokens to farms
        y2k.transfer(rHedge, stringToUint(farms.rewardsAmountHEDGE));
        y2k.transfer(rRisk, stringToUint(farms.rewardsAmountRISK));
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