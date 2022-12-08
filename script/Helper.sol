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
import "./keepers/KeeperDepeg.sol";
import "./keepers/KeeperEndEpoch.sol";

/// @author MiguelBits

contract HelperConfig is Script {
    using stdJson for string;

    struct ConfigVariables{
        uint256 amountOfNewEpochs;
        uint256 amountOfNewMarkets;
        uint256[] epochsIds;
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
        uint256 index;
        string name;
        address oracle;
        int256 strikePrice;
        address token;
    }

    struct ConfigEpochs {
        uint256 epochBegin;
        uint256 epochEnd;
        uint256 epochFee;
        uint256 index;
    }

    struct ConfigFarms {
        string farmRewardsHEDGE;
        string farmRewardsRISK;
        uint index;
    }

    VaultFactory vaultFactory;
    Controller controller;
    RewardsFactory rewardsFactory;
    Y2K y2k;
    KeeperGelatoDepeg keeperDepeg;
    KeeperGelatoEndEpoch keeperEndEpoch;
    ConfigVariables configVariables;
    function setVariables() public {

        uint256[] memory _marketsIds;
        uint256 _amountOfNewMarkets;

        uint256 _amountOfNewEpochs;
        uint256[] memory _epochsIds;

        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/configJSON.json");
        string memory json = vm.readFile(path);
        bytes memory parseJsonByteCode = json.parseRaw(".newMarkets");
        bool _newMarkets = abi.decode(parseJsonByteCode, (bool));
        if(_newMarkets) {
            parseJsonByteCode = json.parseRaw(".amountOfNewMarkets");
            _amountOfNewMarkets = abi.decode(parseJsonByteCode, (uint256));
            parseJsonByteCode = json.parseRaw(".marketsIds");
            _marketsIds = abi.decode(parseJsonByteCode, (uint256[]));
            console2.log("newMarkets", _newMarkets);
            console2.log("amountOfNewMarkets", _amountOfNewMarkets);
            for(uint i = 0; i < _amountOfNewMarkets; i++) {
                console2.log("marketsIds", _marketsIds[i]);
            }
        }

        parseJsonByteCode = json.parseRaw(".newEpochs");
        bool _newEpochs = abi.decode(parseJsonByteCode, (bool));
        if(_newEpochs) {
            parseJsonByteCode = json.parseRaw(".amountOfNewEpochs");
            _amountOfNewEpochs = abi.decode(parseJsonByteCode, (uint256));
            parseJsonByteCode = json.parseRaw(".epochsIds");
            _epochsIds = abi.decode(parseJsonByteCode, (uint256[]));
            console2.log("newEpochs", _newEpochs);
            console2.log("amountOfNewEpochs", _amountOfNewEpochs);
            for(uint i = 0; i < _amountOfNewEpochs; i++) {
                console2.log("epochsIds", _epochsIds[i]);
            }
        }
        bool _newFarms = abi.decode(json.parseRaw(".newFarms"), (bool));

        configVariables = ConfigVariables({
            amountOfNewEpochs: _amountOfNewEpochs,
            amountOfNewMarkets: _amountOfNewMarkets,
            epochsIds: _epochsIds,
            marketsIds: _marketsIds,
            newEpochs: _newEpochs,
            newFarms: _newFarms,
            newMarkets: _newMarkets
        });
    }
    function contractToAddresses(ConfigAddresses memory configAddresses) public {
        vaultFactory = VaultFactory(configAddresses.vaultFactory);
        controller = Controller(configAddresses.controller);
        rewardsFactory = RewardsFactory(configAddresses.rewardsFactory);
        y2k = Y2K(configAddresses.y2k);
        keeperDepeg = KeeperGelatoDepeg(configAddresses.keeperDepeg);
        keeperEndEpoch = KeeperGelatoEndEpoch(configAddresses.keeperEndEpoch);
    }

    function startKeepers(uint _marketIndex, uint _epochEnd) public {
        keeperDepeg.startTask(_marketIndex, _epochEnd);
        keeperEndEpoch.startTask(_marketIndex, _epochEnd);
    }

    function getConfigAddresses() public returns (ConfigAddresses memory) {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/configAddresses.json");
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