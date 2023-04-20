// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
//import "../src/v2/Controllers/RedstonePriceProvider.sol";
//import "./Helper.sol";

//import "../src/v2/Controllers/RedstoneMockPriceProvider.sol";
import "../src/v2/Controllers/ChainlinkPriceProvider.sol";


//import "./Helper.sol";
import "forge-std/console.sol";
import "forge-std/Script.sol";
import "forge-std/StdJson.sol";

contract DeployAndTestRedstone is Script {
    //RedstonePriceProvider public priceProvider;
    using stdJson for string;
    
    ConfigAddresses configAddresses;
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
        //console2.log("json ", string(json));
        
        bytes memory parseJsonByteCode = json.parseRaw(".configAddresses[0]");
        ConfigAddresses memory rawConstants = abi.decode(parseJsonByteCode, (ConfigAddresses));
        //console2.log("ConfigAddresses ", rawConstants.weth);
        
        return rawConstants;
    }
    
    function setup() internal {
        configAddresses = getConfigAddresses(true);
    }
    /*
    function deploy() internal {
        vm.startBroadcast();
        address vaultFactoryAddress = address(0);
        priceProvider = new RedstonePriceProvider(addresses.arbitrum_sequencer, vaultFactoryAddress);
        vm.stopBroadcast();        
    }
    function test() internal {
        // Invoke the Node.js script
        // somehow vm.execute("InvokeNodeScript");
        uint256 vstPrice = evmConnector.getLatestPrice(address(priceProvider), address(0));

        // Output the fetched price
        emit Log("Fetched vstPrice \", vstPrice);
    }*/
    
    // Helper function to check if a string is a number
    function isNumber(string memory s) private pure returns (bool) {
        bytes memory b = bytes(s);
        for (uint i = 0; i < b.length; i++) {
            if (!(b[i] >= "0" && b[i] <= "9" || b[i] == ".")) {
                return false;
            }
        }
        return true;
    }

    function getJsPrice(string  memory  redstoneOracleAddress) public returns (string memory) {
        setup();
        string[] memory cmd = new string[](5);
        cmd[0] = "node";        
        cmd[1] = "./script/test_RedstonePrice.js";
        ///cmd[2] = vm.envString("ARBITRUM_GOERLI_RPC_URL");   
        cmd[2] = vm.envString("ETH_GOERLI_RPC_URL");   
        cmd[3] = vm.envString("PRIVATE_KEY");   
        //cmd[4] = string(redstoneOracleAddress);
        cmd[4] = redstoneOracleAddress;
        
        bytes memory result = vm.ffi(cmd);        
        string memory resultString = string(result);
        return resultString;
    }
    
    function run() public{
        string memory redstoneOracleAddress = "0x11Cc82544253565beB74faeda687db72cd2D5d32";
        string memory newPrice  = getJsPrice(redstoneOracleAddress);
        
        if (!isNumber(newPrice)) {
            console.log("Error: COULD NOT GET PRICE FROM REDSTONE ORACLE");
            console.log(newPrice);
            return;
            
        } else {
            console.log("success");        
            console.log(newPrice);
            
        }
        console.log("Finishing");
        
    }

}

