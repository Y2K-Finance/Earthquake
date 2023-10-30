// SPDX-License-Identifier;
pragma solidity ^0.8.15;

import "./V2Helper.sol";
import "../../src/v2/interfaces/IConditionProvider.sol";
import "../../src/v2/Controllers/ControllerGeneric.sol";

/// @author Y2K Team
//forge script V2DeployFarms --rpc-url $ARBITRUM_RPC_URL --private-key $PRIVATE_KEY --broadcast --skip-simulation --slow --verify -vv

// whitelist controller 0xC0655f3dace795cc48ea1E2e7BC012c1eec912dC
contract V2DeployFarms is HelperV2 {
    function setupY2K() public {
        setVariables();

        configAddresses = getConfigAddresses(configVariables.isTestEnv); //true if test env
        if (configVariables.isTestEnv) {
            console2.log("THIS IS A TEST ENV DEPLOYMENT");
        } else {
            console2.log("THIS IS A PRODUCTION ENV DEPLOYMENT");
            // revert("THIS IS A PRODUCTION ENV DEPLOYMENT");
        }

        console.log("Deployer", msg.sender);
        console.log(
            "Address arbitrum_sequencer",
            configAddresses.arbitrum_sequencer
        );
        console.log("Address Factory", configAddresses.carouselFactory);
        contractToAddresses(configAddresses);
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
    CarouselFactory localFactory = CarouselFactory(configAddresses.carouselFactory);
    ConfigEpochWithEmission[] memory epochs = getConfigEpochs();
     for (uint256 i = 0; i < epochs.length; ++i) {
            ConfigEpochWithEmission memory epoch = epochs[i];

            address depositAsset = getDepositAsset(epoch.depositAsset);
            uint256 strikePrice = stringToUint(epoch.strikePrice);
            uint40 epochEnd = epoch.epochEnd;
            uint40 epochBegin = epoch.epochBegin;

            uint256 marketId = localFactory.getMarketId(
                epoch.token,
                strikePrice,
                depositAsset
            );

            uint256 epochId = localFactory.getEpochId(
                marketId,
                epochBegin,
                epochEnd
            );

            string memory marketName = epoch.name;

            address[2] memory vaults = localFactory.getVaults(marketId);
            // address collateral = vaults[1];
            // address premium = vaults[0];

            if(vaults[1] == address(0) || vaults[0] == address(0)) {
                console.log("collateral", vaults[1]);
                console.log("premium", vaults[0]);
                console.log("marketName", marketName);
                revert("vaults are not set");
            }
            
            StakingRewards collateralFarm = new StakingRewards(
                    msg.sender,
                    msg.sender,
                    configAddresses.y2k,
                    vaults[1],
                    epochId,
                    epochEnd,
                    string.concat("y2kCollateralFarm", marketName),
                    "y2kFarmC"
            );

            StakingRewards premiumFarm = new StakingRewards(
                    msg.sender,
                    msg.sender,
                    configAddresses.y2k,
                    vaults[0],
                    epochId,
                    epochEnd,
                    string.concat("y2kPremiumFarm", marketName),
                    "y2kFarmP"
            );                

            IERC20(configAddresses.y2k).transfer(address(collateralFarm), stringToUint(epoch.collatEmissions));
            IERC20(configAddresses.y2k).transfer(address(premiumFarm), stringToUint(epoch.premiumEmissions));
            
            //start rewards for farms
            collateralFarm.notifyRewardAmount(
                  stringToUint(epoch.collatEmissions)   
            );
            premiumFarm.notifyRewardAmount(
                 stringToUint(epoch.premiumEmissions)
            );

            // IERC20(configAddresses.y2k).transfer(address(collateralFarm),  1 ether);
            // IERC20(configAddresses.y2k).transfer(address(premiumFarm),  2 ether);
            
            // collateralFarm.notifyRewardAmount(
            //     1 ether
            // );
            // premiumFarm.notifyRewardAmount(
            //     2 ether
            // );

            console2.log(address(collateralFarm));
            console2.log(address(premiumFarm));
        }
    
    // address[] memory addressArray = new address[2];
    // addressArray[0] = address(collateralFarm);
    // addressArray[1] = address(premiumFarm);
    // loop over addressArray

    // for(uint i = 0; i < addressArray.length; i++) {
    //     // do something with addressArray[i]
    //     console.log("addressArray[i]", addressArray[i]);

    //     string memory jsonPointer = string.concat(".farms", "[", Strings.toString(i), "]");
    //     string memory addressAsString =Strings.toHexString(uint256(uint160(addressArray[i])), 20);
    //     vm.writeJson(addressAsString, "./output/farmAddresses.json", jsonPointer);
    // }

    }

}
