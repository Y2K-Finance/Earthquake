// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../Helper.sol";
import "../../../src/oracles/GdaiOracle.sol"; 
import "../../../src/oracles/VstOracle.sol";

import "forge-std/console.sol";
contract ReadTVLTest is Helper {
    GdaiOracle public gdai; // Use the ReadTVL contract name
    VstOracle public vst; 

    string public ARBITRUM_RPC_URL = vm.envString("ARBITRUM_RPC_URL");

    function setUp() public {
    
       // TODO: Test all the oracles in one file if possible 
        uint256 arbForkId = vm.createFork(ARBITRUM_RPC_URL);
        vm.selectFork(arbForkId);
        console.log("starting");
        gdai = new GdaiOracle(GDAI_GNS_MAIN,DAI_TOKEN_MAIN,UNISWAP_DAIGDAI_POOL_MAIN);
        
    }

    function testReadTVL() public {
        
        uint8 dec = gdai.getDecimals();
        assertTrue(dec == 18);
        
        uint256 colrat = gdai.getCollateralizationRatio();
        assertTrue(colrat > 0);
        console.log("getCollateralizationRatio");
        console.log(colrat);
        
    }
}
