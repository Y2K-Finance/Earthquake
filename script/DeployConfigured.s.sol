// SPDX-License-Identifier;
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";
import "../src/VaultFactory.sol";
import "../src/Controller.sol";
import "../src/rewards/RewardsFactory.sol";
import "../test/GovToken.sol";
/// @author MiguelBits

contract ConfigScript is Script {
    using stdJson for string;

    struct ConfigAddresses {
        address admin;
        address arbitrum_sequencer;
        address oracleDAI;
        address oracleFEI;
        address oracleFrax;
        address oracleMIM;
        address oracleUSDC;
        address oracleUSDT;
        address policy;
        address tokenDAI;
        address tokenFEI;
        address tokenFrax;
        address tokenMIM;
        address tokenUSDC;
        address tokenUSDT;
        address treasury;
        address weth;
    }

    function run() public {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/configAddresses.json");
        string memory json = vm.readFile(path);
        bytes memory transactionDetails = json.parseRaw(".configAddresses[0]");
        ConfigAddresses memory rawConstants = abi.decode(transactionDetails, (ConfigAddresses));
        console2.log("ConfigAddresses ", rawConstants.weth);
    }

}