// SPDX-License-Identifier;
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";
import "forge-std/Test.sol";
//TODO change this after deploy  y2k token
import "@openzeppelin/contracts/utils/Strings.sol";
import "../../src/v2/Carousel/CarouselFactory.sol";
import "../../src/v2/Controllers/ControllerPeggedAssetV2.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../keepers/KeeperV2.sol";
import "../keepers/KeeperV2Rollover.sol";

/// @author MiguelBits

contract HelperV2 is Script {
    using stdJson for string;

    // @note structs that reflect JSON need to have keys in alphabetical order!!!
    struct ConfigAddressesV2 {
        address admin;
        address arbitrum_sequencer;
        address carouselFactory;
        address gelatoOpsV2;
        address gelatoTaskTreasury;
        address policy;
        address resolveKeeper;
        address rolloverKeeper;
        address treasury;
        address weth;
        address y2k;
    }

    struct ConfigEpochWithEmission {
        string collatEmissions;
        address depositAsset;
        uint40 epochBegin;
        uint40 epochEnd;
        string name;
        string premiumEmissions;
        uint256 strikePrice;
        address token;
        uint16 withdrawalFee;
    }

    struct ConfigMarketV2 {
        address controller;
        address depositAsset;
        uint256 depositFee;
        string minQueueDeposit;
        string name;
        address oracle;
        string relayFee;
        uint256 strikePrice;
        address token;
        string uri;
    }

    struct ConfigVariablesV2 {
        uint256 amountOfNewEpochs;
        uint256 amountOfNewMarkets;
        bool epochs;
        bool newMarkets;
        uint256 totalAmountOfEmittedTokens;
    }

    address y2k;
    ConfigVariablesV2 configVariables;
    ConfigAddressesV2 configAddresses;
    bool isTestEnv;

    function setVariables() public {
        string memory root = vm.projectRoot();
        // TODO: Set the variables correctly
        string memory path = string.concat(root, "/configJSON-V2.json");
        string memory json = vm.readFile(path);
        bytes memory parseJsonByteCode = json.parseRaw(".variables");
        configVariables = abi.decode(parseJsonByteCode, (ConfigVariablesV2));
    }

    function contractToAddresses(
        ConfigAddressesV2 memory _configAddresses
    ) public {
        y2k = address(_configAddresses.y2k);
        // keeperDepeg = KeeperGelatoDepeg(configAddresses.keeperDepeg);
        // keeperEndEpoch = KeeperGelatoEndEpoch(configAddresses.keeperEndEpoch);
    }

    function getConfigAddresses(
        bool _isTestEnv
    ) public returns (ConfigAddressesV2 memory constans) {
        string memory root = vm.projectRoot();
        string memory path;
        if (_isTestEnv) {
            path = string.concat(root, "/script/configs/configTestEnv-V2.json");
            isTestEnv = _isTestEnv;
        } else {
            path = string.concat(
                root,
                "/script/configs/configAddresses-V2.json"
            );
        }
        string memory json = vm.readFile(path);
        bytes memory parseJsonByteCode = json.parseRaw(".configAddresses");
        constans = abi.decode(parseJsonByteCode, (ConfigAddressesV2));
        configAddresses = constans;
    }

    function getConfigMarket()
        public
        returns (ConfigMarketV2[] memory markets)
    {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/configJSON-V2.json");
        string memory json = vm.readFile(path);
        bytes memory marketsRaw = vm.parseJson(json, ".markets");
        markets = abi.decode(marketsRaw, (ConfigMarketV2[]));
    }

    function getConfigEpochs()
        public
        returns (ConfigEpochWithEmission[] memory epochs)
    {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/configJSON-V2.json");
        string memory json = vm.readFile(path);
        bytes memory epochsRaw = vm.parseJson(json, ".epochs");
        epochs = abi.decode(epochsRaw, (ConfigEpochWithEmission[]));
    }

    function fundKeepers(uint256 _amount) public payable {
        KeeperV2(configAddresses.resolveKeeper).deposit{value: _amount}(
            _amount
        );
        KeeperV2Rollover(configAddresses.rolloverKeeper).deposit{
            value: _amount
        }(_amount);
    }

    function startKeepers(uint256 _marketIndex, uint256 _epochID) public {
        KeeperV2(configAddresses.resolveKeeper).startTask(
            _marketIndex,
            _epochID
        );
        KeeperV2Rollover(configAddresses.rolloverKeeper).startTask(
            _marketIndex,
            _epochID
        );
    }

    function verifyMarket() public view {
        // require(marketConstants.epochBegin < marketConstants.epochEnd, "epochBegin is not < epochEnd");
        // require(marketConstants.epochEnd > block.timestamp, "epochEnd in the past");
        // require(marketConstants.strikePrice > 900000000000000000, "strikePrice is not above 0.90");
        // require(marketConstants.strikePrice < 1000000000000000000, "strikePrice is not below 1.00");
        // //TODO add more checks
    }

    function verifyEpoch() public view {
        // require(epochConstants.epochBegin > marketConstants.epochEnd, "epochBegin is not > marketEnd");
        // require(epochConstants.epochBegin < epochConstants.epochEnd, "epochBegin is not < epochEnd");
        // require(epochConstants.epochEnd > block.timestamp, "epochEnd in the past");
        // //TODO add more checks
    }

    function stringToUint(string memory s) public pure returns (uint256) {
        bytes memory b = bytes(s);
        uint256 result = 0;
        for (uint256 i = 0; i < b.length; i++) {
            uint256 c = uint256(uint8(b[i]));
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
        return result;
    }
}
