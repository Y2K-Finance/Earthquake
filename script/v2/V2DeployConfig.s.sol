// SPDX-License-Identifier;
pragma solidity ^0.8.15;

import "./V2Helper.sol";
import "../../src/v2/interfaces/IConditionProvider.sol";

/// @author Y2K Team
//forge script V2DeployConfig --rpc-url $ARBITRUM_RPC_URL --private-key $PRIVATE_KEY --broadcast --skip-simulation --slow --verify -vv

// whitelist controller 0xC0655f3dace795cc48ea1E2e7BC012c1eec912dC
contract V2DeployConfig is HelperV2 {
    function setupY2K() public {
        setVariables();

        configAddresses = getConfigAddresses(configVariables.isTestEnv); //true if test env
        if (configVariables.isTestEnv) {
            console2.log("THIS IS A TEST ENV DEPLOYMENT");
        } else {
            console2.log("THIS IS A PRODUCTION ENV DEPLOYMENT");
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
        if (configVariables.newMarkets) {
            //deploy new markets
            validateMarkets();
            console2.log(
                "-------------------------DEPLOY MARKETS----------------------"
            );
            deployMarkets();
        }
        if (configVariables.epochs) {
            // IERC20(y2k).approve(address(factory), type(uint256).max);
            //deploy epochs
            validateEpochs();
            console2.log(
                "-------------------------DEPLOY EPOCHS----------------------"
            );
            fundKeepers(2000000000000000);
            deployEpochs();
        }
    }

    function deployMarkets() public {
        ConfigMarketV2[] memory markets = getConfigMarket();
        for (uint256 i = 0; i < markets.length; ++i) {
            ConfigMarketV2 memory market = markets[i];
            address controller = getController(market.isGenericController);
            address depositAsset = getDepositAsset(market.depositAsset);
            uint256 strkePrice = stringToUint(market.strikePrice);
            (address prem, address collat, uint256 marketId) = factory
                .createNewCarouselMarket(
                    CarouselFactory.CarouselMarketConfigurationCalldata(
                        market.token,
                        strkePrice,
                        market.oracle,
                        depositAsset,
                        market.name,
                        market.uri,
                        controller,
                        stringToUint(market.relayFee),
                        market.depositFee,
                        stringToUint(market.minQueueDeposit)
                    )
                );
            console2.log("marketId: ", marketId);
            console2.log("premium address: ", prem);
            console2.log("collateral address: ", collat);
            // console log if loop continues
            if (i < markets.length - 1) {
                console2.log(
                    "-----------------------NEXT MARKETS----------------------"
                );
            }
            // if controller is generic, set depeg condition (depeg 2, repeg 1)
            if (market.isGenericController) {
                setDepegCondition(
                    market.oracle,
                    marketId,
                    market.isDepeg
                );
            }
            console2.log("\n");
        }
    }

    function validateMarkets() public {
        ConfigMarketV2[] memory markets = getConfigMarket();

        if (markets.length != configVariables.amountOfNewMarkets) {
            console.log("markets.length", markets.length);
            console.log(
                "configVariables.amountOfNewMarkets",
                configVariables.amountOfNewMarkets
            );
            revert("markets.length != configVariables.amountOfNewMarkets");
        }
        for (uint256 i = 0; i < markets.length; ++i) {
            ConfigMarketV2 memory market = markets[i];
            address controller = getController(market.isGenericController);
            address depositAsset = getDepositAsset(market.depositAsset);
            uint256 strkePrice = stringToUint(market.strikePrice);
            if (!factory.controllers(controller)) {
                console2.log("Controller not whitelisted", controller);
                revert("Controller not whitelisted");
            }
            uint256 previewMarketID = factory.getMarketId(
                market.token,
                strkePrice,
                depositAsset
            );
            address vault = factory.marketIdToVaults(previewMarketID, 0);
            if (vault != address(0)) {
                console2.log("Market already deployed", previewMarketID);
                console2.log(
                    "Market: ",
                    market.token,
                    strkePrice,
                    depositAsset
                );
                revert("Market already deployed");
            }
        }
    }

    function setDepegCondition(
        address _oracle,
        uint256 _marketId,
        bool _isDepegCondition
    ) public {
        if (_isDepegCondition) {
            console2.log("Set depeg condition");
            IConditionProvider(_oracle).setConditionType(_marketId, 2);
        } else {
            console2.log("Set repeg condition");
            IConditionProvider(_oracle).setConditionType(_marketId, 1);
        }
    }

    function deployEpochs() public {
        // ConfigAddressesV2 memory addresses = getConfigAddresses(false);
        ConfigEpochWithEmission[] memory epochs = getConfigEpochs();
        for (uint256 i = 0; i < epochs.length; ++i) {
            ConfigEpochWithEmission memory epoch = epochs[i];
            address depositAsset = getDepositAsset(epoch.depositAsset);
            uint256 strikePrice = stringToUint(epoch.strikePrice);
            uint256 marketId = factory.getMarketId(
                epoch.token,
                strikePrice,
                depositAsset
            );

            (uint256 epochId, address[2] memory vaults) = CarouselFactory(
                factory
            ).createEpochWithEmissions(
                    marketId,
                    epoch.epochBegin,
                    epoch.epochEnd,
                    500,
                    stringToUint(epoch.premiumEmissions),
                    stringToUint(epoch.collatEmissions)
                );

            if (isTestEnv) {
                // IERC20(configAddresses.weth).approve(vaults[0], 1 ether);
                // ICarousel(vaults[0]).deposit(
                //     0,
                //     1 ether,
                //     0xCCA23C05a9Cf7e78830F3fd55b1e8CfCCbc5E50F
                // );
                // IERC20(configAddresses.weth).approve(vaults[1], 1 ether);
                // ICarousel(vaults[1]).deposit(
                //     0,
                //     1 ether,
                //     0xCCA23C05a9Cf7e78830F3fd55b1e8CfCCbc5E50F
                // );
            }

            console.log("marketName: ", epoch.name);
            console2.log("epochId: ", epochId);
            console2.log("marketId: ", marketId);

            deployKeeper(marketId, epochId, vaults, epoch);

            console2.log("\n");
        }
    }

    function validateEpochs() public {
        ConfigEpochWithEmission[] memory epochs = getConfigEpochs();
        if (
            IERC20(y2k).allowance(configAddresses.policy, address(factory)) <
            configVariables.totalAmountOfEmittedTokens
        ) {
            console2.log(
                "Not enough allowance",
                IERC20(y2k).allowance(address(this), address(factory))
            );
            revert("Not enough allowance");
        }
        if (epochs.length != configVariables.amountOfNewEpochs) {
            console.log("epochs.length", epochs.length);
            console.log(
                "configVariables.amountOfNewEpochs",
                configVariables.amountOfNewEpochs
            );
            revert("epochs.length != configVariables.amountOfNewEpochs");
        }
        for (uint256 i = 0; i < epochs.length; ++i) {
            ConfigEpochWithEmission memory epoch = epochs[i];
            address depositAsset = getDepositAsset(epoch.depositAsset);
            uint256 strikePrice = stringToUint(epoch.strikePrice);
            uint256 previewMarketID = factory.getMarketId(
                epoch.token,
                strikePrice,
                depositAsset
            );
            address vault = factory.marketIdToVaults(previewMarketID, 0);
            if (vault == address(0)) {
                console2.log(
                    "Market not deployed",
                    epoch.token,
                    strikePrice,
                    depositAsset
                );
                revert("Market not deployed");
            }
            if (epoch.epochBegin < block.timestamp) {
                console2.log("Epoch begin in the past");
                revert("Epoch begin in the past");
            }
            if (epoch.epochEnd < block.timestamp) {
                console2.log("Epoch end in the past");
                revert("Epoch end in the past");
            }
        }
    }

    function deployKeeper(
        uint256 marketId,
        uint256 epochId,
        address[2] memory vaults,
        ConfigEpochWithEmission memory epoch
    ) public {
        // checks
        if (
            ICarousel(vaults[0]).emissions(epochId) !=
            stringToUint(epoch.premiumEmissions)
        ) {
            console2.log("Premium emissions not set");
            revert("Premium emissions error");
        }
        if (
            ICarousel(vaults[1]).emissions(epochId) !=
            stringToUint(epoch.collatEmissions)
        ) {
            console2.log("Collat emissions not set");
            revert("Collat emissions error");
        }

        (uint40 epochBegin, uint40 epochEnd, uint40 epochCreation) = ICarousel(
            vaults[0]
        ).getEpochConfig(epochId);
        if (epochBegin != epoch.epochBegin) {
            console2.log("Epoch begin not set");
            revert("Epoch begin error");
        }
        if (epochEnd != epoch.epochEnd) {
            console2.log("Epoch end not set");
            revert("Epoch end error");
        }

        // deploy rollover and resolve keeper
        startKeepers(marketId, epochId, epoch.isGenericController);

        console2.log("------------------------KEEPER DETAILS----------------------");

        console2.log("Resolve Keeper taskId: ");
        console2.logBytes32(
            KeeperV2(configAddresses.rolloverKeeper).tasks(
                keccak256(abi.encodePacked(marketId, epochId))
            )
        );
        console2.log("Rollover Keeper taskId: ");
        console.logBytes32(
            KeeperV2(configAddresses.rolloverKeeper).tasks(
                keccak256(abi.encodePacked(marketId, epochId))
            )
        );
        console2.log(
            "-----------------------------------------------------------"
        );
    }
}
