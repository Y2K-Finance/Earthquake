import "../Helper.sol";
import {MultiCaller} from "../../../script/multicallV2/MultiCaller.sol";
import {CarouselFactory} from "../../../src/v2/Carousel/CarouselFactory.sol";
import {HelperV2} from "../../../script/v2/V2Helper.sol";
import "forge-std/console.sol";

contract MultiCallerTest is Helper, HelperV2 {
    // MultiCaller info
    MultiCaller public multiCaller;
    uint256 arbitrumFork;

    // Config variables
    uint256 public preDeployTimeAug13 = 1691956818;
    uint256 public preDeployBlockAug13 = 121122450;
    address public carouselFactory = 0xC3179AC01b7D68aeD4f27a19510ffe2bfb78Ab3e;
    address public genericController =
        0xDff5d76A5EcD9E3190FE8974c920775c987c442e;
    address public factoryOwner = 0x45aA9d8B9D567489be9DeFcd085C6bA72BBf344F;

    function setUp() public {
        arbitrumFork = vm.createFork(ARBITRUM_RPC_URL);
        vm.selectFork(arbitrumFork);

        vm.warp(preDeployTimeAug13);
        vm.rollFork(preDeployBlockAug13);

        multiCaller = new MultiCaller(carouselFactory, genericController);

        // Transfer Ownership from the owner to the multicaller
        CarouselFactory cFactory = CarouselFactory(carouselFactory);
        vm.startPrank(factoryOwner);
        cFactory.transferOwnership(address(multiCaller));
        vm.stopPrank();

        assertEq(cFactory.owner(), address(multiCaller));

        // Setting up the config
        setVariables();

        configAddresses = getConfigAddresses(false); //true if test env

        contractToAddresses(configAddresses);
    }

    function test_deployNewMarkets() public {
        (
            CarouselFactory.CarouselMarketConfigurationCalldata[]
                memory _marketConfig,
            uint256[] memory _depegCondition
        ) = _getNewMarketInfo();
        multiCaller.deployMarkets(_marketConfig, _depegCondition);
    }

    function test_deployNewEpochs() public {
        (
            MultiCaller.EpochConfig[] memory _epochConfig,
            MultiCaller.KeeperConfig[] memory _keeperConfig
        ) = _getNewEpochInfo();
        multiCaller.deployEpochs(_epochConfig, _keeperConfig);
    }

    ////////////////////////////////////////////////
    //                HELPERS                     //
    ////////////////////////////////////////////////
    function _getNewEpochInfo()
        internal
        returns (
            MultiCaller.EpochConfig[] memory _epochConfig,
            MultiCaller.KeeperConfig[] memory _keeperConfig
        )
    {
        ConfigEpochWithEmission[] memory epochs = getConfigEpochs();

        // NOTE: Getting fixed amount of epochs for test
        uint256 fixedLength = 8;

        _epochConfig = new MultiCaller.EpochConfig[](fixedLength);
        _keeperConfig = new MultiCaller.KeeperConfig[](fixedLength);

        for (uint256 i; i < fixedLength - 1; ) {
            ConfigEpochWithEmission memory epoch = epochs[i];
            address depositAsset = getDepositAsset(epoch.depositAsset);
            uint256 strikePrice = stringToUint(epoch.strikePrice);
            uint256 marketId = factory.getMarketId(
                epoch.token,
                strikePrice,
                depositAsset
            );

            _epochConfig[i] = MultiCaller.EpochConfig(
                marketId,
                epoch.epochBegin,
                epoch.epochEnd,
                500,
                0, // stringToUint(epoch.premiumEmissions)
                0 // stringToUint(epoch.collatEmissions)
            );

            _keeperConfig[i].resolver = epoch.isGenericController
                ? marketId ==
                    98949310992640213851983765150833189432751758546965601760898583298872224793782
                    ? configAddresses.resolveKeeperGeneric
                    : configAddresses.resolveKeeperGenericPausable
                : configAddresses.resolveKeeper;
            _keeperConfig[i].rollover = epoch.isGenericController
                ? marketId ==
                    98949310992640213851983765150833189432751758546965601760898583298872224793782
                    ? configAddresses.rolloverKeeper
                    : configAddresses.rolloverKeeperPausable
                : configAddresses.rolloverKeeper;

            unchecked {
                i++;
            }
        }
    }

    function _getNewMarketInfo()
        internal
        returns (
            CarouselFactory.CarouselMarketConfigurationCalldata[]
                memory _marketConfig,
            uint256[] memory _depegCondition
        )
    {
        ConfigMarketV2[] memory markets = getConfigMarket();
        _marketConfig = new CarouselFactory.CarouselMarketConfigurationCalldata[](
            markets.length
        );
        _depegCondition = new uint256[](markets.length);

        for (uint256 i = 0; i < markets.length; ) {
            ConfigMarketV2 memory market = markets[i];
            address controller = getController(market.isGenericController);
            address depositAsset = getDepositAsset(market.depositAsset);
            uint256 strkePrice = stringToUint(market.strikePrice);
            _marketConfig[i] = CarouselFactory
                .CarouselMarketConfigurationCalldata(
                    market.token,
                    strkePrice,
                    market.oracle,
                    depositAsset,
                    market.name,
                    market.uri,
                    controller,
                    stringToUint(market.relayFee),
                    market.depositFee,
                    stringToUint(market.minQueueDeposit)
                );

            if (market.isGenericController) {
                _depegCondition[i] = market.isDepeg ? 2 : 1;
            }
            unchecked {
                i++;
            }
        }
    }
}
