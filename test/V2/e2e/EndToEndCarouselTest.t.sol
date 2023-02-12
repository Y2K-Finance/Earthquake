pragma solidity 0.8.17;

import "../Helper.sol";
import "../../../src/V2/Carousel/CarouselFactory.sol";
import "../../../src/V2/interfaces/ICarousel.sol";
import "../../../src/V2/Carousel/Carousel.sol";
import "../../../src/V2/Controllers/ControllerPeggedAssetV2.sol";


contract EndToEndCarouselTest is Helper {
    using stdStorage for StdStorage;

    CarouselFactory public factory;
    ControllerPeggedAssetV2 public controller;

    address public emissionsToken;
    address public oracle;
    address public premium;
    address public collateral;

    uint256 public relayerFee;
    uint256 public depositFee;
    uint256 public strike;
    uint256 public marketId;
    uint256 public premiumEmissions;
    uint256 public collatEmissions;
    uint256 public epochId;
    uint256 public arbForkId;

    uint40 public begin;
    uint40 public end;

    uint16 public fee;

    string public ARBITRUM_RPC_URL = vm.envString("ARBITRUM_RPC_URL");

    function setUp() public {
        arbForkId = vm.createFork(ARBITRUM_RPC_URL);
        vm.selectFork(arbForkId);

        emissionsToken = address(new MintableToken("Emissions Token", "EMT"));

        factory = new CarouselFactory(
            ADMIN,
            WETH,
            TREASURY,
            emissionsToken
        );

        controller = new ControllerPeggedAssetV2(address(factory), ARBITRUM_SEQUENCER, TREASURY);
        factory.whitelistController(address(controller));

        relayerFee = 2 gwei;
        depositFee = 50; // 0,5%

        //oracle = address(0x3);
        //strike = uint256(0x2);
        string memory name = string("USD Coin");
        string memory symbol = string("USDC");

        // deploy market
        (
            premium,
            collateral,
            marketId
        ) = factory.createNewCarouselMarket(
            CarouselFactory.CarouselMarketConfigurationCalldata(
                USDC_TOKEN,
                STRIKE,
                USDC_CHAINLINK,
                UNDERLYING,
                name,
                symbol,
                address(controller),
                relayerFee,
                depositFee
            )
        );

        // deploy epoch
        begin = uint40(block.timestamp - 5 days);
        end = uint40(block.timestamp - 3 days);
        fee = uint16(0x5); //0,5%
        premiumEmissions = 1000 ether;
        collatEmissions = 100 ether;

        // approve emissions token to factory
        vm.startPrank(TREASURY);

        MintableToken(emissionsToken).approve(address(factory),  5000 ether);

        vm.stopPrank();


       ( epochId, ) =  factory.createEpochWithEmissions(
                marketId,
                begin,
                end,
                fee,
                premiumEmissions,
                collatEmissions
        );

        emit log_named_uint("epochId: ", epochId);
    }

    function testEndToEndCarousel() public {
        vm.startPrank(USER);

        IERC20(UNDERLYING).approve(address(premium), 10 ether);
        IERC20(UNDERLYING).approve(address(collateral), 2 ether);

        Carousel(premium).deposit(epochId, 10 ether, USER);
        Carousel(collateral).deposit(epochId, 2 ether, USER);

        vm.stopPrank();
    }
}