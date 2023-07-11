// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Helper.sol";
import "../../src/v2/VaultFactoryV2Pausable.sol";
import "../../src/v2/VaultV2Pausable.sol";
import "../../src/v2/TimeLock.sol";
import "../../src/v2/interfaces/IVaultV2Pausable.sol";

contract FactoryV2PausableTest is Helper {
    VaultFactoryV2Pausable factory;
    TimeLock timelock;
    address controller;

    function setUp() public {
        timelock = new TimeLock(ADMIN);

        factory = new VaultFactoryV2Pausable(WETH, TREASURY, address(timelock));

        controller = address(0x54);
        factory.whitelistController(address(controller));
    }

    function testFactoryCreation() public {
        timelock = new TimeLock(ADMIN);

        factory = new VaultFactoryV2Pausable(WETH, TREASURY, address(timelock));

        assertEq(address(timelock.policy()), ADMIN);
        assertEq(address(factory.WETH()), WETH);
        assertEq(address(factory.treasury()), TREASURY);
        assertEq(address(factory.owner()), address(this));

        // After deployment controller can be set one time by owner
        vm.expectRevert(
            abi.encodeWithSelector(VaultFactoryV2Pausable.AddressZero.selector)
        );
        factory.whitelistController(address(0));

        address controller1 = address(0x54);
        factory.whitelistController(address(controller1));
        assertTrue(factory.controllers(controller1));

        address controller2 = address(0x55);
        vm.expectRevert(
            abi.encodeWithSelector(
                VaultFactoryV2Pausable.NotAuthorized.selector
            )
        );
        factory.whitelistController(controller2);

        // new controllers can be added by queueing them in tomelocker
        vm.startPrank(factory.timelocker());
        factory.whitelistController(controller2);
        assertTrue(factory.controllers(controller2));
        vm.stopPrank();
    }

    function testMarketCreation() public {
        // test all revert cases
        vm.startPrank(NOTADMIN);
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        factory.createNewMarket(
            VaultFactoryV2Pausable.MarketConfigurationCalldata(
                address(0x1),
                uint256(0x2),
                address(0x3),
                address(0x4),
                string(""),
                string(""),
                address(0x7) // wrong controller
            )
        );
        vm.stopPrank();

        // wrong controller
        vm.expectRevert(VaultFactoryV2Pausable.ControllerNotSet.selector);
        factory.createNewMarket(
            VaultFactoryV2Pausable.MarketConfigurationCalldata(
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
        vm.expectRevert(VaultFactoryV2Pausable.AddressZero.selector);
        factory.createNewMarket(
            VaultFactoryV2Pausable.MarketConfigurationCalldata(
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
        vm.expectRevert(VaultFactoryV2Pausable.AddressZero.selector);
        factory.createNewMarket(
            VaultFactoryV2Pausable.MarketConfigurationCalldata(
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
        vm.expectRevert(VaultFactoryV2Pausable.AddressZero.selector);
        factory.createNewMarket(
            VaultFactoryV2Pausable.MarketConfigurationCalldata(
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
        (address premium, address collateral, uint256 marketId) = factory
            .createNewMarket(
                VaultFactoryV2Pausable.MarketConfigurationCalldata(
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
        assertTrue(factory.marketToOracle(marketId) == oracle);
        assertEq(marketId, factory.getMarketId(token, strike, underlying));

        // test if counterparty is set
        assertEq(IVaultV2Pausable(premium).counterPartyVault(), collateral);
        assertEq(IVaultV2Pausable(collateral).counterPartyVault(), premium);
    }

    function testEpochDeployment() public {
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

        uint256 marketId = createMarketHelper();

        // test revert cases
        vm.expectRevert(
            abi.encodeWithSelector(
                VaultFactoryV2Pausable.MarketDoesNotExist.selector,
                uint256(0x1)
            )
        );
        factory.createEpoch(
            uint256(0x1), // market does not exist
            uint40(0x2),
            uint40(0x3),
            uint16(0x4)
        );

        vm.expectRevert(VaultFactoryV2Pausable.FeeCannotBe0.selector);
        factory.createEpoch(
            marketId,
            uint40(0x2),
            uint40(0x3),
            uint16(0) // fee can not be 0
        );

        // make sure epoch can not be set if controller is deprecated
        address[2] memory vaults = factory.getVaults(marketId);
        vm.startPrank(address(factory.timelocker()));
        factory.whitelistController(controller);
        vm.stopPrank();
        vm.expectRevert(VaultFactoryV2Pausable.ControllerNotSet.selector);
        factory.createEpoch(marketId, uint40(0x2), uint40(0x3), uint16(0x4));
        vm.startPrank(address(factory.timelocker()));
        factory.whitelistController(controller);
        vm.stopPrank();

        vm.expectRevert(VaultV2Pausable.EpochEndMustBeAfterBegin.selector);
        factory.createEpoch(
            marketId,
            uint40(0x5), // begin must be before end
            uint40(0x3),
            uint16(0x4)
        );

        (uint256 epochId, ) = factory.createEpoch(
            marketId,
            uint40(0x2),
            uint40(0x3),
            uint16(0x4)
        );
        vm.expectRevert(VaultV2Pausable.EpochAlreadyExists.selector);
        factory.createEpoch(marketId, uint40(0x2), uint40(0x3), uint16(0x4));

        uint40 begin = uint40(0x3);
        uint40 end = uint40(0x4);
        uint16 fee = uint16(0x5);

        // epoch can not be created when market is paused
        factory.pauseMarket(marketId);
        vm.expectRevert(VaultV2Pausable.MarketPaused.selector);
        factory.createEpoch(marketId, begin, end, fee);
        factory.pauseMarket(marketId);

        // test success case
        (uint256 epochId2, ) = factory.createEpoch(marketId, begin, end, fee);

        // test if epoch fee is correct
        uint16 fetchedFee = factory.getEpochFee(epochId2);
        assertEq(fee, fetchedFee);

        // test if epoch config is correct
        (uint40 fetchedBegin, uint40 fetchedEnd, ) = IVaultV2Pausable(vaults[0])
            .getEpochConfig(epochId2);
        assertEq(begin, fetchedBegin);
        assertEq(end, fetchedEnd);

        // test if epoch is added to market
        uint256[] memory epochs = factory.getEpochsByMarketId(marketId);
        assertEq(epochs[0], epochId);
        assertEq(epochs[1], epochId2);
    }

    function testPauseMarket() public {
        uint256 marketId = createMarketHelper();
        uint256 falseId = 999;
        address[2] memory vaults = factory.getVaults(marketId);

        // test revert cases
        vm.expectRevert(
            abi.encodeWithSelector(
                VaultFactoryV2Pausable.MarketDoesNotExist.selector,
                falseId
            )
        );
        factory.pauseMarket(falseId);

        // test success case
        factory.pauseMarket(marketId);
        assertEq(IVaultV2Pausable(vaults[0]).paused(), true);
        assertEq(IVaultV2Pausable(vaults[1]).paused(), true);
    }

    function testSetTreasury() public {
        // test revert cases
        vm.expectRevert(VaultFactoryV2Pausable.NotTimeLocker.selector);
        factory.setTreasury(address(0x20));

        vm.startPrank(address(factory.timelocker()));
        vm.expectRevert(VaultFactoryV2Pausable.AddressZero.selector);
        factory.setTreasury(address(0));

        // test success case
        factory.setTreasury(address(0x20));
        assertEq(factory.treasury(), address(0x20));
        vm.stopPrank();
    }

    function testChangeController() public {
        address newController = address(0x20);
        // test revert cases
        uint256 marketId = createMarketHelper();
        vm.expectRevert(VaultFactoryV2Pausable.NotTimeLocker.selector);
        factory.changeController(marketId, newController);

        vm.startPrank(address(factory.timelocker()));
        vm.expectRevert(VaultFactoryV2Pausable.ControllerNotSet.selector);
        factory.changeController(marketId, newController);
        factory.whitelistController(newController);
        vm.expectRevert(
            abi.encodeWithSelector(
                VaultFactoryV2Pausable.MarketDoesNotExist.selector,
                uint256(0x1)
            )
        );
        factory.changeController(uint256(0x1), newController);

        // test success case
        factory.changeController(marketId, newController);
        address[2] memory vaults = factory.getVaults(marketId);
        assertEq(IVaultV2Pausable(vaults[0]).controller(), newController);
        assertEq(IVaultV2Pausable(vaults[1]).controller(), newController);
        vm.stopPrank();
    }

    function testChangeOracle() public {
        // address oldOracle = address(0x3);
        address newOracle = address(0x4);

        uint256 marketId = createMarketHelper();
        vm.expectRevert(VaultFactoryV2Pausable.NotTimeLocker.selector);
        factory.changeOracle(marketId, newOracle);

        vm.startPrank(address(factory.timelocker()));
        vm.expectRevert(
            abi.encodeWithSelector(
                VaultFactoryV2Pausable.MarketDoesNotExist.selector,
                uint256(0)
            )
        );
        factory.changeOracle(uint256(0), newOracle);
        vm.expectRevert(
            abi.encodeWithSelector(
                VaultFactoryV2Pausable.MarketDoesNotExist.selector,
                uint256(1)
            )
        );
        factory.changeOracle(uint256(1), newOracle);
        vm.expectRevert(VaultFactoryV2Pausable.AddressZero.selector);
        factory.changeOracle(marketId, address(0));

        // test success case
        factory.changeOracle(marketId, newOracle);
        vm.stopPrank();
        assertEq(factory.marketToOracle(marketId), newOracle);
    }

    function testTransferOwnership() public {
        // test revert cases
        vm.expectRevert(VaultFactoryV2Pausable.NotTimeLocker.selector);
        factory.transferOwnership(address(0x20));

        // imitate timelocker
        vm.startPrank(address(factory.timelocker()));
        vm.expectRevert(VaultFactoryV2Pausable.AddressZero.selector);
        factory.transferOwnership(address(0));

        // test success case
        factory.transferOwnership(address(0x20));
        assertEq(factory.owner(), address(0x20));
        vm.stopPrank();

        // interact through timelocker
        vm.startPrank(address(0x222222));
        // test revert cases
        vm.expectRevert(
            abi.encodeWithSelector(
                TimeLock.NotOwner.selector,
                address(0x222222)
            )
        );
        timelock.changeOwnerOnFactory(address(0x222222), address(factory));
        vm.stopPrank();

        vm.startPrank(ADMIN);
        // test success case
        timelock.changeOwnerOnFactory(address(0x21), address(factory));
        assertEq(factory.owner(), address(0x21));
        vm.stopPrank();
    }

    function createMarketHelper() public returns (uint256 marketId) {
        address token = address(0x1);
        address oracle = address(0x3);
        address underlying = address(0x4);
        uint256 strike = uint256(0x2);
        string memory name = string("test");
        string memory symbol = string("tst");

        (, , marketId) = factory.createNewMarket(
            VaultFactoryV2Pausable.MarketConfigurationCalldata(
                token,
                strike,
                oracle,
                underlying,
                name,
                symbol,
                controller
            )
        );
    }
}
