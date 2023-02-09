// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../Helper.sol";
import "../../../src/V2/Carousel/CarouselFactory.sol";
import "../../../src/V2/interfaces/ICarousel.sol";


contract CarouselFactoryTest is Helper { 
    using stdStorage for StdStorage;

        CarouselFactory factory;
        address controller;
        address emissionsToken;
        uint256 relayerFee;
        uint256 closingTimeFrame;
        uint256 lateDepositFee;
   
        function setUp() public {

        emissionsToken = address(new MintableToken("Emissions Token", "EMT"));

        factory = new CarouselFactory(
            ADMIN,
            WETH,
            TREASURY,
            emissionsToken
        );

        controller = address(0x54);
        factory.whitelistController(address(controller));

        relayerFee = 2 gwei;
        closingTimeFrame = 1 hours;
        lateDepositFee = 1000; // 1%
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
                closingTimeFrame,
                lateDepositFee
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
        assertEq(ICarousel(premium).lateDepositFee(), lateDepositFee);
        assertEq(ICarousel(collateral).lateDepositFee(), lateDepositFee);

        // test if closing time frame is set
        assertEq(ICarousel(premium).closingTimeFrame(), closingTimeFrame);
        assertEq(ICarousel(collateral).closingTimeFrame(), closingTimeFrame);

        // test if relayer fee is set
        assertEq(ICarousel(premium).relayerFee(), relayerFee);
        assertEq(ICarousel(collateral).relayerFee(), relayerFee);

        // test emissions token is set
        assertEq(ICarousel(premium).emissionsToken(), emissionsToken);
        assertEq(ICarousel(collateral).emissionsToken(), emissionsToken);
    }

    function testCarouselEpochDeloyment() public {
    
        // create market
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
                closingTimeFrame,
                lateDepositFee
            )
        );


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
        (uint40 fetchedBegin, uint40 fetchedEnd) = IVaultV2(vaults[0]).getEpochConfig(epochId2);
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

}