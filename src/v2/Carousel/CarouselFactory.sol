// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../VaultFactoryV2.sol";
// import "./Carousel.sol";
// import "./CarouselWETH.sol";

import {ICarousel} from "../interfaces/ICarousel.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {CarouselCreator} from "../libraries/CarouselCreator.sol";

/// @author Y2K Finance Team

contract CarouselFactory is VaultFactoryV2 {
    using SafeERC20 for IERC20;
    IERC20 public emissionsToken;

    /** @notice constructor
    @param _weth address of the weth contract
    @param _treasury address of the treasury contract
    @param _emissoinsToken address of the emissions token
     */
    constructor(
        address _weth,
        address _treasury,
        address _timelock,
        address _emissoinsToken
    ) VaultFactoryV2(_weth, _treasury, _timelock) {
        if(_emissoinsToken == address(0)) revert AddressZero();
        emissionsToken = IERC20(_emissoinsToken);
    }

    /**
    @notice Function to create two new vaults, premium and collateral, with the respective params, and storing the oracle for the token provided
    @param  _marketCalldata CarouselMarketConfigurationCalldata struct with the market params
    @return premium address of the premium vault
    @return collateral address of the collateral vault
    @return marketId uint256 of the marketId
     */
    function createNewMarket(
        bytes calldata _marketCalldata
    )
        external
        override
        onlyOwner
        returns (
            address premium,
            address collateral,
            uint256 marketId
        )
    {
        CarouselMarketConfigurationCalldata memory data = abi.decode(_marketCalldata, (CarouselMarketConfigurationCalldata));
        if (!controllers[data.controller]) revert ControllerNotSet();
        if (data.token == address(0)) revert AddressZero();
        if (data.oracle == address(0)) revert AddressZero();
        if (data.underlyingAsset == address(0)) revert AddressZero();

        if (tokenToOracle[data.token] == address(0)) {
            tokenToOracle[data.token] = data.oracle;
        }

        marketId = getMarketId(data.token, data.strike);
        if (marketIdToVaults[marketId][0] != address(0))
            revert MarketAlreadyExists();

        //y2kUSDC_99*PREMIUM
        premium = CarouselCreator.createCarousel(
            CarouselCreator.CarouselMarketConfiguration(
                 data.underlyingAsset == WETH,
                data.underlyingAsset,
                string(abi.encodePacked(data.name, PREMIUM)),
                string(PSYMBOL),
                data.tokenURI,
                data.token,
                data.strike,
                data.controller,
                treasury,
                address(emissionsToken),
                data.relayerFee,
                data.depositFee
            )
        );

        // y2kUSDC_99*COLLATERAL
        collateral =  CarouselCreator.createCarousel(
            CarouselCreator.CarouselMarketConfiguration(
                data.underlyingAsset == WETH,
                data.underlyingAsset,
                string(abi.encodePacked(data.name, COLLAT)),
                string(CSYMBOL),
                data.tokenURI,
                data.token,
                data.strike,
                data.controller,
                treasury,
                address(emissionsToken),
                data.relayerFee,
                data.depositFee
            )
        );

        //set counterparty vault
        ICarousel(premium).setCounterPartyVault(collateral);
        ICarousel(collateral).setCounterPartyVault(premium);

        marketIdToVaults[marketId] = [premium, collateral];

        emit MarketCreated(
            marketId,
            premium,
            collateral,
            data.underlyingAsset,
            data.token,
            data.name,
            data.strike,
            data.controller
        );

        return (premium, collateral, marketId);
    }

    /** @notice Function to create a new epoch with emissions
    @param _marketId uint256 of the marketId
    @param _epochBegin uint40 of the epoch begin
    @param _epochEnd uint40 of the epoch end
    @param _withdrawalFee uint16 of the withdrawal fee
    @param _permiumEmissions uint256 of the emissions for the premium vault
    @param _collatEmissions uint256 of the emissions for the collateral vault
    @return epochId uint256 of the epochId
    @return vaults address[2] of the vaults
     */
    function createEpochWithEmissions(
        uint256 _marketId,
        uint40 _epochBegin,
        uint40 _epochEnd,
        uint16 _withdrawalFee,
        uint256 _permiumEmissions,
        uint256 _collatEmissions
    ) public returns (uint256 epochId, address[2] memory vaults) {
        // no need for onlyOwner modifier as createEpoch already has modifier
        (epochId, vaults) = createEpoch(
            _marketId,
            _epochBegin,
            _epochEnd,
            _withdrawalFee
        );

        emissionsToken.safeTransferFrom(treasury, vaults[0], _permiumEmissions);
        ICarousel(vaults[0]).setEmissions(epochId, _permiumEmissions);

        emissionsToken.safeTransferFrom(treasury, vaults[1], _collatEmissions);
        ICarousel(vaults[1]).setEmissions(epochId, _collatEmissions);
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /** @notice Function to deploy a new Carousel vault
    @param _marketConfig CarouselMarketConfiguration struct with the vault params
    @return address of the new vault
     */
    function _deployCarouselVault(
        CarouselCreator.CarouselMarketConfiguration memory _marketConfig
    ) internal returns (address) {
        // if (_marketConfig.underlyingAsset == WETH) {
        //     return
        //         address(
        //             new CarouselWETH(
        //                 Carousel.ConstructorArgs(
        //                 _marketConfig.underlyingAsset,
        //                 _marketConfig.name,
        //                 _marketConfig.symbol,
        //                 _marketConfig.tokenURI,
        //                 _marketConfig.token,
        //                 _marketConfig.strike,
        //                 _marketConfig.controller,
        //                 treasury,
        //                 address(emissionsToken),
        //                 _marketConfig.relayerFee,
        //                 _marketConfig.depositFee
        //                 )
        //             )
        //         );
        // } else {
        //     return
        //         address(
        //             new Carousel(
                      
        //             )
        //         );
        // }
    }

    /*//////////////////////////////////////////////////////////////
                                ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /** @notice Function to change the relayer fee
    @param _relayerFee uint256 of the relayer fee
    @param _marketIndex uint256 of the market index
     */
    function changeRelayerFee(uint256 _relayerFee, uint256 _marketIndex)
        public
        onlyTimeLocker
    {
        if (_relayerFee < 10000) revert InvalidRelayerFee();

        address[2] memory vaults = marketIdToVaults[_marketIndex];
        if (vaults[0] == address(0)) revert MarketDoesNotExist(_marketIndex);
        ICarousel insr = ICarousel(vaults[0]);
        ICarousel risk = ICarousel(vaults[1]);
        insr.changeRelayerFee(_relayerFee);
        risk.changeRelayerFee(_relayerFee);

        emit ChangedRelayerFee(_relayerFee, _marketIndex);
    }

    function changeDepositFee(uint256 _depositFee, uint256 _marketIndex, uint256 vaultIndex)
        public
        onlyTimeLocker
    {
        if(vaultIndex > 1) revert InvalidVaultIndex();
        // _depositFee is in basis points max 0.5%
        if (_depositFee > 250) revert InvalidDepositFee();
        // TODO might need to be able to change individual vaults
        address[2] memory vaults = marketIdToVaults[_marketIndex];
        if (vaults[vaultIndex] == address(0)) revert MarketDoesNotExist(_marketIndex);
        ICarousel(vaults[vaultIndex]).changeDepositFee(_depositFee);

        emit ChangedDepositFee(_depositFee, _marketIndex, vaultIndex, vaults[vaultIndex]);
    }

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct CarouselMarketConfigurationCalldata {
        address token;
        uint256 strike;
        address oracle;
        address underlyingAsset;
        string name;
        string tokenURI;
        address controller;
        uint256 relayerFee;
        uint256 depositFee;
    }

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error InvalidRelayerFee();
    error InvalidVaultIndex();
    error InvalidDepositFee();


    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event ChangedDepositFee(
        uint256 depositFee,
        uint256 marketIndex,
        uint256 vaultIndex,
        address vault
    );

    event ChangedRelayerFee(uint256 relayerFee, uint256 marketIndex);


}
