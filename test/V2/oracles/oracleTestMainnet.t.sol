// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../Helper.sol";
import "../../../src/oracles/gdaiOracle.sol"; 
import "../../../src/oracles/vstOracle.sol";

import "forge-std/console.sol";
contract ReadTVLTest is Helper {
    gdaiOracle public gdai; // Use the ReadTVL contract name
    vstOracle public vst; 

    string public ARBITRUM_RPC_URL = vm.envString("ARBITRUM_RPC_URL");

    function setUp() public {
        uint256 arbForkId = vm.createFork(ARBITRUM_RPC_URL);
        vm.selectFork(arbForkId);
        console.log("starting");
        gdai = new gdaiOracle(address( 0xd85E038593d7A098614721EaE955EC2022B9B91B ));
        
        console.log("starting 3");
        
    }

    function testReadTVL() public {
        // Call the function in your ReadTVL smart contract that reads the TVL value
        uint256 gains = gdai.getValue();
        console.log(gains);
        // Assert that the TVL value is greater than zero (or any other condition you want to check)
        assertTrue(gains > 0);
        
        console.log("starting 4");
    }
}
