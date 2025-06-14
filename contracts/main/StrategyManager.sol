// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {IERC20MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IProtocolRegistry} from "./registry/IProtocolRegistry.sol";
import {IAccessController} from "./access/IAccessController.sol";
import {ErrorLibrary} from "../library/ErrorLibrary.sol";
import {IVault} from "./IVault.sol";
import {IStockStrategy} from "./strategy/IStockStrategy.sol";

/**
 * @title StrategyManager
 * @notice Manages investment strategies and token allocations for the vault
 * @dev Implements UUPS upgradeability pattern and includes reentrancy protection
 * @dev Handles strategy weights, deposits, withdrawals, and rebalancing
 */
contract StrategyManager is Initializable, OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

    /**
     * @notice Emitted when the strategy manager is initialized
     * @param vault Address of the vault contract
     * @param accessController Address of the access controller
     * @param protocolRegistry Address of the protocol registry
     * @param baseToken Address of the base token
     */
    event StrategyManagerInitialized(
        address indexed vault,
        address indexed accessController,
        address indexed protocolRegistry,
        address baseToken
    );

    /**
     * @notice Emitted when vault tokens and their weights are set
     * @param tokens Array of token addresses
     * @param weights Array of corresponding weights
     */
    event VaultTokensSet(address[] tokens, uint256[] weights);

    /**
     * @notice Emitted when a deposit is executed
     * @param depositToken Address of the token being deposited
     * @param amount Amount of tokens deposited
     * @param investmentAfterDeposit Total investment after deposit
     */
    event DepositExecuted(
        address indexed depositToken,
        uint256 amount,
        uint256 investmentAfterDeposit
    );

    /**
     * @notice Emitted when a withdrawal is executed
     * @param withdrawToken Address of the token being withdrawn
     * @param amount Amount of tokens withdrawn
     * @param strategyWithdrawals Array of amounts withdrawn from each strategy
     */
    event WithdrawExecuted(
        address indexed withdrawToken,
        uint256 amount,
        uint256[] strategyWithdrawals
    );

    /**
     * @notice Emitted when strategy weights are updated
     * @param oldWeights Array of previous weights
     * @param newWeights Array of new weights
     * @param slippage Slippage value used for the update
     */
    event StrategyWeightsUpdated(
        uint256[] oldWeights,
        uint256[] newWeights,
        uint256 slippage
    );

    /**
     * @notice Emitted when strategies are updated
     * @param oldStrategies Array of previous strategy addresses
     * @param newStrategies Array of new strategy addresses
     * @param weights Array of weights for new strategies
     * @param slippage Slippage value used for the update
     */
    event StrategyUpdated(
        address[] oldStrategies,
        address[] newStrategies,
        uint256[] weights,
        uint256 slippage
    );

    /// @notice Interface for the access control contract
    IAccessController public accessController;
    
    /// @notice Interface for the protocol registry contract
    IProtocolRegistry public protocolRegistry;
    
    /// @notice Interface for the vault contract
    IVault public vault;
    
    /// @notice Address of the base token used for deposits and withdrawals
    address public baseToken;

    /// @notice Array of strategy token addresses
    address[] public strategyTokens;
    
    /// @notice Array of weights corresponding to strategy tokens
    uint256[] public strategyWeights;
    
    /// @notice Array of new strategy token addresses for updates
    address[] public newStrategyTokens;
    
    /// @notice Array of new weights for strategy updates
    uint256[] public newStrategyWeights;

    /// @notice Scale factor for ratio calculations (10000 = 100%)
    uint public RATIO_SCALE = 10000;

    /**
     * @notice Emitted when strategy ratios are changed
     * @param vault Address of the vault
     * @param isIncrease Whether the change was an increase
     */
    event StrategiesAndRatiosChangedEvent(address indexed vault, bool isIncrease);

    /**
     * @notice Modifier to restrict function access to vault contract
     * @dev Reverts with CallerNotVault error if the caller doesn't have vault role
     */
    modifier onlyVault(){
        if (!accessController.hasRole(keccak256("VAULT_ROLE"), msg.sender)) revert ErrorLibrary.CallerNotVault();
        _;
    }

    /**
     * @notice Modifier to restrict function access to vault managers
     * @dev Reverts with CallerNotVaultManager error if the caller doesn't have vault manager role
     */
    modifier onlyVaultManager(){
        if (!accessController.hasRole(keccak256("VAULT_MANAGER_ROLE"), msg.sender)) revert ErrorLibrary.CallerNotVaultManager();
        _;
    }

    /**
     * @notice Initializes the strategy manager contract
     * @dev Can only be called once during contract deployment
     * @param _vault Address of the vault contract
     * @param _accessController Address of the access controller
     * @param _protocolRegistry Address of the protocol registry
     * @param _baseToken Address of the base token
     */
    function initialize(address _vault, address _accessController, address _protocolRegistry, address _baseToken) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        
        if(_accessController != address(0)) revert ErrorLibrary.ZERO_ADDRESS();
        if(_protocolRegistry != address(0)) revert ErrorLibrary.ZERO_ADDRESS();
        
        accessController = IAccessController(_accessController);
        protocolRegistry = IProtocolRegistry(_protocolRegistry);
        vault = IVault(_vault);
        baseToken = _baseToken;

        emit StrategyManagerInitialized(_vault, _accessController, _protocolRegistry, _baseToken);
    }

    /**
     * @notice Sets the vault tokens and their weights
     * @dev Only callable by vault manager
     * @param _tokens Array of token addresses
     * @param _weights Array of corresponding weights
     */
    function setVaultTokens(address[] memory _tokens, uint256[] memory _weights) external onlyVaultManager {
        if(_tokens.length != _weights.length) revert ErrorLibrary.IncorrectArrayLength();
        uint256 weightSum = 0;
        for(uint256 i = 0; i < _tokens.length; i++){
            if(!protocolRegistry.isEnabled(_tokens[i])) revert ErrorLibrary.TokenNotEnabled();
            weightSum += _weights[i];
        }
        if(weightSum != RATIO_SCALE) revert ErrorLibrary.InvalidWeight();
        strategyTokens = _tokens;
        strategyWeights = _weights;

        emit VaultTokensSet(_tokens, _weights);
    }

    /**
     * @notice Deposits tokens into the strategies
     * @dev Only callable by vault
     * @dev Reverts if protocol is paused
     * @param _depositToken Address of the token to deposit
     * @param _amount Amount of tokens to deposit
     * @param _slippage Maximum allowed slippage for the deposit
     * @return uint256 Total amount invested after deposit
     */
    function deposit(address _depositToken, uint256 _amount, uint256 _slippage) external nonReentrant onlyVault returns (uint256) {
        if(protocolRegistry.getProtocolPause()) revert ErrorLibrary.ProtocolPaused();

        uint256 investmentAfterDeposit = 0;

        IERC20MetadataUpgradeable(_depositToken).safeTransferFrom(msg.sender, address(this), _amount);

        (uint256[] memory individualBalance, uint256 totalBalance) = getUnderlyingTokenBalance();
        if(totalBalance > 0){
            for (uint256 i = 0; i < strategyTokens.length; i++) {
                uint256 amnt = 0;
                if (i == strategyTokens.length - 1) {
                    amnt = IERC20MetadataUpgradeable(_depositToken).balanceOf(address(this));
                } else {
                    uint256 currentStrategyBalance = individualBalance[i];
                    uint256 ratio = (currentStrategyBalance * RATIO_SCALE) / totalBalance;
                    amnt = (_amount * ratio) / RATIO_SCALE;
                }
                IProtocolRegistry.TokenRecord memory tokenInfo = getTokenInfo(strategyTokens[i]);
                IERC20MetadataUpgradeable(strategyTokens[i]).safeApprove(tokenInfo.handler, amnt);
                uint256 depositAmount = IStockStrategy(tokenInfo.handler).deposit(_depositToken, amnt, _slippage);
                investmentAfterDeposit += depositAmount;
            }
        } else {
            for (uint256 i = 0; i < strategyTokens.length; i++) {
                uint256 amnt = (_amount * strategyWeights[i]) / RATIO_SCALE;

                IProtocolRegistry.TokenRecord memory tokenInfo = getTokenInfo(strategyTokens[i]);
                IERC20MetadataUpgradeable(strategyTokens[i]).safeApprove(tokenInfo.handler, amnt);
                uint256 depositAmount = IStockStrategy(tokenInfo.handler).deposit(_depositToken, amnt, _slippage);
                investmentAfterDeposit += depositAmount;
            }
        }

        emit DepositExecuted(_depositToken, _amount, investmentAfterDeposit);
        return investmentAfterDeposit;
    }

    /**
     * @notice Withdraws tokens from the strategies
     * @dev Only callable by vault
     * @dev Reverts if protocol is paused
     * @param _withdrawToken Address of the token to withdraw
     * @param _amount Amount of tokens to withdraw
     * @return uint256 Amount of tokens withdrawn
     */
    function withdraw(address _withdrawToken, uint256 _amount) external nonReentrant onlyVault returns (uint256) {
        if(protocolRegistry.getProtocolPause()) revert ErrorLibrary.ProtocolPaused();

        uint256 totalSupply = vault.totalSupply();
        uint256[] memory strategyWithdrawals = new uint256[](strategyTokens.length);

        for(uint256 i = 0; i < strategyTokens.length; i++){
            IProtocolRegistry.TokenRecord memory tokenInfo = getTokenInfo(strategyTokens[i]);
            uint256 getTokenBalance = IStockStrategy(tokenInfo.handler).getUnderlyingTokenBalance(strategyTokens[i]);
            uint256 withdrawAmount = (_amount * getTokenBalance) / totalSupply;
            strategyWithdrawals[i] = withdrawAmount;
            IERC20MetadataUpgradeable(strategyTokens[i]).safeTransfer(msg.sender, withdrawAmount);
        }

        emit WithdrawExecuted(_withdrawToken, _amount, strategyWithdrawals);
    }

    /**
     * @notice Gets the balance of underlying tokens for each strategy
     * @return individualBalance Array of individual token balances
     * @return totalBalance Total balance across all strategies
     */
    function getUnderlyingTokenBalance() public view returns (uint256[] memory, uint256) {
        uint totalBalance = 0;
        uint[] memory balances = new uint[](strategyTokens.length);
        for(uint256 i = 0; i < strategyTokens.length; i++){
            IProtocolRegistry.TokenRecord memory tokenInfo = getTokenInfo(strategyTokens[i]);
            balances[i] = IStockStrategy(tokenInfo.handler).getUnderlyingTokenBalance(address(this));
            totalBalance += balances[i];
        }
        return (balances, totalBalance);
    }

    /**
     * @notice Updates strategy weights
     * @param newWeights Array of new weights
     * @param _slippage Slippage value for the update
     * @dev Only callable by vault manager
     */
    function updateStrategyWeights(
        uint256[] memory newWeights,
        uint256 _slippage
    ) external onlyVaultManager nonReentrant {
        if (newWeights.length != strategyTokens.length) revert ErrorLibrary.InvalidLength();
        uint256 totalWeightsSum = 0;
        for (uint256 i = 0; i < newWeights.length; i++) {
            totalWeightsSum += newWeights[i];
        }
        if (totalWeightsSum != RATIO_SCALE) revert ErrorLibrary.InvalidWeights();
        
        uint256[] memory oldWeights = strategyWeights;
        _updateStrategyInfo(strategyTokens, newWeights);
        _updateInformation(_slippage);

        emit StrategyWeightsUpdated(oldWeights, newWeights, _slippage);
    }

    /**
     * @notice Updates strategies and their weights
     * @param _strategies Array of new strategy addresses
     * @param _weights Array of new weights
     * @param _slippage Slippage value for the update
     * @dev Only callable by vault manager
     */
    function updateStrategy(
        address[] memory _strategies,
        uint256[] memory _weights,
        uint256 _slippage
    ) external onlyVaultManager nonReentrant {
        if (_strategies.length == 0) revert ErrorLibrary.InvalidLength();
        uint256 totalRatio = 0;

        address[] memory oldStrategies = strategyTokens;
        delete strategyTokens;
        delete newStrategyTokens;
        delete newStrategyWeights;

        for (uint256 i = 0; i < _strategies.length; i++) {
            totalRatio += _weights[i];
        }
        if (totalRatio != RATIO_SCALE) revert ErrorLibrary.InvalidWeights();
        for (uint256 i = 0; i < _strategies.length; i++) {
            if (_weights[i] == 0) {
                uint256 tokenBalance = IStockStrategy(_strategies[i]).getUnderlyingTokenBalance(address(this));
                IStockStrategy(_strategies[i]).withdraw(
                    _strategies[i],
                    tokenBalance,
                    _slippage
                );
            } else {
                newStrategyTokens.push(_strategies[i]);
                newStrategyWeights.push(_weights[i]);
            }
        }

        _updateStrategyInfo(newStrategyTokens, newStrategyWeights);
        _updateInformation(_slippage);

        emit StrategyUpdated(oldStrategies, newStrategyTokens, newStrategyWeights, _slippage);
    }

    /**
     * @notice Updates strategy information
     * @param _strategies Array of strategy addresses
     * @param newWeights Array of new weights
     * @dev Internal function to update strategy information
     */
    function _updateStrategyInfo(
        address[] memory _strategies,
        uint256[] memory newWeights
    ) internal {
        delete strategyTokens;
        uint256 weightsTotal = 0;
        for (uint256 i = 0; i < _strategies.length; i++) {
            IProtocolRegistry.TokenRecord memory tokenInfo = getTokenInfo(_strategies[i]);
            if (!tokenInfo.enabled) revert ErrorLibrary.TokenNotEnabled();
            strategyTokens.push(_strategies[i]);
            weightsTotal += newWeights[i];
        }
        if (weightsTotal != RATIO_SCALE) revert ErrorLibrary.InvalidWeights();
        strategyWeights = newWeights;
    }

    /**
     * @notice Updates information after strategy changes
     * @param newSlippage New slippage value for updates
     * @dev Internal function to update information after strategy changes
     */
    function _updateInformation(uint256 newSlippage) internal {
        (uint256[] memory individualBalance, uint256 totalBalance) = getUnderlyingTokenBalance();
        uint256 totalValue = totalBalance + IERC20MetadataUpgradeable(baseToken).balanceOf(address(this));
        
        if (totalValue == 0) return;

        (uint256[] memory oldWeights, uint256[] memory newWeights) = _calculateWeights(individualBalance, totalValue);
        _handleWeightDecreases(oldWeights, newWeights, newSlippage);
        _handleWeightIncreases(oldWeights, newWeights, newSlippage);

        emit StrategiesAndRatiosChangedEvent(address(this), true);
    }

    /**
     * @notice Calculates old and new weights for strategies
     * @param individualBalance Array of individual token balances
     * @param totalValue Total value of all tokens
     * @return oldWeights Array of old weights
     * @return newWeights Array of new weights
     */
    function _calculateWeights(
        uint256[] memory individualBalance,
        uint256 totalValue
    ) internal view returns (uint256[] memory oldWeights, uint256[] memory newWeights) {
        oldWeights = new uint256[](strategyTokens.length);
        newWeights = new uint256[](strategyTokens.length);

        for (uint256 i = 0; i < strategyTokens.length; i++) {
            uint256 currentValue = individualBalance[i];
            oldWeights[i] = (currentValue * RATIO_SCALE) / totalValue;
            newWeights[i] = strategyWeights[i];
        }

        return (oldWeights, newWeights);
    }

    /**
     * @notice Handles weight decreases by withdrawing from strategies
     * @param oldWeights Array of old weights
     * @param newWeights Array of new weights
     * @param newSlippage Slippage value for withdrawals
     */
    function _handleWeightDecreases(
        uint256[] memory oldWeights,
        uint256[] memory newWeights,
        uint256 newSlippage
    ) internal {
        for (uint256 i = 0; i < strategyTokens.length; i++) {
            if (newWeights[i] < oldWeights[i]) {
                uint256 ratioDiff = oldWeights[i] - newWeights[i];
                IProtocolRegistry.TokenRecord memory tokenInfo = getTokenInfo(strategyTokens[i]);
                uint256 tokenBalance = IStockStrategy(tokenInfo.handler).getUnderlyingTokenBalance(strategyTokens[i]);
                uint256 tokensToWithdraw = (tokenBalance * ratioDiff) / oldWeights[i];
                uint256 underlyingToWithdraw = (tokensToWithdraw *
                    IStockStrategy(tokenInfo.handler).getUnderlyingTokenBalance(strategyTokens[i])) / tokenBalance;
                
                IStockStrategy(tokenInfo.handler).withdraw(
                    strategyTokens[i],
                    underlyingToWithdraw,
                    newSlippage
                );
            }
        }
    }

    /**
     * @notice Handles weight increases by depositing into strategies
     * @param oldWeights Array of old weights
     * @param newWeights Array of new weights
     * @param newSlippage Slippage value for deposits
     */
    function _handleWeightIncreases(
        uint256[] memory oldWeights,
        uint256[] memory newWeights,
        uint256 newSlippage
    ) internal {
        uint256 sumRatio = 0;
        for (uint256 i = 0; i < strategyTokens.length; i++) {
            if (newWeights[i] > oldWeights[i]) {
                uint256 ratioDiff = newWeights[i] - oldWeights[i];
                sumRatio += ratioDiff;
            }
        }

        if (sumRatio == 0) revert ErrorLibrary.InvalidExecution();

        uint256 totalCurrencyBalance = IERC20MetadataUpgradeable(baseToken).balanceOf(address(this));
        for (uint256 i = 0; i < strategyTokens.length; i++) {
            if (newWeights[i] > oldWeights[i]) {
                IProtocolRegistry.TokenRecord memory tokenInfo = getTokenInfo(strategyTokens[i]);
                uint256 ratioToDeposit = newWeights[i] - oldWeights[i];
                uint256 depositAmount = (totalCurrencyBalance * ratioToDeposit) / sumRatio;
                
                IStockStrategy(tokenInfo.handler).deposit(
                    baseToken,
                    depositAmount,
                    newSlippage
                );
            }
        }
    }

    /**
     * @notice Gets token information from the protocol registry
     * @param _token Address of the token to get information for
     * @return TokenRecord Token information from the protocol registry
     */
    function getTokenInfo(address _token) internal view returns (IProtocolRegistry.TokenRecord memory) {
        return protocolRegistry.getTokenInformation(_token);
    }

    /**
     * @notice Authorizes contract upgrades
     * @dev Only callable by the contract owner
     * @param newImplementation Address of the new implementation contract
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}