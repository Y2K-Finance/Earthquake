// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/VaultFactory.sol";
import "../src/Controller.sol";

//forge script script/Contract.s.sol:ContractScript --rpc-url $ARBITRUM_RINKEBY_RPC_URL  --private-key $PRIVATE_KEY --broadcast -vvvv --via-ir
contract ContractScript is Script {

    //rinkeby arbitrum
    address public constant wETH = 0x207eD1742cc0BeBD03E50e855d3a14E41f93A461;

    address public constant oracle1 = 0x3e3546c6b5689f7EAa1BA7Bc9571322c3168D786; //dai
    address public constant oracle2 = 0x103a2d37Ea6b3b4dA2F5bb44E001001729E74354; //usdc
    address public constant oracle3 = 0xb1Ac85E779d05C2901812d812210F6dE144b2df0; //usdt

    address public token1 = 0x4dCf5ac4509888714dd43A5cCc46d7ab389D9c23;
    address public token2 = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;
    address public token3 = 0x2C8d6418499a1482B8624Dc7Ee64236aA303d30B;

    address public admin = 0xFB0a3A93e9acd461747e7D613eb3722d53B96613;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        
        //0xc1FEb9F2Bc1B96bD445098F556982D1C7812ceb7
        VaultFactory _vf = new VaultFactory(address(this),wETH, admin);
        Controller _ct = new Controller(address(_vf), admin);

        //REAL MARKETS:
        _vf.setController(address(_ct));
        _vf.createNewMarket(10,50,token1,99000000,block.timestamp + 12 hours, block.timestamp + 13 hours,oracle1,"y2kDAI_AUG*99");
        // _vf.createNewMarket(10,50,token1,97000000,block.timestamp + 2 days,block.timestamp + 5 days,oracle1,"y2kDAI_AUG*98");
        // _vf.createNewMarket(10,50,token1,95000000,block.timestamp + 3 days,block.timestamp + 5 days,oracle1,"y2kDAI_AUG*97");

        //DEPEGGED MARKETS:
        _vf.createNewMarket(10,50,token2,199000000,block.timestamp + 12 hours, block.timestamp + 13 hours,oracle2,"y2kUSDC_AUG*99");
        // _vf.createNewMarket(10,50,token2,197000000,block.timestamp + 2 days,block.timestamp + 5 days,oracle2,"y2kUSDC_AUG*98");
        // _vf.createNewMarket(10,50,token2,195000000,block.timestamp + 3 days,block.timestamp + 5 days,oracle2,"y2kUSDC_AUG*97");

        vm.stopBroadcast();
    }
}
