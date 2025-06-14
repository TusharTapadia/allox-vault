// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IVaultManagerConfig {
    // Events
    event VaultManagerFeesUpdated(uint256 fees);
    event TokenAllowed(address token);
    event TokenDisallowed(address token);

    // View functions
    function accessController() external view returns (address);
    function vaultManagerFees() external view returns (uint256);
    function allowedTokens(address token) external view returns (bool);

    // State changing functions
    function initialize(address _accessController, address _protocolRegistry) external;
    function setVaultManagerFees(uint256 _fees) external;
    function allowDepositToken(address[] memory tokens) external;
    function disallowDepositToken(address[] memory tokens) external;
}
