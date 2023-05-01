// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../Helper.sol";
import "../../../src/oracles/gdaiOracle.sol"; 
import "../../../src/oracles/vstOracle.sol"; 

import "forge-std/console.sol";
contract ReadTVLTest is Helper {    
    gdaiOracle public gdai; // Use the ReadTVL contract name
    vstOracle public vst; 

    string public ARBITRUM_RPC_URL = vm.envString("ARBITRUM_GOERLI_RPC_URL");

    
    
    function setUp() public {
        uint256 arbForkId = vm.createFork(ARBITRUM_RPC_URL,18224000);// 18224050 Found out the very hard way that one should use an old block on test o.O -.-
        vm.selectFork(arbForkId);
        console.log("starting 2");
        vst = new vstOracle(address( 0x86392aF1fB288f49b8b8fA2495ba201084C70A13 )); // VST Testnet address given by RedStone
        
        console.log("starting 3");
        
    }

    function testReadTVL() public {
        // Call the function in your ReadTVL smart contract that reads the TVL value
        console.log("starting 3");
        uint256 vst = vst.getValue();
        console.log(vst);
        // Assert that the TVL value is greater than zero (or any other condition you want to check)
        assertTrue(vst > 0);
        console.log("starting 4");
    }
}
