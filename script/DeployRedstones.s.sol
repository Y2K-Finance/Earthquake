// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./RedstonePriceProvider.sol";
import "./HelperConfig.sol";

contract DeployAndTestRedstone is HelperConfig {
    RedstonePriceProvider public priceProvider;

    function setup() internal {
        // Initialize configuration using HelperConfig functions
        ConfigAddresses memory configAddresses = getConfigAddresses(false);
        contractToAddresses(configAddresses);
    }

    function deploy() internal {
        // Initialize variables
        address sequencerAddress = address(0);
        address factoryAddress = address(0);

        // Deploy RedstonePriceProvider contract
        priceProvider = new RedstonePriceProvider(sequencerAddress, factoryAddress);
    }

    function test() internal {
        // Invoke the Node.js script
        // somehow vm.execute("InvokeNodeScript");


        uint256 vstPrice = evmConnector.getLatestPrice(address(priceProvider), address(0));

        // Output the fetched price
        emit Log("Fetched vstPrice \", vstPrice);
    }

    function run() public {
        setup();
        deploy();
        test();
    }
}
