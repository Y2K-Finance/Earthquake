// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Helper.sol";
import "../../src/v2/VaultFactoryV2.sol";


contract FactoryV2Test is Helper {
      VaultFactoryV2 factory;
      address controller;
      function setUp() public {
        factory = new VaultFactoryV2(
            ADMIN,
            WETH,
            TREASURY
        );

        controller = address(0x54);
        factory.whitelistController(address(controller));
     }


    function testFactoryCreation() public {

        factory = new VaultFactoryV2(
            ADMIN,
            WETH,
            TREASURY
        );
       
        assertEq(address(factory.timelocker().policy()), ADMIN);
        assertEq(address(factory.WETH()), WETH);
        assertEq(address(factory.treasury()), TREASURY);
        assertEq(address(factory.owner()), address(this));

        // After deployment controller can be set one time by owner 
        vm.expectRevert(abi.encodeWithSelector(VaultFactoryV2.AddressZero.selector));
        factory.whitelistController(address(0));

        address controller1 = address(0x54);
        factory.whitelistController(address(controller1));
        assertTrue(factory.controllers(controller1));

        address controller2 = address(0x55);
        vm.expectRevert(abi.encodeWithSelector(VaultFactoryV2.NotAuthorized.selector));
        factory.whitelistController(controller2);

        // new controllers can be added by queueing them in tomelocker
        vm.startPrank(address(factory.timelocker()));
        factory.whitelistController(controller2);
        assertTrue(factory.controllers(controller2));
        vm.stopPrank();
    }

    function testMarketCreation() public {
        
        // test all revert cases
        vm.startPrank(NOTADMIN);
            vm.expectRevert(bytes("Ownable: caller is not the owner"));
                factory.createNewMarket(
                    VaultFactoryV2.MarketConfigurationCalldata(
                        address(0x1),
                        uint256(0x2),
                        address(0x3),
                        address(0x4),
                        string(""),
                        string(""),
                        address(0x7)
                    )
                );
        vm.stopPrank();

        // wrong controller
        vm.expectRevert(VaultFactoryV2.ControllerNotSet.selector);
            factory.createNewMarket(
                VaultFactoryV2.MarketConfigurationCalldata(
                    address(0x1),
                    uint256(0x2),
                    address(0x3),
                    address(0x4),
                    string(""),
                    string(""),
                    address(0x7) // wrong controller
                )
            );

        address token = address(0x1);
        address oracle = address(0x3);
        address underlying = address(0x4);
        uint256 strike = uint256(0x2);
        string memory name = string("");
        string memory symbol = string("");
        // wrong token
        vm.expectRevert(VaultFactoryV2.AddressZero.selector);
            factory.createNewMarket(
                VaultFactoryV2.MarketConfigurationCalldata(
                    address(0), // wrong token
                    strike,
                    oracle,
                    underlying,
                    name,
                    symbol,
                    controller
                )
            );

       // wrong oracle
        vm.expectRevert(VaultFactoryV2.AddressZero.selector);
            factory.createNewMarket(
                VaultFactoryV2.MarketConfigurationCalldata(
                    token,
                    strike,
                    address(0), // wrong oracle
                    underlying,
                    name,
                    symbol,
                    controller
                )
            );

        // wrong underlying
        vm.expectRevert(VaultFactoryV2.AddressZero.selector);
            factory.createNewMarket(
                VaultFactoryV2.MarketConfigurationCalldata(
                    token,
                    strike,
                    oracle,
                    address(0), // wrong underlying
                    name,
                    symbol,
                    controller
                )
            );


        // test success case
        (
            address premium,
            address collateral,
            uint256 marketId
        ) = factory.createNewMarket(
            VaultFactoryV2.MarketConfigurationCalldata(
                token,
                strike,
                oracle,
                underlying,
                name,
                symbol,
                controller
            )
        );

        // test if market is created
        assertEq(factory.getVaults(marketId)[0], premium);
        assertEq(factory.getVaults(marketId)[1], collateral);

        // test oracle is set
        assertTrue(factory.tokenToOracle(token) == oracle);
        assertEq(marketId, factory.getMarketId(token, strike));

        // test if counterparty is set
        assertEq(IVaultV2(premium).counterPartyVault(), collateral);
        assertEq(IVaultV2(collateral).counterPartyVault(), premium);   
    }

    function testEpochDeloyment() public {
        // teste revert cases
        vm.startPrank(NOTADMIN);
            vm.expectRevert(bytes("Ownable: caller is not the owner"));
                factory.createEpoch(
                uint256(0x1),
                uint40(0x2),
                uint40(0x3),
                uint16(0x4)
                );
        vm.stopPrank();
    }

    // function testChangeTreasury() {

    // }
    
    // function testSetTreasury() {

    // }

    // function testChangeController() {
        
    // }

    // function testChangeOracle() {

    // }
}