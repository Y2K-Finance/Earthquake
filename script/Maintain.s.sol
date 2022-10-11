// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "./Helper.sol";
import "../src/VaultFactory.sol";
import "../src/Controller.sol";
import "../src/rewards/RewardsFactory.sol";
import "../test/GovToken.sol";
import "../test/oracles/DepegOracle.sol";

/// @author MiguelBits

/*
forge script script/Maintain.s.sol:MaintainScript --rpc-url $ARBITRUM_RINKEBY_RPC_URL  --private-key $PRIVATE_KEY --broadcast -vv

Controller address 0xE3790E0bc21F43868A2527a999A9a11c807AD659
Vault Factory address 0xAD78ccB7F26CAECf09406a0541012330874A8466
Rewards Factory address 0x2c4C123b87Ee0019F830c4AB30118c8f53cD2b9F
GovToken address 0x4bd30F77809730E38EE59eE0e8FF008407dD3025
*/
contract MaintainScript is Script, Helper {

    function run() public {
        vm.startBroadcast();
        

        vm.stopBroadcast();
    }

   function createAssets(uint index) public {
        ConfigMarket memory markets = getConfigMarket(index);
        ConfigFarm memory farms = getConfigFarm(index);
        vaultFactory.createNewMarket(markets.epochFee, markets.token, markets.strikePrice, markets.epochBegin, markets.epochEnd, markets.oracle, markets.name);
        (address rHedge, address rRisk) = rewardsFactory.createStakingRewards(index, farms.epochEnd);
        //sending gov tokens to farms
        y2k.approve(address(rHedge), farms.rewardsAmount);
        y2k.transfer(rHedge, farms.rewardsAmount);
        y2k.approve(address(rRisk), farms.rewardsAmount);
        y2k.transfer(rRisk, farms.rewardsAmount);
        //start rewards for farms
        StakingRewards(rHedge).notifyRewardAmount(y2k.balanceOf(rHedge));
        StakingRewards(rRisk).notifyRewardAmount(y2k.balanceOf(rRisk));
        // stop create market
   }

   function deployMoreAssets(uint index) public {
        ConfigMarket memory markets = getConfigMarket(index);
        ConfigFarm memory farms = getConfigFarm(index);
        vaultFactory.deployMoreAssets(index, markets.epochBegin, markets.epochEnd, markets.epochFee);
        (address rHedge, address rRisk) = rewardsFactory.createStakingRewards(index, markets.epochEnd);
        //sending gov tokens to farms
        y2k.approve(address(rHedge), farms.rewardsAmount);
        y2k.transfer(rHedge, farms.rewardsAmount);
        y2k.approve(address(rRisk), farms.rewardsAmount);
        y2k.transfer(rRisk, farms.rewardsAmount);
        //start rewards for farms
        StakingRewards(rHedge).notifyRewardAmount(y2k.balanceOf(rHedge));
        StakingRewards(rRisk).notifyRewardAmount(y2k.balanceOf(rRisk));
   }

   

}
