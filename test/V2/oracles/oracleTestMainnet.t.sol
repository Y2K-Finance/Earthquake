// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../Helper.sol";
import "./gdaiOracle.sol"; // Import your smart contract here
import "./vstOracle.sol"; // Import your smart contract here

import "forge-std/console.sol";
contract ReadTVLTest is Helper {
    ReadTVL public readTVL; // Use the ReadTVL contract name
    ReadVST public readVST; 

    string public ARBITRUM_RPC_URL = vm.envString("ARBITRUM_RPC_URL");

    function setUp() public {
        uint256 arbForkId = vm.createFork(ARBITRUM_RPC_URL);
        vm.selectFork(arbForkId);
        console.log("starting");
        readTVL = new ReadTVL(address( 0xd85E038593d7A098614721EaE955EC2022B9B91B ));
        
        console.log("starting 3");
        
    }

    function testReadTVL() public {
        // Call the function in your ReadTVL smart contract that reads the TVL value
        uint256 gains = readTVL.getValue();
        console.log(gains);
        // Assert that the TVL value is greater than zero (or any other condition you want to check)
        assertTrue(gains > 0);
        
        console.log("starting 4");
    }
}
