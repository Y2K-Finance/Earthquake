// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../Helper.sol";
import "../../../src/v2/Carousel/CarouselFactory.sol";
import "../../../src/v2/TimeLock.sol";
import "../../../src/v2/interfaces/ICarousel.sol";


contract CarouselFactoryTest is Helper { 
    using stdStorage for StdStorage;

        CarouselFactory factory;
        address controller;
        address emissionsToken;
        uint256 relayerFee;
        uint256 depositFee;
   
        function setUp() public {
        
        TimeLock timelock = new TimeLock(ADMIN);

        emissionsToken = address(new MintableToken("Emissions Token", "EMT"));


        factory = new CarouselFactory(
            WETH,
            TREASURY,
            address(timelock),
            emissionsToken
        );

        controller = address(0x54);
        factory.whitelistController(address(controller));

        relayerFee = 2 gwei;
        depositFee = 50; // 1%
     }

      function testCarouselMarketCreation() public {
        
        address token = address(0x1);
        address oracle = address(0x3);
        address underlying = address(0x4);
        uint256 strike = uint256(0x2);
        string memory name = string("");
        string memory symbol = string("");
        // test success case
        (
            address premium,
            address collateral,
            uint256 marketId
        ) = factory.createNewCarouselMarket(
            CarouselFactory.CarouselMarketConfigurationCalldata( 
                token,
                strike,
                oracle,
                underlying,
                name,
                symbol,
                controller,
                relayerFee,
                depositFee
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

        // test late deposit fee on Vaults is set
        assertEq(ICarousel(premium).depositFee(), depositFee);
        assertEq(ICarousel(collateral).depositFee(), depositFee);

        // test if relayer fee is set
        assertEq(ICarousel(premium).relayerFee(), relayerFee);
        assertEq(ICarousel(collateral).relayerFee(), relayerFee);

        // test emissions token is set
        assertEq(ICarousel(premium).emissionsToken(), emissionsToken);
        assertEq(ICarousel(collateral).emissionsToken(), emissionsToken);
    }

    function testCarouselEpochDeloyment() public {
    
        uint256 marketId = createMarketHelper();

        // test success case
        uint40 begin = uint40(0x3);
        uint40 end = uint40(0x4);
        uint16 fee = uint16(0x5);
        uint256 premiumEmissions = 1000 ether;
        uint256 collatEmissions = 100 ether;

        // revert if treasury does not have emissions tokens
        vm.expectRevert(stdError.arithmeticError);
        factory.createEpochWithEmissions(
                marketId,
                begin,
                end,
                fee,
                premiumEmissions,
                collatEmissions
        );

        // fund treasury
        deal(emissionsToken, TREASURY, 5000 ether, true);
        // revert if emissions token is not approved
        vm.expectRevert(stdError.arithmeticError);
        factory.createEpochWithEmissions(
                marketId,
                begin,
                end,
                fee,
                premiumEmissions,
                collatEmissions
        );

        // approve emissions token to factory
        vm.startPrank(TREASURY);
        MintableToken(emissionsToken).approve(address(factory),  5000 ether);
        vm.stopPrank();


       ( uint256 epochId2, address[2] memory vaults ) =  factory.createEpochWithEmissions(
                marketId,
                begin,
                end,
                fee,
                premiumEmissions,
                collatEmissions
        );

        // test if epoch fee is correct
        uint16 fetchedFee = factory.getEpochFee(epochId2);
        assertEq(fee, fetchedFee);
        
        // test if epoch config is correct
        (uint40 fetchedBegin, uint40 fetchedEnd, ) = IVaultV2(vaults[0]).getEpochConfig(epochId2);
        assertEq(begin, fetchedBegin);
        assertEq(end, fetchedEnd);

        // test if epoch is added to market
        uint256[] memory epochs = factory.getEpochsByMarketId(marketId);
        assertEq(epochs[0], epochId2); // this is not equal to epochs array on vaults

        // test if emissoins are set on vaults
        assertEq(ICarousel(vaults[0]).emissions(epochId2), premiumEmissions);
        assertEq(ICarousel(vaults[1]).emissions(epochId2), collatEmissions);

        // check emissions token balance of vaults
        assertEq(MintableToken(emissionsToken).balanceOf(vaults[0]), premiumEmissions);
        assertEq(MintableToken(emissionsToken).balanceOf(vaults[1]), collatEmissions);
    }

    // test changeRelayerFee
    function testChangeRelayerFee() public {
        uint256 marketId = createMarketHelper();
        uint256 newFee = 3 gwei;
        vm.expectRevert(VaultFactoryV2.NotTimeLocker.selector);
        factory.changeRelayerFee(newFee, marketId);

        // get time locker
        address timeLocker = address(factory.timelocker());

        vm.startPrank(timeLocker);
        vm.expectRevert(CarouselFactory.InvalidRelayerFee.selector);
        factory.changeRelayerFee(9000, marketId); // revert if fee  is less than 10000 to not cause devide by zero error

        vm.expectRevert(abi.encodeWithSelector(VaultFactoryV2.MarketDoesNotExist.selector, 100));
        factory.changeRelayerFee(newFee, 100); // revert if market does not exist

        // test success case
        factory.changeRelayerFee(newFee, marketId);
        assertEq(ICarousel(factory.getVaults(marketId)[0]).relayerFee(), newFee);
        assertEq(ICarousel(factory.getVaults(marketId)[1]).relayerFee(), newFee);

        vm.stopPrank();
    }

    // tes test changeClosingTimeFrame
    // function testChangeClosingTimeFrame() public {
    //     uint256 marketId = createMarketHelper();
    //     uint40 newTimeFrame = 1000;
    //     vm.expectRevert(VaultFactoryV2.NotTimeLocker.selector);
    //     factory.changeClosingTimeFrame(newTimeFrame, marketId);

    //     // get time locker
    //     address timeLocker = address(factory.timelocker());

    //     vm.startPrank(timeLocker);
    //     vm.expectRevert(abi.encodeWithSelector(VaultFactoryV2.MarketDoesNotExist.selector, 100));
    //     factory.changeClosingTimeFrame(newTimeFrame, 100); // revert if market does not exist

    //     vm.expectRevert(CarouselFactory.InvalidClosingTimeFrame.selector);
    //     factory.changeClosingTimeFrame(0, marketId); // revert if time frame is 0

    //     // test success case
    //     factory.changeClosingTimeFrame(newTimeFrame, marketId);
    //     assertEq(ICarousel(factory.getVaults(marketId)[0]).closingTimeFrame(), newTimeFrame);
    //     assertEq(ICarousel(factory.getVaults(marketId)[1]).closingTimeFrame(), newTimeFrame);

    //     vm.stopPrank();
    // }    

    // test changeDepositFee
    function testChangeDepositFee() public {
        uint256 marketId = createMarketHelper();
        uint16 newFee = 25; // 2%
        vm.expectRevert(VaultFactoryV2.NotTimeLocker.selector);
        factory.changeDepositFee(newFee, marketId, 0);

        // get time locker
        address timeLocker = address(factory.timelocker());

        vm.startPrank(timeLocker);
        vm.expectRevert(CarouselFactory.InvalidDepositFee.selector);
        factory.changeDepositFee(11000, marketId, 0); // revert if fee is greater than 100%

        vm.expectRevert(abi.encodeWithSelector(VaultFactoryV2.MarketDoesNotExist.selector, 100));
        factory.changeDepositFee(newFee, 100, 0); // revert if market does not exist

        // test success case
        // change fee for premium vault
        factory.changeDepositFee(newFee, marketId, 0);
        assertEq(ICarousel(factory.getVaults(marketId)[0]).depositFee(), newFee);
        // check if collateral vault fee is not changed
        assertEq(ICarousel(factory.getVaults(marketId)[1]).depositFee(), depositFee);

        // change fee for collateral vault
        factory.changeDepositFee(newFee, marketId, 1);
        assertEq(ICarousel(factory.getVaults(marketId)[1]).depositFee(), newFee);
        vm.stopPrank();
    }

    function createMarketHelper() public returns(uint256 marketId){

        // create market
        address token = address(0x1);
        address oracle = address(0x3);
        address underlying = address(0x4);
        uint256 strike = uint256(0x2);
        string memory name = string("");
        string memory symbol = string("");

        (
            ,
            ,
            marketId
        ) = factory.createNewCarouselMarket(
          CarouselFactory.CarouselMarketConfigurationCalldata( 
                token,
                strike,
                oracle,
                underlying,
                name,
                symbol,
                controller,
                relayerFee,
                depositFee)
        );
    }

}