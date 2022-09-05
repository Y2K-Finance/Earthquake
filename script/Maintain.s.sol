// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/VaultFactory.sol";
import "../src/Controller.sol";
import "../src/rewards/RewardsFactory.sol";
import "../test/GovToken.sol";
import "../test/oracles/DepegOracle.sol";

/*
forge script script/Maintain.s.sol:MaintainScript --rpc-url $ARBITRUM_RINKEBY_RPC_URL  --private-key $PRIVATE_KEY --broadcast -vv

Controller address 0xE3790E0bc21F43868A2527a999A9a11c807AD659
Vault Factory address 0xAD78ccB7F26CAECf09406a0541012330874A8466
Rewards Factory address 0x2c4C123b87Ee0019F830c4AB30118c8f53cD2b9F
GovToken address 0x4bd30F77809730E38EE59eE0e8FF008407dD3025
*/
contract MaintainScript is Script {

    address vf = 0xAD78ccB7F26CAECf09406a0541012330874A8466;
    //address cl = 0xE3790E0bc21F43868A2527a999A9a11c807AD659;
    address rf = 0x2c4C123b87Ee0019F830c4AB30118c8f53cD2b9F;
    //address gt = 0x4bd30F77809730E38EE59eE0e8FF008407dD3025;

    uint256 epochEnd = block.timestamp + 1 hours + 20 minutes;
    uint256 epochBegin = block.timestamp + 1 hours;

    uint256 FEE = 55;
    uint256 nextEpochEnd = epochEnd + 1 hours;
    uint256 nextEpochBegin = epochBegin + 1 hours;

    address tokenUSDC = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;
    address tokenDAI = 0x4dCf5ac4509888714dd43A5cCc46d7ab389D9c23;

    address oracleUSDC = 0x5f0423B1a6935dc5596e7A24d98532b67A0AeFd8;
    address oracleDAI = 0x3e3546c6b5689f7EAa1BA7Bc9571322c3168D786;

    function run() public {

        VaultFactory vaultFactory = VaultFactory(vf);
        //Controller controller = Controller(cl);
        RewardsFactory rewardsFactory = RewardsFactory(rf);
        //GovToken govToken = GovToken(gt);
        
        console2.log("Market index", vaultFactory.marketIndex());

        //USDC
        vaultFactory.deployMoreAssets(1, epochBegin, epochEnd, FEE);
        rewardsFactory.createStakingRewards(1, epochEnd);

        vaultFactory.deployMoreAssets(2, epochBegin, epochEnd, FEE);
        rewardsFactory.createStakingRewards(2, epochEnd);

        vaultFactory.deployMoreAssets(3, epochBegin, epochEnd, FEE);
        rewardsFactory.createStakingRewards(3, epochEnd);

        //DAI
        vaultFactory.deployMoreAssets(4, epochBegin, epochEnd, FEE);
        rewardsFactory.createStakingRewards(4, epochEnd);

        vaultFactory.deployMoreAssets(5, epochBegin, epochEnd, FEE);
        rewardsFactory.createStakingRewards(5, epochEnd);

        vaultFactory.deployMoreAssets(6, epochBegin, epochEnd, FEE);
        rewardsFactory.createStakingRewards(6, epochEnd);

    }

}
