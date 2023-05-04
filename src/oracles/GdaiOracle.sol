// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "forge-std/console.sol";
    
interface IGNS {
    function tvl() external view returns (uint256);
    function totalSupply() external view returns (uint256);    
}

interface IUniswapV3Factory {
    function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address pool);
}

interface IUniswapV3Pool {
    function getLiquidity() external view returns (uint128);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function slot0() external view returns (uint160 sqrtPriceX96, int24 tick, uint16 observationIndex, uint16 observationCardinality, uint16 observationCardinalityNext, uint8 feeProtocol, bool unlocked);
}

contract GdaiOracle {
    IGNS public gnsToken;
    IUniswapV3Pool public uniswapPool;
    uint8 public decimals;

    constructor(address _gnsTokenAddress, address _daiTokenAddress, address _uniswapPoolV3) {
    
        address _daiTokenAddress = address(_daiTokenAddress);
        gnsToken = IGNS(_gnsTokenAddress);
        uniswapPool = IUniswapV3Pool(_uniswapPoolV3);
        decimals = 18; //TODO - Look up this number
    }

    function getTVL() public view returns (uint256) {
        return gnsToken.tvl();
    }
    
    function getDecimals() public view returns (uint8){
        return decimals;
    }
    
    function getTotalSupply() public view returns (uint8) {
        return decimals;
    }

    function getLatestGNSPrice() public view returns (uint256) {
        (uint160 sqrtPriceX96,,,,,,) = uniswapPool.slot0();

        uint256 price = (uint256(sqrtPriceX96)**2 * 10**decimals) >> (96 * 2);

        if (uniswapPool.token0() == address(gnsToken)) {
            return price;
        } else {
            return uint256(1 ether) / price;
        }
    }

    function getCollateralizationRatio() public view returns (uint256) {
        uint256 tvl = gnsToken.tvl();
        uint256 gnsPrice = getLatestGNSPrice();
        uint256 gnsTotalSupply = gnsToken.totalSupply();

        uint256 gnsMarketCap = gnsTotalSupply * gnsPrice / (10**decimals);
        uint256 collateralizationRatio = (tvl * 10**decimals) / gnsMarketCap;

        return collateralizationRatio;
    }

}
