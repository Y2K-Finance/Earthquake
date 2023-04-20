// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../src/v2/Controllers/RedstonePriceProvider.sol";
import "forge-std/console.sol";
import "forge-std/Script.sol";
import "forge-std/StdJson.sol";

// source .env
// forge script ./script/DeployRedstone.s.sol:DeployAndTestRedstone --ffi --rpc-url $GOERLI_RPC_URL --broadcast --verify -vvvv
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
    
    //address priceProvider = address(new RedstonePriceProvider(addresses.arbitrum_sequencer, vaultFactoryAddress));
    function deploy() internal returns (address){
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);        
        //vm.startBroadcast();
        console.log("priceProvider1");
        address vaultFactoryAddress = address(0);
        address priceProvider = address(new RedstonePriceProvider(address(0),address(0)));
        vm.stopBroadcast();      
        
        // Get the transaction receipt
        (bool success, bytes memory result) = address(vm).staticcall(abi.encodeWithSignature("getReceipt(address)", priceProvider));
        require(success, "Failed to get transaction receipt");

        // Decode the transaction receipt
        (uint256 status, uint256 cumulativeGasUsed, bytes32 txHash) = abi.decode(result, (uint256, uint256, bytes32));

       // Log the transaction hash
        console.log("Transaction Hash: ");
        console.log(string(abi.encodePacked(txHash)));
        
        console.log("new priceProvider");
        console.log(priceProvider);
        
        
        
        return priceProvider;
        
        
        
    }
    
    function addressToString(address _address) public pure returns (string memory) {
        bytes32 _bytes = bytes32(uint256(uint160(_address)));
        bytes memory hexAlphabet = "0123456789abcdef";
        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        for (uint i = 0; i < 20; ++i) {
            str[2 + i * 2] = hexAlphabet[uint8(_bytes[i + 12] >> 4)];
            str[3 + i * 2] = hexAlphabet[uint8(_bytes[i + 12] & 0x0f)];
        }
        return string(str);
    }
    
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
        cmd[2] = vm.envString("GOERLI_RPC_URL");   
        cmd[3] = vm.envString("PRIVATE_KEY");   
        //cmd[4] = string(redstoneOracleAddress);
        cmd[4] = redstoneOracleAddress;
        
        bytes memory result = vm.ffi(cmd);        
        string memory resultString = removeFirstChar(string(result));
        return resultString;
    }
    
    function removeFirstChar(string memory input) internal pure returns (string memory) {
        bytes memory inputBytes = bytes(input);
        require(inputBytes.length > 0, "Input string must not be empty");

        bytes memory outputBytes = new bytes(inputBytes.length - 1);
        for (uint i = 1; i < inputBytes.length; i++) {
            outputBytes[i - 1] = inputBytes[i];
        }
        return string(outputBytes);
    }    
    
    function run() public{        
        //address redstoneOracle = 0x90193C961A926261B756D1E5bb255e67ff9498A1;
        address redstoneOracle = deploy();
        
        string memory redstoneOracleAddress = addressToString(redstoneOracle);
        console.log("redstoneOracleAddress");
        console.log(redstoneOracleAddress);
        string memory newPrice  = getJsPrice(redstoneOracleAddress);
        
        if (!isNumber(newPrice)) {
            console.log("Error: COULD NOT GET PRICE FROM REDSTONE ORACLE");
            console.log(newPrice);
            return;
            
        } else {
            console.log("newPrice");        
            console.log(newPrice);
            RedstonePriceProvider rpp = RedstonePriceProvider(redstoneOracle);
            int256 vstPrice = rpp.getLatestPrice(address(0));
            console.log("vstPrice");        
            console.log(uint256(vstPrice));
        }
        console.log("Finishing");
        
    }

}

