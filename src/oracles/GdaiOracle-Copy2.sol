// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "forge-std/console.sol";
//interface IERC20 {
//    function balanceOf(address account) external view returns (uint256);
//}

interface IGNS {
    function tvl() external view returns (uint256);
}
//
interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

contract GdaiOracle {
    IGNS public gnsToken;
    //IERC20 public daiToken;
    IUniswapV2Pair public uniswapPair;
    uint8 public decimals;

    constructor(address _gnsTokenAddress) {
        //address _daiTokenAddress = address(0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1);
        address _daiTokenAddress = address(0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1);
        address _uniswapFactoryAddress = address(0x6554AD1Afaa3f4ce16dc31030403590F467417A6);
        gnsToken = IGNS(_gnsTokenAddress);
        //daiToken = IERC20(_daiTokenAddress);

        // Fetch the Uniswap pair address dynamically
        IUniswapV2Factory uniswapFactory = IUniswapV2Factory(_uniswapFactoryAddress);
        //address _uniswapPairAddress = uniswapFactory.getPair(_gnsTokenAddress, _daiTokenAddress);
        //address _uniswapPairAddress = uniswapFactory.getPair(_daiTokenAddress,_gnsTokenAddress);
        //
        address _uniswapPairAddress = address(0x3bFE2e1745c586FeA5BcBEAB418F6544960944e6);
        console.log(_uniswapPairAddress);
        require(_uniswapPairAddress != address(0), "Uniswap pair not found");

        uniswapPair = IUniswapV2Pair(_uniswapPairAddress);
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

    function getLatestGNSPrice() public view returns (uint256) {
        (uint112 reserve0, uint112 reserve1,) = uniswapPair.getReserves();

        if (uniswapPair.token0() == address(gnsToken)) {
            return (uint256(reserve1) * 10**decimals) / reserve0;
        } else {
            return (uint256(reserve0) * 10**decimals) / reserve1;
        }
    }

    function getCollateralizationRatio() public view returns (uint256) {
        uint256 tvl = gnsToken.tvl();
        uint256 gnsPrice = getLatestGNSPrice();

        uint256 gnsMarketValue = gnsPrice;
        uint256 collateralizationRatio = (tvl * 10**decimals) / gnsMarketValue;

        return collateralizationRatio;
    }
}
