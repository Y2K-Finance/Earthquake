// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../Helper.sol";
import "../../../src/oracles/GdaiOracle.sol"; 
import "../../../src/oracles/VstOracle.sol"; 

import "forge-std/console.sol";
contract ReadTVLTest is Helper {    
    GdaiOracle public gdai; // Use the ReadTVL contract name
    VstOracle public vst; 

    string public ARBITRUM_RPC_URL = vm.envString("ARBITRUM_GOERLI_RPC_URL");

    
    
    function setUp() public {
        uint256 arbForkId = vm.createFork(ARBITRUM_RPC_URL,18224000);// 18224050 Found out the very hard way that one should use an old block on test o.O -.-
        vm.selectFork(arbForkId);
        console.log("starting 2");
        vst = new VstOracle(REDSTONE_VST_TEST); // VST Testnet address given by RedStone
        
        console.log("starting 3");
        
    }

    function testReadTVL() public {
        // Call the function in your ReadTVL smart contract that reads the TVL value
        console.log("starting 3");
        uint256 vstValue = vst.getValue();
        console.log(vstValue);
        // Assert that the TVL value is greater than zero (or any other condition you want to check)
        assertTrue(vstValue > 0);
        console.log("starting 4");
        
        uint8 dec = vst.getDecimals();
        assertTrue(dec == 18);
        
        
    }
}
