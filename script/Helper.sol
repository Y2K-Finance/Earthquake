// SPDX-License-Identifier;
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../src/VaultFactory.sol";
import "../src/Controller.sol";
import "../src/rewards/RewardsFactory.sol";
import "../test/Y2Ktest.sol";
/// @author MiguelBits

//forge script ConfigScript --rpc-url $ARBITRUM_RPC_URL  --private-key $PRIVATE_KEY --broadcast -vv
contract Helper is Script {
    using stdJson for string;

    VaultFactory vaultFactory;
    Controller controller;
    RewardsFactory rewardsFactory;
    Y2K y2k;


    struct ConfigAddresses {
        address admin;
        address arbitrum_sequencer;
        address oracleDAI;
        address oracleFEI;
        address oracleFRAX;
        address oracleMIM;
        address oracleUSDC;
        address oracleUSDT;
        address policy;
        address tokenDAI;
        address tokenFEI;
        address tokenFRAX;
        address tokenMIM;
        address tokenUSDC;
        address tokenUSDT;
        address treasury;
        address weth;
    }

    struct ConfigMarket {
        uint256 epochBegin;
        uint256 epochEnd;
        uint256 epochFee;
        string name;
        address oracle;
        int256 strikePrice;
        address token;
    }

    struct ConfigFarm {
        uint256 epochEnd;
        uint256 rewardsAmount;
    }

    function getConfigAddresses() public returns (ConfigAddresses memory) {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/configAddresses.json");
        string memory json = vm.readFile(path);
        bytes memory transactionDetails = json.parseRaw(".configAddresses[0]");
        ConfigAddresses memory rawConstants = abi.decode(transactionDetails, (ConfigAddresses));
        //console2.log("ConfigAddresses ", rawConstants.weth);
        return rawConstants;
    }

    function getConfigMarket(uint256 index) public returns (ConfigMarket memory) {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/configMarkets.json");
        string memory json = vm.readFile(path);
        string memory indexString = string.concat(".",Strings.toString(index), "[0]");
        bytes memory transactionDetails = json.parseRaw(indexString);
        ConfigMarket memory rawConstants = abi.decode(transactionDetails, (ConfigMarket));
        //console2.log("ConfigMarkets ", rawConstants.name);
        return rawConstants;
    }

    function getConfigFarm(uint256 index) public returns (ConfigFarm memory) {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/configFarms.json");
        string memory json = vm.readFile(path);
        string memory indexString = string.concat(".",Strings.toString(index), "[0]");
        bytes memory transactionDetails = json.parseRaw(indexString);
        ConfigFarm memory rawConstants = abi.decode(transactionDetails, (ConfigFarm));
        //console2.log("ConfigFarms ", rawConstants.rewardsAmount);
        return rawConstants;
    }
}