pragma solidity 0.8.17;

import "../VaultV2Pausable.sol";

library VaultV2CreatorPausable {
    struct MarketConfiguration {
        bool isWETH;
        address underlyingAsset;
        string name;
        string symbol;
        string tokenURI;
        address token;
        uint256 strike;
        address controller;
        address treasury;
    }

    function createPausableVaultV2(
        MarketConfiguration memory _marketConfig
    ) public returns (address) {
        return
            address(
                new VaultV2Pausable(
                    _marketConfig.isWETH,
                    _marketConfig.underlyingAsset,
                    _marketConfig.name,
                    _marketConfig.symbol,
                    _marketConfig.tokenURI,
                    _marketConfig.token,
                    _marketConfig.strike,
                    _marketConfig.controller
                )
            );
    }
}
