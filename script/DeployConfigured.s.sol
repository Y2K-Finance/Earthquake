// SPDX-License-Identifier;
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";
import "../src/VaultFactory.sol";
import "../src/Controller.sol";
//TODO change this after deploy  y2k token
import "../src/rewards/PausableRewardsFactory.sol";
import "../src/tokens/Y2K.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @author MiguelBits

//forge script ConfigScript --rpc-url $ARBITRUM_RPC_URL --private-key $PRIVATE_KEY --broadcast --etherscan-api-key $arbiscanApiKey --verify --skip-simulation --gas-estimate-multiplier 200 --slow -vv

contract ConfigScript is Script {
    using stdJson for string;

    uint totalSupplied = 1000000000000000000000000000;

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

        vaultFactory = new VaultFactory(addresses.treasury, addresses.weth, addresses.policy);
        controller = new Controller(address(vaultFactory), addresses.arbitrum_sequencer);

        vaultFactory.setController(address(controller));

        y2k = new Y2K(totalSupplied, msg.sender);

        rewardsFactory = new RewardsFactory(address(y2k), address(vaultFactory));
        //stop setUp();
                        
        console2.log("Controller address", address(controller));
        console2.log("Vault Factory address", address(vaultFactory));
        console2.log("Rewards Factory address", address(rewardsFactory));
        console2.log("Y2K token address", address(y2k));
        console2.log("\n");
        //INDEX 1
        //get markets config
        uint index = 1;
        ConfigMarket memory markets = getConfigMarket(index);
        ConfigFarm memory farms = getConfigFarm(index);
        console2.log("Market name", markets.name);
        console2.log("Adress token", addresses.tokenFRAX);
        console2.log("Market token", markets.token);
        console2.log("Adress oracle", addresses.oracleFRAX);
        console2.log("Market oracle", markets.oracle);
        console2.log("Market strike price", uint256(markets.strikePrice));
        console2.log("Market epoch begin", markets.epochBegin);
        console2.log("Market epoch   end", markets.epochEnd);
        console2.log("Market epoch fee", markets.epochFee);
        console2.log("Farm rewards amount", farms.rewardsAmount);
        //console2.log("Sender balance amnt", y2k.balanceOf(msg.sender));
        console2.log("\n");
        // create market 
        vaultFactory.createNewMarket(markets.epochFee, markets.token, markets.strikePrice, markets.epochBegin, markets.epochEnd, markets.oracle, markets.name);
        (address rHedge, address rRisk) = rewardsFactory.createStakingRewards(index, markets.epochEnd);
        //sending gov tokens to farms
        y2k.transfer(rHedge, farms.rewardsAmount);
        y2k.transfer(rRisk, farms.rewardsAmount);
        //start rewards for farms
        StakingRewards(rHedge).notifyRewardAmount(y2k.balanceOf(rHedge));
        StakingRewards(rRisk).notifyRewardAmount(y2k.balanceOf(rRisk));
        // stop create market

        //transfer ownership
        vaultFactory.transferOwnership(addresses.admin);

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