// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {CarouselFactory} from "../../src/v2/Carousel/CarouselFactory.sol";
import {
    IConditionProvider
} from "../../src/v2/interfaces/IConditionProvider.sol";
import {KeeperV2} from "../keepers/KeeperV2.sol";

contract MultiCaller is Ownable {
    struct EpochConfig {
        uint256 marketId;
        uint40 epochBegin;
        uint40 epochEnd;
        uint16 withdrawalFee;
        uint256 premiumEmissions;
        uint256 collatEmissions;
    }

    struct KeeperConfig {
        address rollover;
        address resolver;
    }

    struct VaultAddresses {
        address[2] vaults;
    }

    CarouselFactory public immutable carouselFactory;
    address public immutable genericController;

    constructor(address _carouselFactory, address _genericController) {
        carouselFactory = CarouselFactory(_carouselFactory);
        genericController = _genericController;
    }

    function deployMarkets(
        CarouselFactory.CarouselMarketConfigurationCalldata[]
            calldata _marketConfig,
        uint256[] calldata _depegCondition
    ) external payable onlyOwner {
        address[] memory prem;
        address[] memory collat;
        uint256[] memory marketId;

        for (uint i; i < _marketConfig.length - 1; ) {
            (prem[i], collat[i], marketId[i]) = carouselFactory
                .createNewCarouselMarket(_marketConfig[i]);

            if (_marketConfig[i].controller == genericController)
                IConditionProvider(_marketConfig[i].oracle).setConditionType(
                    marketId[i],
                    _depegCondition[i]
                );

            unchecked {
                i++;
            }
        }
    }

    function deployEpochs(
        EpochConfig[] calldata _epochConfig,
        KeeperConfig[] calldata _keeperConfig
    ) external payable onlyOwner {
        uint256[] memory epochId;
        VaultAddresses[] memory vaults;

        for (uint i; i < _epochConfig.length - 1; ) {
            (epochId[i], vaults[i].vaults) = carouselFactory
                .createEpochWithEmissions(
                    _epochConfig[i].marketId,
                    _epochConfig[i].epochBegin,
                    _epochConfig[i].epochEnd,
                    _epochConfig[i].withdrawalFee,
                    _epochConfig[i].premiumEmissions,
                    _epochConfig[i].collatEmissions
                );
            unchecked {
                i++;
            }

            uint256 currentId = epochId[i];

            KeeperV2(_keeperConfig[i].resolver).startTask(
                _epochConfig[i].marketId,
                currentId
            );
            KeeperV2(_keeperConfig[i].rollover).startTask(
                _epochConfig[i].marketId,
                currentId
            );
        }
    }
}
