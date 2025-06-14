// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {AggregatorV2V3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

interface IPriceOracle {
    // Events
    event addFeed(address[] base, address[] quote, AggregatorV2V3Interface[] aggregator);
    event updateFeed(address base, address quote, address aggregator);

    // View functions
    function WETH() external view returns (address);
    function oracleExpirationThreshold() external view returns (uint256);
    function decimals(address base, address quote) external view returns (uint8);
    function getUsdEthPrice(uint256 amountIn) external view returns (uint256 amountOut);
    function getEthUsdPrice(uint256 amountIn) external view returns (uint256 amountOut);
    function getPrice(address base, address quote) external view returns (int256);
    function getPriceForAmount(address token, uint256 amount, bool ethPath) external view returns (uint256 amountOut);
    function getPriceForTokenAmount(address tokenIn, address tokenOut, uint256 amount) external view returns (uint256 amountOut);
    function getPriceTokenUSD18Decimals(address _base, uint256 amountIn) external view returns (uint256 amountOut);
    function getPriceUSDToken(address _base, uint256 amountIn) external view returns (uint256 amountOut);
    function getPriceForOneTokenInUSD(address _base) external view returns (uint256 amountOut);

    // State changing functions
    function _addFeed(
        address[] memory base,
        address[] memory quote,
        AggregatorV2V3Interface[] memory aggregator
    ) external;
    
    function _updateFeed(
        address base,
        address quote,
        AggregatorV2V3Interface aggregator
    ) external;

    function updateOracleExpirationThreshold(uint256 _newTimeout) external;
}
