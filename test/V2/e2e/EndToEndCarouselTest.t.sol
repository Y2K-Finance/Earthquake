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
    uint256 public queueLength;

    uint40 public begin;
    uint40 public end;

    uint16 public fee;

    string public ARBITRUM_RPC_URL = vm.envString("ARBITRUM_RPC_URL");

    function setUp() public {
        arbForkId = vm.createFork(ARBITRUM_RPC_URL);
        vm.selectFork(arbForkId);

        emissionsToken = address(new MintableToken("Emissions Token", "EMT"));
        UNDERLYING = address(new MintableToken("UnderLyingToken", "utkn"));

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
        fee = uint16(50); //0,5%
        premiumEmissions = 1000 ether;
        collatEmissions = 100 ether;

        // approve emissions token to factory
        vm.startPrank(TREASURY);

        MintableToken(emissionsToken).mint(address(TREASURY), 5000);
        MintableToken(emissionsToken).approve(address(factory),  5000 ether);

        vm.stopPrank();

       ( epochId, ) = factory.createEpochWithEmissions(
                marketId,
                begin,
                end,
                fee,
                premiumEmissions,
                collatEmissions
        );

        deal(UNDERLYING, USER, 1000 ether, true);
        deal(UNDERLYING, USER2, 1000 ether, true);

    }

    function testEndToEndCarousel() public {
        vm.startPrank(USER);

        //warp to deposit period
        vm.warp(begin - 1 days);
        
        //deal ether
        vm.deal(USER, 20 ether);

        //approve ether deposit
        IERC20(UNDERLYING).approve(premium, 10 ether);

        //deposit in carousel vaults
        Carousel(premium).deposit(0, 10 ether, USER);

        vm.stopPrank();

        vm.startPrank(USER2);

         //warp to deposit period
        vm.warp(begin - 1 days);
        
        //deal ether
        vm.deal(USER2, 20 ether);

        //approve ether deposit
        IERC20(UNDERLYING).approve(premium, 10 ether);

        //deposit in carousel vaults
        Carousel(premium).deposit(0, 10 ether, USER2);

        vm.stopPrank();

        //warp to deposit period
        vm.warp(begin - 1 days);

        //assert queue length
        queueLength = 2;
        assertEq(Carousel(premium).getDepositQueueLenght(), queueLength);

        //mint deposit in queue
        Carousel(premium).mintDepositInQueue(epochId, queueLength);

        //assert balance and emissions
        assertEq(Carousel(premium).balanceOf(USER, epochId), 10 ether - relayerFee);
        assertEq(Carousel(premium).balanceOfEmissions(USER, epochId), 10 ether - relayerFee);
        assertEq(Carousel(premium).balanceOf(USER2, epochId), 10 ether - relayerFee);
        assertEq(Carousel(premium).balanceOfEmissions(USER2, epochId), 10 ether - relayerFee);

        vm.stopPrank();
    }
}