// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {IAccessController} from "../access/IAccessController.sol";
import {IProtocolRegistry} from "../registry/IProtocolRegistry.sol";
import {ErrorLibrary} from "../../library/ErrorLibrary.sol";

/**
 * @title VaultManagerConfig
 * @notice Configuration contract for vault managers to control fees and allowed deposit tokens
 * @dev Implements UUPS upgradeability pattern and includes reentrancy protection
 * @dev Manages vault manager fees and whitelist of allowed deposit tokens
 */
contract VaultManagerConfig is Initializable, OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable {
    /// @notice Interface for the access control contract
    IAccessController public accessController;
    
    /// @notice Fee percentage for vault managers in basis points (1 basis point = 0.01%)
    uint256 public vaultManagerFees;
    
    /// @notice Mapping of token addresses to their allowed status for deposits
    mapping(address => bool) public allowedTokens;
    
    /// @notice Interface for the protocol registry contract
    IProtocolRegistry public protocolRegistry;

    /**
     * @notice Emitted when vault manager fees are updated
     * @param fees New fee percentage in basis points
     */
    event VaultManagerFeesUpdated(uint256 fees);

    /**
     * @notice Emitted when tokens are allowed for deposits
     * @param tokens Array of token addresses that were allowed
     */
    event TokenAllowed(address[] tokens);

    /**
     * @notice Emitted when tokens are disallowed for deposits
     * @param tokens Array of token addresses that were disallowed
     */
    event TokenDisallowed(address[] tokens);

    /**
     * @notice Initializes the vault manager configuration
     * @dev Can only be called once during contract deployment
     * @param _accessController Address of the access control contract
     * @param _protocolRegistry Address of the protocol registry contract
     */
    function initialize(address _accessController, address _protocolRegistry) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        if(_accessController == address(0)) revert ErrorLibrary.ZERO_ADDRESS();
        if(_protocolRegistry == address(0)) revert ErrorLibrary.ZERO_ADDRESS();
        accessController = IAccessController(_accessController);
        protocolRegistry = IProtocolRegistry(_protocolRegistry);
    }

    /**
     * @notice Modifier to restrict function access to vault managers
     * @dev Reverts with CallerNotVaultManager error if the caller doesn't have vault manager role
     */
    modifier onlyVaultManager() {
        if (!accessController.hasRole(keccak256("VAULT_MANAGER_ROLE"), msg.sender)) revert ErrorLibrary.CallerNotVaultManager();
        _;
    }

    /**
     * @notice Sets the vault manager fee percentage
     * @dev Only callable by vault managers
     * @dev Fee must be less than or equal to 10% (1000 basis points)
     * @param _fees New fee percentage in basis points
     */
    function setVaultManagerFees(uint256 _fees) external onlyVaultManager {
        if(_fees > 1000) revert ErrorLibrary.InvalidFee();
        vaultManagerFees = _fees;
        emit VaultManagerFeesUpdated(_fees);
    }

    /**
     * @notice Allows specified tokens for deposits
     * @dev Only callable by vault managers
     * @dev Tokens must be enabled in the protocol registry
     * @param tokens Array of token addresses to allow for deposits
     */
    function allowDepositToken(address [] memory tokens) external onlyVaultManager {
        for (uint256 i = 0; i < tokens.length; i++) {
            if(tokens[i] == address(0)) revert ErrorLibrary.ZERO_ADDRESS();
            IProtocolRegistry.TokenRecord memory tokenInfo = protocolRegistry.getTokenInformation(tokens[i]);
            if(!tokenInfo.enabled) revert ErrorLibrary.InvalidToken();
            allowedTokens[tokens[i]] = true;
        }
        emit TokenAllowed(tokens);
    }

    /**
     * @notice Disallows specified tokens for deposits
     * @dev Only callable by vault managers
     * @param tokens Array of token addresses to disallow for deposits
     */
    function disallowDepositToken(address [] memory tokens) external onlyVaultManager {
        for (uint256 i = 0; i < tokens.length; i++) {
            if(tokens[i] == address(0)) revert ErrorLibrary.ZERO_ADDRESS();
            allowedTokens[tokens[i]] = false;
        }
        emit TokenDisallowed(tokens);
    }

    /**
     * @notice Authorizes contract upgrades
     * @dev Only callable by the contract owner
     * @param newImplementation Address of the new implementation contract
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
