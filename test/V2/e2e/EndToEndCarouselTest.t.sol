pragma solidity 0.8.17;

import "../Helper.sol";
import "../../../src/V2/Carousel/CarouselFactory.sol";
import "../../../src/V2/interfaces/ICarousel.sol";

CarouselFactory factory;

address controller;
address emissionsToken;

uint256 relayerFee;
uint256 depositFee;

contract EndToEndCarouselTest is Helper {
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
        depositFee = 100; // 1%

        address token = address(0x1);
        address oracle = address(0x3);
        address underlying = address(0x4);
        uint256 strike = uint256(0x2);
        string memory name = string("");
        string memory symbol = string("");

        // deploy market
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

        // deploy epoch
        uint40 begin = uint40(0x3);
        uint40 end = uint40(0x4);
        uint16 fee = uint16(0x5);
        uint256 premiumEmissions = 1000 ether;
        uint256 collatEmissions = 100 ether;

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
    }

    function testEndToEndCarousel() public {

    }
}