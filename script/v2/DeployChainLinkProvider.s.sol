pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "forge-std/console2.sol";

import {ChainlinkPriceProvider} from "../../src/v2/oracles/individual/ChainlinkPriceProvider.sol";


//forge script script/v2/DeployChainLinkProvider.s.sol --rpc-url https://arb-sepolia.g.alchemy.com/v2/SA1EqG4RW6GcciKBnPtu8n6OJqxy164t
contract DeployChainLinkProvider is Script {
    function run() public {

        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        //arbitrum main net
        address arbitrumSequencer = 0xFdB631F5EE196F0ed6FAa767959853A9F217697D;
        //address priceFeed = 0x0a32255dd4BB6177C994bAAc73E0606fDD568f66;
        address factory = 0x442Fd67F2CcF92eD73E7B7E4ff435835EcA890C9;
        
        //sepolia
        address priceFeed = 0xD1092a65338d049DB68D7Be6bD89d17a0929945e;

        uint256 timeOut = 12 hours;

        ChainlinkPriceProvider chainlinkPriceProvider =
            new ChainlinkPriceProvider(arbitrumSequencer, factory, priceFeed, timeOut);
        console2.log(
            "Chainlink Price Provider",
            address(chainlinkPriceProvider)
        );
    }
}