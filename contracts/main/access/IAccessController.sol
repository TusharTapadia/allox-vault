// SPDX-License-Identifier: MIT

/**
 * @title IAccessController
 * @notice Interface to specify and grant different roles
 */

pragma solidity 0.8.20;

interface IAccessController {
  function setupRole(bytes32 role, address account) external;

  function hasRole(bytes32 role, address account) external view returns (bool);

  function setUpRoles(address _creatorAddress, address _strategyManagerAddress, address _vaultAddress) external;
}
