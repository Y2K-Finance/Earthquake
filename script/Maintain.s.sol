// SPDX-License-Identifier: MIT
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

    address vf = 0xb597ADcE4adB828e5CAA724a8F4437568FD8bB6c;
    address cl = 0xc359A787B34c71A9d1c89b4d88A362afe10970aB;
    address rf = 0x076d579dc8E204a013e9524942AeAcac1Dd0c62C;
    //address gt = 0x4bd30F77809730E38EE59eE0e8FF008407dD3025;

    uint256 epochEnd = 1662825600;
    uint256 epochBegin = block.timestamp;

    uint256 FEE = 55;
    uint256 nextEpochEnd = epochEnd + 30 minutes;
    uint256 nextEpochBegin = epochBegin + 20 minutes;

    // address tokenUSDC = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;
    // address tokenDAI = 0x4dCf5ac4509888714dd43A5cCc46d7ab389D9c23;

    // address oracleUSDC = 0x5f0423B1a6935dc5596e7A24d98532b67A0AeFd8;
    // address oracleDAI = 0x3e3546c6b5689f7EAa1BA7Bc9571322c3168D786;

    function run() public {
        vm.startBroadcast();
        Controller controller = Controller(cl);
        controller.triggerEndEpoch(1, epochEnd);
        controller.triggerEndEpoch(2, epochEnd);
        controller.triggerEndEpoch(3, epochEnd);
        // controller.triggerDepeg(4, epochEnd);
        // controller.triggerDepeg(5, epochEnd);
        // controller.triggerDepeg(6, epochEnd);
        //GovToken govToken = GovToken(gt);
        //deployMore();

        vm.stopBroadcast();
    }

    function deployMore() public {
        VaultFactory vaultFactory = VaultFactory(vf);
        RewardsFactory rewardsFactory = RewardsFactory(rf);
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
