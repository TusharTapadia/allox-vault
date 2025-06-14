// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IProtocolRegistry {
    function getPriceOracle() external view returns (address);
    function getWETH() external view returns (address);
    function getProtocolPause() external view returns (bool);
    function getProtocolFee() external view returns (uint256);
    function getTreasury() external view returns (address);
    function isEnabled(address _token) external view returns (bool);
    
    
    struct TokenRecord {
        bool enabled;
        address handler;
    }

    function getTokenInformation(address _token) external view returns (TokenRecord memory);
}
