// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../src/v2/Controllers/RedstonePriceProvider.sol";
import "forge-std/console.sol";
import "forge-std/Script.sol";
import "forge-std/StdJson.sol";


// forge script ./script/TestRedstoneVST.s.sol:TestRedstoneVST --ffi --rpc-url $GOERLI_RPC_URL --broadcast -vvvv
contract TestRedstoneVST is Script {
    //RedstonePriceProvider public priceProvider;
    using stdJson for string;
    bytes32 symbol;
    
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
    
    function setup() internal {
        configAddresses = getConfigAddresses(true);
        symbol = bytes32("VST");
    }
    
    /*
    TODO: Update, to include a deploy which can fully test this oracle
    function deploy() internal returns (address){
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);        
        console.log("priceProvider1");
        address vaultFactoryAddress = address(0);
        //address priceProvider = address(new RedstonePriceProvider(addresses.arbitrum_sequencer, vaultFactoryAddress));
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
    }*/
    
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
    

    
    function getJsPrice(string  memory  redstoneOracleAddress) public returns (string memory) {
        setup();
        string[] memory cmd = new string[](5);
        cmd[0] = "node";        
        cmd[1] = "./script/test_RedstonePrice.js";
        cmd[2] = vm.envString("GOERLI_RPC_URL");  //TODO: Update to pull the rpc-url from the command line 
        cmd[3] = vm.envString("PRIVATE_KEY");   
        cmd[4] = redstoneOracleAddress;
        
        bytes memory result = vm.ffi(cmd);        
        string memory resultString = removeFirstChar(string(result));
        return resultString;
    }
    
    
    
    function run() public{        
        //TODO: CURRENT JG - this is in active development
        // At present, the RedstoneConsumerNumericBase.getOracleNumericValueFromTxMsg seems to:
        // 1. works when invoked via the dApp wrapper class (test_RedstonePrice.js)
        // WORKS:  string memory newPrice  = getJsPrice(redstoneOracleAddress) invokes test_RedstonePrice.js;
        // 2. fails when invoked via this forge process wrapper class RedstonePriceProvider.extGetOracleNumericValueFromTxMsg(symbol)
        // FAIL:  rpp.extGetOracleNumericValueFromTxMsg(symbol)
        // 3.
        // Expected:  rpp.extGetOracleNumericValueFromTxMsg(symbol) ~(similar to)= getJsPrice(redstoneOracleAddress)
        //////
        // Related Files / Classes
        // ./test_RedstonePrice.js
        // src/v2/Controllers/RedstonePriceProvider.sol (y2k)
        // --RedstoneConsumerNumericBase (RedStone API)
        // ----RedstoneConsumerBase (RedStone API)
        
        address redstoneOracle = 0x2f697A11f84Bd520Bf99D63Ef9c4038238c9423E; // Cleaned up code and uses variable symbol
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
            
            try rpp.getLatestPrice(address(0)) returns (int256 vstPrice) {
                console.log("vstPrice");
                console.log(uint256(vstPrice));
            } catch Error(string memory reason) {
                console.log("Error calling getLatestPrice:");
                console.log(reason);
            } catch (bytes memory /*lowLevelData*/) {
                console.log("Unknown error calling getLatestPrice");
            }
        }
        console.log("Finishing");
        // TODO: Add in deploy:
        // address redstoneOracle = deploy();
        
        // TODO: Info: Previous addresses and attempts on Goerli.
        // address redstoneOracle = 0x5684D53aD5babcC19e2a219B1625E4AaF97E33cA; // Full Broken Oracle
        // 0. address redstoneOracle = 0xB2727C8cdFc41a8F2653917A3Bf783956C90845A; // Returns just a number
        // 1. address redstoneOracle = 0xF6662ddF35A123630b6E665bc753A670e7a277d8; // Returns a deeper number
        // 2. address redstoneOracle = 0x0758474d78e8cD2D2D75AcAA0E088546449FC268; // Updated to include custom signer (did not help)

    }
    
    /*//////////////////////////////////////////////////////////////
                          SERVICE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

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
        
        return rawConstants;
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
    function removeFirstChar(string memory input) internal pure returns (string memory) {
        bytes memory inputBytes = bytes(input);
        require(inputBytes.length > 0, "Input string must not be empty");

        bytes memory outputBytes = new bytes(inputBytes.length - 1);
        for (uint i = 1; i < inputBytes.length; i++) {
            outputBytes[i - 1] = inputBytes[i];
        }
        return string(outputBytes);
    }    
    

}

