pragma solidity 0.8.17;

import "../Carousel/CarouselPausable.sol";

library CarouselCreatorPausable {
    struct CarouselMarketConfiguration {
        bool isWETH;
        address assetAddress;
        string name;
        string symbol;
        string tokenURI;
        address token;
        uint256 strike;
        address controller;
        address treasury;
        address emissionsToken;
        uint256 relayerFee;
        uint256 depositFee;
        uint256 minQueueDeposit;
    }

    function createCarousel(
        CarouselMarketConfiguration memory _marketConfig
    ) public returns (address) {
        return
            address(
                new CarouselPausable(
                    CarouselPausable.ConstructorArgs(
                        _marketConfig.isWETH,
                        _marketConfig.assetAddress,
                        _marketConfig.name,
                        _marketConfig.symbol,
                        _marketConfig.tokenURI,
                        _marketConfig.token,
                        _marketConfig.strike,
                        _marketConfig.controller,
                        _marketConfig.emissionsToken,
                        _marketConfig.relayerFee,
                        _marketConfig.depositFee,
                        _marketConfig.minQueueDeposit
                    )
                )
            );
    }
}
