// SPDX-License-Identifier;
pragma solidity ^0.8.13;

import "./Helper.sol";

/// @author MiguelBits
//forge script ConfigScript --rpc-url $ARBITRUM_RPC_URL --private-key $PRIVATE_KEY --broadcast --skip-simulation --gas-estimate-multiplier 200 --slow -vv
contract ConfigScript is Script, HelperConfig {

    function run() public {
        //LOAD json config and check bool deploy new markets
        //if true deploy new markets
        ConfigAddresses memory addresses = getConfigAddresses();
        contractToAddresses(addresses);

        vm.startBroadcast();

        deployMarkets(addresses);

        vm.stopBroadcast();
    }

    function deployMarkets() public {
        // vaultFactory.createNewMarket(_withdrawalFee, _token, _strikePrice, epochBegin, epochEnd, _oracle, _name);
    }

}