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
        uint256 epochBegin;
        uint256 epochEnd;
        uint256 epochFee;
        string name;
        address oracle;
        int256 strikePrice;
        address token;
    }

    struct ConfigFarm {
        uint256 rewardsAmountHEDGE;
        uint256 rewardsAmountRISK;
    }

    VaultFactory vaultFactory;
    Controller controller;
    RewardsFactory rewardsFactory;
    Y2K y2k;
    KeeperGelatoDepeg keeperDepeg;
    KeeperGelatoEndEpoch keeperEndEpoch;

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