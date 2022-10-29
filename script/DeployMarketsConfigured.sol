// SPDX-License-Identifier;
pragma solidity ^0.8.13;

import "./Helper.sol";

/// @author MiguelBits
//forge script ConfigScript --rpc-url $ARBITRUM_RPC_URL --private-key $PRIVATE_KEY --broadcast --skip-simulation --gas-estimate-multiplier 200 --slow -vv
contract ConfigMarketsScript is Script, HelperConfig {

    uint index = 7;

    function run() public {
        vm.startBroadcast();

        ConfigAddresses memory addresses = getConfigAddresses();
        ConfigMarket memory markets = getConfigMarket(index);
        ConfigFarm memory farms = getConfigFarm(index);

        contractToAddresses(addresses);

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
        console2.log("Farm rewards amount HEDGE", farms.rewardsAmountHEDGE);
        console2.log("Farm rewards amount RISK", farms.rewardsAmountRISK);
        //console2.log("Sender balance amnt", y2k.balanceOf(msg.sender));
        console2.log("\n");
        // create market 
        vaultFactory.createNewMarket(markets.epochFee, markets.token, markets.strikePrice, markets.epochBegin, markets.epochEnd, markets.oracle, markets.name);
        (address rHedge, address rRisk) = rewardsFactory.createStakingRewards(index, markets.epochEnd);
        //sending gov tokens to farms
        y2k.transfer(rHedge, stringToUint(farms.rewardsAmountHEDGE));
        y2k.transfer(rRisk, stringToUint(farms.rewardsAmountRISK));
        //start rewards for farms
        StakingRewards(rHedge).notifyRewardAmount(stringToUint(farms.rewardsAmountHEDGE));
        StakingRewards(rRisk).notifyRewardAmount(stringToUint(farms.rewardsAmountRISK));
        // stop create market

        console2.log("Farm Hedge", rHedge);
        console2.log("Farm Risk", rRisk);
        
        startKeepers(index, markets.epochEnd);

        console.log("ConfigMarketsScript done");

        vm.stopBroadcast();
    }

}