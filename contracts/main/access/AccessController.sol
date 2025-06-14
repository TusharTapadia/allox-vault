// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ErrorLibrary} from "../../library/ErrorLibrary.sol";

/**
 * @title AccessController
 * @notice This contract manages access control for the protocol using OpenZeppelin's AccessControl
 * @dev Inherits from OpenZeppelin's AccessControl contract to implement role-based access control
 */
contract AccessController is AccessControl {

    /**
     * @notice Role identifier for super administrators with highest level of access
     * @dev This role has the ability to manage all other roles and protocol settings
     */
    bytes32 public constant SUPER_ADMIN_ROLE = keccak256("SUPER_ADMIN_ROLE");

    /**
     * @notice Role identifier for strategy managers who can manage investment strategies
     * @dev This role has permissions to create and modify investment strategies
     */
    bytes32 public constant STRATEGY_MANAGER_ROLE = keccak256("STRATEGY_MANAGER_ROLE");

    /**
     * @notice Role identifier for vault contracts
     * @dev This role is assigned to vault contracts to allow them to interact with the protocol
     */
    bytes32 public constant VAULT_ROLE = keccak256("VAULT_ROLE");

    /**
     * @notice Role identifier for vault managers who can manage vault operations
     * @dev This role has permissions to manage vault settings and operations
     */
    bytes32 public constant VAULT_MANAGER_ROLE = keccak256("VAULT_MANAGER_ROLE");

    /**
     * @notice Initializes the contract and sets up the default admin role
     * @dev The deployer of the contract is automatically assigned the DEFAULT_ADMIN_ROLE
     */
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice Modifier to restrict function access to admin role holders
     * @dev Reverts with CallerNotAdmin error if the caller doesn't have admin role
     */
    modifier onlyAdmin() {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert ErrorLibrary.CallerNotAdmin();
        }
        _;
    }

    /**
     * @notice Grants a specific role to an address
     * @dev Only callable by addresses with DEFAULT_ADMIN_ROLE
     * @param role The role identifier to grant
     * @param account The address to grant the role to
     */
    function setupRole(bytes32 role, address account) public onlyAdmin {
        _setupRole(role, account);
    }

    /**
     * @notice Sets up initial roles for core protocol addresses
     * @dev Only callable by addresses with DEFAULT_ADMIN_ROLE
     * @param _creatorAddress Address of the protocol creator
     * @param _strategyManagerAddress Address of the strategy manager
     * @param _vaultAddress Address of the vault contract
     */
    function setupInitialRoles(address _creatorAddress, address _strategyManagerAddress, address _vaultAddress) public onlyAdmin {
        _setupRole(SUPER_ADMIN_ROLE, _creatorAddress);
        _setupRole(STRATEGY_MANAGER_ROLE, _strategyManagerAddress);
        _setupRole(VAULT_ROLE, _vaultAddress);
        _setupRole(VAULT_MANAGER_ROLE, _creatorAddress);
    }
}
