// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IERC20MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import {IPriceOracle} from "../../oracle/IPriceOracle.sol";
import {ErrorLibrary} from "../../library/ErrorLibrary.sol";
import {IAccessController} from "../../main/access/IAccessController.sol";
import {IProtocolRegistry} from "../../main/registry/IProtocolRegistry.sol";

/**
 * @title StockStrategy
 * @notice Strategy contract for managing stock token deposits and withdrawals
 * @dev Implements UUPS upgradeability pattern and includes reentrancy protection
 * @dev Handles token deposits, withdrawals, and balance tracking
 */
contract StockStrategy is Initializable, OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;
    
    /// @notice Interface for the access control contract
    IAccessController public accessController;
    
    /// @notice Interface for the protocol registry contract
    IProtocolRegistry public protocolRegistry;

    /**
     * @notice Initializes the stock strategy contract
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
     * @notice Modifier to restrict function access to strategy managers
     * @dev Reverts with CallerNotStrategyManager error if the caller doesn't have strategy manager role
     */
    modifier onlyStrategyManager(){
        if (!accessController.hasRole(keccak256("STRATEGY_MANAGER_ROLE"), msg.sender)) revert ErrorLibrary.CallerNotStrategyManager();
        _;
    }

    /**
     * @notice Deposits tokens into the strategy
     * @dev Only callable by strategy managers
     * @dev Reverts if protocol is paused
     * @param _token Address of the token to deposit
     * @param _amount Amount of tokens to deposit
     * @param _slippage Maximum allowed slippage for the deposit
     * @return uint256 Amount of tokens deposited (after slippage)
     */
    function deposit(address _token, uint256 _amount, uint256 _slippage) external nonReentrant onlyStrategyManager returns (uint256) {
        if(protocolRegistry.getProtocolPause()) revert ErrorLibrary.ProtocolPaused();

        IERC20MetadataUpgradeable(_token).safeTransferFrom(msg.sender, address(this), _amount);

        //DEPOSIT LOGIC ACCORDING TO STRATEGY

        // REDIRECT PROTOCOL TOKEN BACK TO VAULT

        return _amount; // RETURN THE AMOUNT DEPOSITED(AFTER SLIPPAGE IF ANY)
    }

    /**
     * @notice Withdraws tokens from the strategy
     * @dev Only callable by strategy managers
     * @dev Reverts if protocol is paused
     * @param _token Address of the token to withdraw
     * @param _amount Amount of tokens to withdraw
     * @param _slippage Maximum allowed slippage for the withdrawal
     * @return uint256 Amount of tokens withdrawn (after slippage)
     */
    function withdraw(address _token, uint256 _amount, uint256 _slippage) external nonReentrant onlyStrategyManager returns (uint256) {
        if(protocolRegistry.getProtocolPause()) revert ErrorLibrary.ProtocolPaused();

        IERC20MetadataUpgradeable(_token).safeTransfer(msg.sender, _amount);

        //WITHDRAW LOGIC ACCORDING TO STRATEGY

        return _amount; // RETURN THE AMOUNT WITHDRAWN(AFTER SLIPPAGE IF ANY)
    }

    /**
     * @notice Gets the USD value of the underlying token balance
     * @param _token Address of the token to check
     * @return uint256 USD value of the token balance in 18 decimals
     */
    function getUnderlyingValue(address _token) public view returns (uint256) { 
        IPriceOracle priceOracle = IPriceOracle(protocolRegistry.getPriceOracle());
        uint256 amount = IERC20MetadataUpgradeable(_token).balanceOf(address(this));
        return priceOracle.getPriceTokenUSD18Decimals(_token, amount);
    }

    /**
     * @notice Gets the balance of a specific token in the strategy
     * @param _token Address of the token to check
     * @return uint256 Balance of the token in the strategy
     */
    function getUnderlyingTokenBalance(address _token) external view returns (uint256) {
        return IERC20MetadataUpgradeable(_token).balanceOf(address(this));
    }

    /**
     * @notice Gets the underlying token address for a given token
     * @dev This function should be implemented according to the specific protocol's token structure
     * @param _token Address of the token to check
     * @return address Address of the underlying token
     */
    function getUnderlyingToken(address _token) external view returns (address) {
        // ADD LOGIC TO GET UNDERLYING TOKEN USING RESPECTIVE PROTOCOL CONTRACT
        // EXAMPLE : vETH IS VENUS PROTOCOL YIELD RECEIPT TOKEN THEN UNDERLYING TOKEN IS ETH
        return _token;
    }

    /**
     * @notice Authorizes contract upgrades
     * @dev Only callable by the contract owner
     * @param newImplementation Address of the new implementation contract
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}