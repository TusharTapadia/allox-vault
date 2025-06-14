// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {IERC20MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ErrorLibrary} from "../library/ErrorLibrary.sol";
import {IVaultManagerConfig} from "./registry/IVaultManagerConfig.sol";
import {IWETH} from "../interfaces/IWETH.sol";
import {IStrategyManager} from "./IStrategyManager.sol";
import {IProtocolRegistry} from "./registry/IProtocolRegistry.sol";
import {IAccessController} from "./access/IAccessController.sol";

/**
 * @title Vault
 * @notice ERC20 token contract representing shares in a vault of assets
 * @dev Implements UUPS upgradeability pattern and includes reentrancy protection
 * @dev Handles deposits, withdrawals, and share management for the vault
 */
contract Vault is Initializable, ERC20Upgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable {
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

    /**
     * @notice Emitted when a user deposits tokens into the vault
     * @param user Address of the user making the deposit
     * @param token Address of the token being deposited
     * @param amount Amount of tokens deposited
     * @param shares Amount of vault shares minted
     */
    event Deposit(address indexed user, address indexed token, uint256 amount, uint256 shares);

    /**
     * @notice Emitted when a user withdraws tokens from the vault
     * @param user Address of the user making the withdrawal
     * @param token Address of the token being withdrawn
     * @param shares Amount of vault shares burned
     * @param amount Amount of tokens withdrawn
     */
    event Withdraw(address indexed user, address indexed token, uint256 shares, uint256 amount);

    /**
     * @notice Emitted when new vault shares are minted
     * @param to Address receiving the minted shares
     * @param amount Amount of shares minted
     */
    event SharesMinted(address indexed to, uint256 amount);

    /**
     * @notice Emitted when vault shares are burned
     * @param from Address whose shares are being burned
     * @param amount Amount of shares burned
     */
    event SharesBurned(address indexed from, uint256 amount);

    /**
     * @notice Emitted when the vault is initialized
     * @param protocolRegistry Address of the protocol registry
     * @param accessController Address of the access controller
     * @param vaultManagerConfig Address of the vault manager config
     * @param strategyManager Address of the strategy manager
     * @param name Name of the vault token
     * @param symbol Symbol of the vault token
     */
    event VaultInitialized(
        address indexed protocolRegistry,
        address indexed accessController,
        address indexed vaultManagerConfig,
        address strategyManager,
        string name,
        string symbol
    );

    /// @notice Address of the Wrapped Ether (WETH) contract
    address public WETH;
    
    /// @notice Interface for the access control contract
    IAccessController public accessController;
    
    /// @notice Interface for the vault manager configuration
    IVaultManagerConfig public vaultManagerConfig;
    
    /// @notice Address of the strategy manager contract
    address public strategyManager;
    
    /// @notice Interface for the protocol registry
    IProtocolRegistry public protocolRegistry;

    /**
     * @notice Modifier to restrict function access to minters
     * @dev Reverts with CallerNotMinter error if the caller doesn't have minter role
     */
    modifier onlyMinter() {
        if (!accessController.hasRole(keccak256("MINTER_ROLE"), msg.sender)) revert ErrorLibrary.CallerNotMinter();
        _;
    }

    /**
     * @notice Initializes the vault contract
     * @dev Can only be called once during contract deployment
     * @param _protocolRegistry Address of the protocol registry
     * @param _accessController Address of the access controller
     * @param _vaultManagerConfig Address of the vault manager config
     * @param _strategyManager Address of the strategy manager
     * @param _name Name of the vault token
     * @param _symbol Symbol of the vault token
     */
    function initialize(
        address _protocolRegistry,
        address _accessController,
        address _vaultManagerConfig,
        address _strategyManager,
        string memory _name,
        string memory _symbol
    ) public initializer {
        __ERC20_init(_name, _symbol);
        __Ownable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        
        if(_accessController != address(0)) revert ErrorLibrary.ZERO_ADDRESS();
        if(_vaultManagerConfig != address(0)) revert ErrorLibrary.ZERO_ADDRESS();
        if(_strategyManager != address(0)) revert ErrorLibrary.ZERO_ADDRESS();
        if(_protocolRegistry != address(0)) revert ErrorLibrary.ZERO_ADDRESS();

        protocolRegistry = IProtocolRegistry(_protocolRegistry);
        WETH = protocolRegistry.getWETH();
        vaultManagerConfig = IVaultManagerConfig(_vaultManagerConfig);
        strategyManager = _strategyManager;
        accessController = IAccessController(_accessController);

        emit VaultInitialized(_protocolRegistry, _accessController, _vaultManagerConfig, _strategyManager, _name, _symbol);
    }

    /**
     * @notice Deposits tokens into the vault and mints shares
     * @dev Reverts if token is not allowed or amount is zero
     * @param _token Address of the token to deposit
     * @param _amount Amount of tokens to deposit
     * @param _slippage Maximum allowed slippage for the deposit
     */
    function deposit(address _token, uint256 _amount, uint256 _slippage) external nonReentrant {
        if(_token == address(0)) revert ErrorLibrary.ZERO_ADDRESS();
        if(_amount == 0) revert ErrorLibrary.ZeroTokenAmount();
        if(!vaultManagerConfig.allowedTokens(_token)) revert ErrorLibrary.InvalidToken();

        safeTransferHelper(_token, _amount);
        uint256 depositedAmount = IStrategyManager(strategyManager).deposit(_token, _amount, _slippage);

        uint256 shares;
        if(totalSupply() == 0){
            shares = depositedAmount;
        }else{
            (uint256[] memory individualBalance, uint256 totalBalance) = IStrategyManager(strategyManager).getUnderlyingTokenBalance();
            shares = (depositedAmount * totalSupply()) / totalBalance;
        }
        _mint(msg.sender, shares);
        
        emit Deposit(msg.sender, _token, _amount, shares);
    }

    /**
     * @notice Withdraws tokens from the vault by burning shares
     * @dev Reverts if amount is zero or token is not allowed
     * @param _withdrawToken Address of the token to withdraw
     * @param _amount Amount of shares to burn
     * @param _slippage Maximum allowed slippage for the withdrawal
     */
    function withdraw(address _withdrawToken, uint256 _amount, uint256 _slippage) external nonReentrant {
        if(_amount == 0) revert ErrorLibrary.ZeroTokenAmount();
        if(!vaultManagerConfig.allowedTokens(_withdrawToken)) revert ErrorLibrary.InvalidToken();

        _burn(msg.sender, _amount);
        uint256 withdrawAmount = IStrategyManager(strategyManager).withdraw(_withdrawToken, _amount, _slippage);
        IERC20MetadataUpgradeable(_withdrawToken).safeTransfer(msg.sender, withdrawAmount);

        emit Withdraw(msg.sender, _withdrawToken, _amount, withdrawAmount);
    }

    /**
     * @notice Helper function to safely transfer tokens to the vault
     * @dev Handles both regular ERC20 tokens and WETH deposits
     * @param _token Address of the token to transfer
     * @param _amount Amount of tokens to transfer
     */
    function safeTransferHelper(address _token, uint256 _amount) internal {
        IERC20MetadataUpgradeable(_token).safeTransferFrom(msg.sender, address(this), _amount);
        if(_token == WETH && msg.value > 0) {
            IWETH(WETH).deposit{value: _amount}();
        }else{
            IERC20MetadataUpgradeable(_token).safeTransferFrom(msg.sender, address(this), _amount);
        }
    }

    /**
     * @notice Mints new vault shares to a specified address
     * @dev Only callable by addresses with minter role
     * @param _to Address to mint shares to
     * @param _amount Amount of shares to mint
     */
    function mintShares(address _to, uint256 _amount) external virtual onlyMinter {
        _mint(_to, _amount);
        emit SharesMinted(_to, _amount);
    }

    /**
     * @notice Burns vault shares from a specified address
     * @dev Only callable by addresses with minter role
     * @param _to Address to burn shares from
     * @param _amount Amount of shares to burn
     */
    function burnShares(address _to, uint256 _amount) external virtual onlyMinter {
        _burn(_to, _amount);
        emit SharesBurned(_to, _amount);
    }

    /**
     * @notice Authorizes contract upgrades
     * @dev Only callable by the contract owner
     * @param newImplementation Address of the new implementation contract
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}