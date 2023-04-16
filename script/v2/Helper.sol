// SPDX-License-Identifier;
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";
import "forge-std/Test.sol";
//TODO change this after deploy  y2k token
import "@openzeppelin/contracts/utils/Strings.sol";
// import "../keepers/KeeperDepeg.sol";
// import "../keepers/KeeperEndEpoch.sol";

/// @author MiguelBits

contract HelperV2 is Script {
    using stdJson for string;

    struct ConfigVariables{
        uint256 amountOfNewEpochs;
        uint256 amountOfNewFarms;
        uint256 amountOfNewMarkets;
        uint256[] epochsIds;
        uint256[] farmsIds;
        uint256[] marketsIds;
        bool newEpochs;
        bool newFarms;
        bool newMarkets;
    }
    struct ConfigAddresses {
        address admin;
        address arbitrum_sequencer;
        address controller;
        address gelatoOpsV2;
        address gelatoTaskTreasury;
        address keeperDepeg;
        address keeperEndEpoch;
        address oracleDAI;
        address oracleFEI;
        address oracleFRAX;
        address oracleMIM;
        address oracleUSDC;
        address oracleUSDT;
        address policy;
        address rewardsFactory;
        address tokenDAI;
        address tokenFEI;
        address tokenFRAX;
        address tokenMIM;
        address tokenUSDC;
        address tokenUSDT;
        address treasury;
        address vaultFactory;
        address weth;
        address y2k;
    }

    struct ConfigMarket {
        uint256 marketId;
        string name;
        address oracle;
        int256 strikePrice;
        address token;
    }

    struct ConfigEpochs {
        uint256 epochBegin;
        uint256 epochEnd;
        uint256 epochFee;
        uint256 marketId;
    }

    struct ConfigFarms {
        uint256 epochEnd;
        string farmRewardsHEDGE;
        string farmRewardsRISK;
        uint marketId;
    }



    ConfigVariables configVariables;

    function setVariables() public {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/configJSON.json");
        string memory json = vm.readFile(path);
        bytes memory parseJsonByteCode = json.parseRaw(".variables");
        configVariables = abi.decode(parseJsonByteCode, (ConfigVariables));
        // console2.log("ConfigVariables ", rawConstants.amountOfNewMarkets);
    }

    // function contractToAddresses(ConfigAddresses memory configAddresses) public {
    //     vaultFactory = VaultFactory(configAddresses.vaultFactory);
    //     controller = Controller(configAddresses.controller);
    //     rewardsFactory = RewardsFactory(configAddresses.rewardsFactory);
    //     y2k = Y2K(configAddresses.y2k);
    //     keeperDepeg = KeeperGelatoDepeg(configAddresses.keeperDepeg);
    //     keeperEndEpoch = KeeperGelatoEndEpoch(configAddresses.keeperEndEpoch);
    // }

    // function startKeepers(uint _marketIndex, uint _epochEnd) public {
    //     keeperDepeg.startTask(_marketIndex, _epochEnd);
    //     keeperEndEpoch.startTask(_marketIndex, _epochEnd);
    // }

    function getConfigAddresses(bool isTestEnv) public returns (ConfigAddresses memory) {
        string memory root = vm.projectRoot();
        string memory path;
        if(isTestEnv){
            path = string.concat(root, "/configTestEnv.json");
        }
        else{
            path = string.concat(root, "/configAddresses.json");
        }
        string memory json = vm.readFile(path);
        bytes memory parseJsonByteCode = json.parseRaw(".configAddresses[0]");
        ConfigAddresses memory rawConstants = abi.decode(parseJsonByteCode, (ConfigAddresses));
        //console2.log("ConfigAddresses ", rawConstants.weth);
        return rawConstants;
    }
    
    function getConfigMarket(uint256 index) public returns (ConfigMarket memory) {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/configJSON.json");
        string memory json = vm.readFile(path);
        string memory indexString = string.concat(".markets", "[", Strings.toString(index), "]");
        bytes memory transactionDetails = json.parseRaw(indexString);
        ConfigMarket memory rawConstants = abi.decode(transactionDetails, (ConfigMarket));
        //console2.log("ConfigMarkets ", rawConstants.name);
        return rawConstants;
    }

    function getConfigEpochs(uint256 index) public returns (ConfigEpochs memory) {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/configJSON.json");
        string memory json = vm.readFile(path);
        string memory indexString = string.concat(".epochs", "[", Strings.toString(index), "]");
        bytes memory transactionDetails = json.parseRaw(indexString);
        ConfigEpochs memory rawConstants = abi.decode(transactionDetails, (ConfigEpochs));
        //console2.log("ConfigEpochs ", rawConstants.name);
        return rawConstants;
    }

    function getConfigFarms(uint256 index) public returns (ConfigFarms memory) {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/configJSON.json");
        string memory json = vm.readFile(path);
        string memory indexString = string.concat(".farms", "[", Strings.toString(index), "]");
        bytes memory transactionDetails = json.parseRaw(indexString);
        ConfigFarms memory rawConstants = abi.decode(transactionDetails, (ConfigFarms));
        //console2.log("ConfigEpochs ", rawConstants.name);
        return rawConstants;
    }

    function verifyConfig(ConfigMarket memory marketConstants) public view {
        // require(marketConstants.epochBegin < marketConstants.epochEnd, "epochBegin is not < epochEnd");
        // require(marketConstants.epochEnd > block.timestamp, "epochEnd in the past");
        // require(marketConstants.strikePrice > 900000000000000000, "strikePrice is not above 0.90");
        // require(marketConstants.strikePrice < 1000000000000000000, "strikePrice is not below 1.00");
        // //TODO add more checks
    }

    function verifyConfig(ConfigMarket memory marketConstants, ConfigEpochs memory epochConstants) public view {
        // require(epochConstants.epochBegin > marketConstants.epochEnd, "epochBegin is not > marketEnd");
        // require(epochConstants.epochBegin < epochConstants.epochEnd, "epochBegin is not < epochEnd");
        // require(epochConstants.epochEnd > block.timestamp, "epochEnd in the past");
        // //TODO add more checks

    }

    function stringToUint(string memory s) public pure returns (uint) {
        bytes memory b = bytes(s);
        uint result = 0;
        for (uint256 i = 0; i < b.length; i++) {
            uint256 c = uint256(uint8(b[i]));
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
        return result;
    }

}