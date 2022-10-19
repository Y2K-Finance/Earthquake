// SPDX-License-Identifier;
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";
import "../src/VaultFactory.sol";
import "../src/Controller.sol";
import "../src/rewards/RewardsFactory.sol";
import "../test/Y2Ktest.sol";
import "../test/fakeWeth.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @author MiguelBits
//forge script ConfigScript --rpc-url $ARBITRUM_RPC_URL --private-key $PRIVATE_KEY --broadcast --skip-simulation --gas-estimate-multiplier 200 --slow -vv
contract ConfigMarketsScript is Script {
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

    VaultFactory vaultFactory = VaultFactory(0x3DcF49D27388E4BCF7AE74D75AFA987034Bd7ce0);
    Controller controller = Controller(0x77fe110716E6B5D1904C7E3d1C49aB3C58Ef678B);
    RewardsFactory rewardsFactory = RewardsFactory(0x9dC6821AE74FaAE71Dfd1016f14eAdcA7823Faf4);
    Y2K y2k = Y2K(0x4070a276F99A4A38E0b3046183fEc8F33923716e);

    uint index = 3;

    function run() public {
        vm.startBroadcast();

        ConfigAddresses memory addresses = getConfigAddresses();
        ConfigMarket memory markets = getConfigMarket(index);
        ConfigFarm memory farms = getConfigFarm(index);

        //INDEX
        //get markets config
        console2.log("Market index", index);
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

    function getConfigMarket(uint256 _index) public returns (ConfigMarket memory) {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/configMarkets.json");
        string memory json = vm.readFile(path);
        string memory indexString = string.concat(".",Strings.toString(_index), "[0]");
        bytes memory transactionDetails = json.parseRaw(indexString);
        ConfigMarket memory rawConstants = abi.decode(transactionDetails, (ConfigMarket));
        //console2.log("ConfigMarkets ", rawConstants.name);
        return rawConstants;
    }

    function getConfigFarm(uint256 _index) public returns (ConfigFarm memory) {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/configFarms.json");
        string memory json = vm.readFile(path);
        string memory indexString = string.concat(".",Strings.toString(_index), "[0]");
        bytes memory transactionDetails = json.parseRaw(indexString);
        ConfigFarm memory rawConstants = abi.decode(transactionDetails, (ConfigFarm));
        //console2.log("ConfigFarms ", rawConstants.rewardsAmount);
        return rawConstants;
    }
}