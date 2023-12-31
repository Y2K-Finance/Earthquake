// SPDX-License-Identifier;
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";
import "forge-std/Test.sol";
//TODO change this after deploy  y2k token
import "@openzeppelin/contracts/utils/Strings.sol";
import "../../src/v2/Carousel/CarouselFactory.sol";
import "../../src/v2/Carousel/CarouselFactoryPausable.sol";
import "../../src/v2/Carousel/Carousel.sol";

import "../../src/v2/Controllers/ControllerPeggedAssetV2.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../keepers/KeeperV2.sol";
import "../keepers/KeeperV2Rollover.sol";

// import Farm Contracts

import {StakingRewards} from "../../src/v2/Farms/StakingRewards.sol";


/// @author MiguelBits

contract HelperV2 is Script {
    using stdJson for string;

    // @note structs that reflect JSON need to have keys in alphabetical order!!!
    struct ConfigAddressesV2 {
        address admin;
        address arb;
        address arbitrum_sequencer;
        address carouselFactory;
        address controller;
        address controllerGeneric;
        address controllerGenericPausable;
        address gelatoOpsV2;
        address gelatoTaskTreasury;
        address pausableCarouselFactory;
        address policy;
        address resolveKeeper;
        address resolveKeeperGeneric;
        address resolveKeeperGenericPausable;
        address rolloverKeeper;
        address rolloverKeeperPausable;
        address treasury;
        address weth;
        address y2k;
    }

    struct ConfigEpochWithEmission {
        string collatEmissions;
        string depositAsset;
        uint40 epochBegin;
        uint40 epochEnd;
        string name;
        string premiumEmissions;
        string strikePrice;
        address token;
        uint16 withdrawalFee;
    }

    struct ConfigMarketV2 {
        string depositAsset;
        string depositFee;
        bool isDepeg;
        bool isGenericController;
        string minQueueDeposit;
        string name;
        address oracle;
        string relayFee;
        string strikePrice;
        address token;
        string uri;
    }

    struct ConfigVariablesV2 {
        uint256 amountOfNewEpochs;
        uint256 amountOfNewMarkets;
        bool epochs;
        bool isTestEnv;
        bool newMarkets;
        uint256 totalAmountOfEmittedTokens;
    }

    address y2k;
    ConfigVariablesV2 configVariables;
    ConfigAddressesV2 configAddresses;
    bool isTestEnv;
    CarouselFactory factory;
    CarouselFactory pausableFactory;
    function setVariables() public {
        string memory root = vm.projectRoot();
        // TODO: Set the variables correctly
        string memory path = string.concat(root, "/configJSON-V2.json");
        string memory json = vm.readFile(path);
        bytes memory parseJsonByteCode = json.parseRaw(".variables");
        configVariables = abi.decode(parseJsonByteCode, (ConfigVariablesV2));
        isTestEnv = configVariables.isTestEnv;
    }

    function contractToAddresses(
        ConfigAddressesV2 memory _configAddresses
    ) public {
        y2k = address(_configAddresses.y2k);
        factory = CarouselFactory(_configAddresses.carouselFactory);
        pausableFactory = CarouselFactory(
            _configAddresses.pausableCarouselFactory
        );
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
        // KeeperV2(configAddresses.resolveKeeper).deposit{value: _amount}(
        //     _amount
        // );
        // KeeperV2Rollover(configAddresses.rolloverKeeper).deposit{
        //     value: _amount
        // }(_amount);

        KeeperV2Rollover(configAddresses.resolveKeeperGenericPausable).deposit{
            value: _amount
        }(_amount);
        
        KeeperV2Rollover(configAddresses.rolloverKeeperPausable).deposit{
            value: _amount
        }(_amount);

    }

    function startKeepers(
        uint256 _marketId,
        uint256 _epochId,
        bool _isGenericController
    ) public {
        address resolver = _isGenericController ?
            // ? _marketId ==  98949310992640213851983765150833189432751758546965601760898583298872224793782 ?
            //         configAddresses.resolveKeeperGeneric :
            //         configAddresses.resolveKeeperGenericPausable
            configAddresses.resolveKeeperGeneric
            : configAddresses.resolveKeeper;
        KeeperV2(resolver).startTask(
                _marketId,
                _epochId
        );

        address rollover = 
        _isGenericController ? 
            // ? _marketId ==  98949310992640213851983765150833189432751758546965601760898583298872224793782 ?
            //         configAddresses.rolloverKeeper :
            //         configAddresses.rolloverKeeperPausable
            configAddresses.rolloverKeeper
            : configAddresses.rolloverKeeper;

        KeeperV2Rollover(rollover).startTask(
            _marketId,
            _epochId
        );

        if (
            KeeperV2(resolver).tasks(
                keccak256(abi.encodePacked(_marketId, _epochId))
            ) == bytes32(0)
        ) {
            console2.log("resolveKeeper epochId not set");
            revert("resolveKeeper epochId error");
        }

        if (
            KeeperV2(rollover).tasks(
                keccak256(abi.encodePacked(_marketId, _epochId))
            ) == bytes32(0)
        ) {
            console2.log("rolloverKeeper epochId not set");
            revert("rolloverKeeper epochId error");
        }

        console2.log(
            "------------------------KEEPER DETAILS----------------------"
        );

        console2.log("Resolve Keeper taskId: ");
            console2.logBytes32(
                KeeperV2(resolver).tasks(
                    keccak256(abi.encodePacked(_marketId, _epochId))
                )
            );
            console2.log("Rollover Keeper taskId: ");
            console.logBytes32(
                KeeperV2(rollover).tasks(
                    keccak256(abi.encodePacked(_marketId, _epochId))
                )
            );
    }

    function getController(
        bool isGenericControler
    ) public view returns (address controller) {
        return
            isGenericControler
                ? configAddresses.controllerGeneric
                : configAddresses.controller;
    }

    function getDepositAsset(
        string memory _depositAsset
    ) public view returns (address depositAsset) {
        if (
            keccak256(abi.encodePacked(_depositAsset)) ==
            keccak256(abi.encodePacked(string("WETH")))
        ) {
            return configAddresses.weth;
        } else if (
            keccak256(abi.encodePacked(_depositAsset)) ==
            keccak256(abi.encodePacked(string("ARB")))
        ) {
            return configAddresses.arb;
        } else if (
            keccak256(abi.encodePacked(_depositAsset)) ==
            keccak256(abi.encodePacked(string("Y2K")))
        ){
            return configAddresses.y2k;
        } else if (
            keccak256(abi.encodePacked(_depositAsset)) ==
            keccak256(abi.encodePacked(string("DAI")))
        ) {
            return 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;
        } else {
            revert("depositAsset not found");
        }
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


    function stringToInt(string memory s) public pure returns (int256) {
        // Convert the string into a bytes representation for easier manipulation
        bytes memory b = bytes(s);

        // Initialize the result as 0
        int256 result = 0;

        // A flag to check if the number is negative
        bool isNegative = false;

        // We assume the number starts at the beginning of the string
        uint256 start = 0;

        // Check if the first character is a negative sign ("-")
        if (b.length > 0 && b[0] == bytes1(0x2D)) {
            isNegative = true;  // Set the flag if it's negative
            start = 1;          // Start parsing from the next character
        }

        // Loop through each character of the string
        for (uint256 i = start; i < b.length; i++) {
            // Convert the character into its ASCII value
            uint256 c = uint256(uint8(b[i]));

            // Check if the character is a digit (ASCII values from 48 to 57 represent '0' to '9')
            if (c >= 48 && c <= 57) {
                // Convert the character to its integer value and add it to the result
                result = result * 10 + (int256(c) - 48);
            }
        }

        // If the number was negative, negate the result
        if (isNegative) {
            result = -result;
        }

        return result;
    }

    function stringToUint(string memory s) public pure returns (uint256) {
        // First, convert the string to an int256
        int256 intResult = stringToInt(s);

        // Then, cast the int256 to a uint256 and return
        return uint256(intResult);
    }

}
