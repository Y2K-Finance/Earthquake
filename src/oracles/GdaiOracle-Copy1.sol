// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/interfaces/AggregatorV3Interface.sol";
import "@chainlink/interfaces/AggregatorV2V3Interface.sol";


interface IGNS {
    function tvl() external view returns (uint256);
}

contract GdaiOracle {
    IGNS public gnsToken;
    AggregatorV3Interface public gnsPriceFeed;
    uint8 public decimals;

    constructor(address _gnsTokenAddress) {
        gnsToken = IGNS(_gnsTokenAddress);
        address _gnsPriceFeedAddress = address( 0xcef1C791CDd8c3EA92D6AB32399119Fd30E1Ff21 );
        gnsPriceFeed = AggregatorV3Interface(_gnsPriceFeedAddress);
        decimals = 18;
    }

    function getPNL() public view returns (uint256) {
        return gnsToken.tvl();
    }

    function getValue() public view returns (uint256) {
        return gnsToken.tvl();
    }

    function getDecimals() public view returns (uint8) {
        return decimals;
    }

    function getLatestGNSPrice() public view returns (int256) {
        (, int256 price,,,) = gnsPriceFeed.latestRoundData();
        return price;
    }

    function getCollateralizationRatio() public view returns (uint256) {
        uint256 tvl = gnsToken.tvl();
        int256 gnsPrice = getLatestGNSPrice();

        require(gnsPrice > 0, "Invalid GNS price");

        uint256 gnsMarketValue = uint256(gnsPrice);
        uint256 collateralizationRatio = (tvl * 10**decimals) / gnsMarketValue;

        return collateralizationRatio;
    }
}
