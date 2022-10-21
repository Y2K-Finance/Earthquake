// SPDX-License-Identifier;
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";
import "../src/VaultFactory.sol";
import "../src/Controller.sol";
//TODO change this after deploy  y2k token
import "../src/rewards/PausableRewardsFactory.sol";
import "../test/Y2Ktest.sol";
import "../test/fakeWeth.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./keepers/Keeper.sol";

/// @author MiguelBits

//forge script ConfigScript --rpc-url $ARBITRUM_RPC_URL --private-key $PRIVATE_KEY --broadcast --etherscan-api-key $arbiscanApiKey --verify --skip-simulation --gas-estimate-multiplier 200 --slow -vv

contract ConfigScript is Script {
    using stdJson for string;

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
        uint256 rewardsAmount;
    }

    VaultFactory vaultFactory;
    Controller controller;
    RewardsFactory rewardsFactory;
    Y2K y2k;
    WETH fakeWeth;

    function run() public {

        ConfigAddresses memory addresses = getConfigAddresses();
        console2.log("Address admin", addresses.admin);
        console2.log("Address arbitrum_sequencer", addresses.arbitrum_sequencer);
        console2.log("Address oracleDAI", addresses.oracleDAI);
        console2.log("Address oracleFEI", addresses.oracleFEI);
        console2.log("Address oracleFRAX", addresses.oracleFRAX);
        console2.log("Address oracleMIM", addresses.oracleMIM);
        console2.log("Address oracleUSDC", addresses.oracleUSDC);
        console2.log("Address oracleUSDT", addresses.oracleUSDT);
        console2.log("Address policy", addresses.policy);
        console2.log("Address tokenDAI", addresses.tokenDAI);
        console2.log("Address tokenFEI", addresses.tokenFEI);
        console2.log("Address tokenFRAX", addresses.tokenFRAX);
        console2.log("Address tokenMIM", addresses.tokenMIM);
        console2.log("Address tokenUSDC", addresses.tokenUSDC);
        console2.log("Address tokenUSDT", addresses.tokenUSDT);
        console2.log("Address treasury", addresses.treasury);
        console2.log("Address weth", addresses.weth);
        console2.log("\n");

        vm.startBroadcast();

        console2.log("Broadcast sender", msg.sender);
        console2.log("Broadcast admin ", addresses.admin);
        console2.log("Broadcast policy", addresses.policy);
        //start setUp();
        fakeWeth = new WETH();
        vaultFactory = new VaultFactory(addresses.treasury, address(fakeWeth), addresses.policy);
        controller = new Controller(address(vaultFactory), addresses.arbitrum_sequencer);

        vaultFactory.setController(address(controller));

        y2k = new Y2K(5000 ether, msg.sender);

        rewardsFactory = new RewardsFactory(address(y2k), address(vaultFactory));
        //keeper creation
        KeeperGelato keeper = new KeeperGelato(payable(0xB3f5503f93d5Ef84b06993a1975B9D21B962892F), 
        payable(0xB2f34fd4C16e656163dADFeEaE4Ae0c1F13b140A), 
        address(controller));

        //stop setUp();
                        
        console2.log("Controller address", address(controller));
        console2.log("Vault Factory address", address(vaultFactory));
        console2.log("Rewards Factory address", address(rewardsFactory));
        console2.log("Y2K token address", address(y2k));
        console2.log("Keeper address", address(keeper));
        console2.log("WETH address", address(fakeWeth));
        console2.log("\n");

        //transfer ownership
        //vaultFactory.transferOwnership(addresses.admin);
        y2k.transfer(0x16cBaDA408F7523452fF91c8387b1784d00d10D8, 50 ether);

        vm.stopBroadcast();
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