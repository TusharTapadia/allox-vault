// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import {IStockStrategy} from "../strategy/IStockStrategy.sol";
import {IPriceOracle} from "../../oracle/IPriceOracle.sol";
import {ErrorLibrary} from "../../library/ErrorLibrary.sol";

/**
 * @title ProtocolRegistry
 * @notice Central registry contract for managing protocol-wide settings and token registrations
 * @dev This contract handles token registration, protocol fees, treasury management, and protocol state
 * @dev Implements UUPS upgradeability pattern and includes reentrancy protection
 */
contract TokenRegistry is Initializable, OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable {
    /**
     * @notice Structure to store token-specific information
     * @param enabled Whether the token is enabled in the protocol
     * @param handler Address of the strategy handler for the token
     */
    struct TokenRecord {
        bool enabled;
        address handler;
    }

    /// @notice Mapping of token addresses to their registration information
    mapping(address => TokenRecord) internal tokenInformation;

    /// @notice Address where protocol fees are collected
    address public treasury;
    
    /// @notice Protocol fee in basis points (1 basis point = 0.01%)
    uint256 public protocolFee;
    
    /// @notice Flag indicating whether the protocol is paused
    bool public protocolPause;
    
    /// @notice Address of the Wrapped Ether (WETH) contract
    address public WETH;
    
    /// @notice Address of the price oracle contract
    address public priceOracle;

    /**
     * @notice Emitted when new tokens are enabled in the protocol
     * @param _token Array of token addresses that were enabled
     * @param _handler Array of corresponding handler addresses
     */
    event EnableToken(
        address[] _token,
        address[] _handler
    );

    /**
     * @notice Initializes the protocol registry with core parameters
     * @dev Can only be called once during contract deployment
     * @param _treasury Address where protocol fees will be collected
     * @param _weth Address of the WETH contract
     * @param _oracle Address of the price oracle contract
     */
    function initialize(
        address _treasury,
        address _weth,
        address _oracle
    ) external initializer {
        __UUPSUpgradeable_init();
        __Ownable_init();
        if (_treasury == address(0)) {
            revert ErrorLibrary.ZeroAddressTreasury();
        }
        if (_oracle == address(0)) {
            revert ErrorLibrary.ZERO_ADDRESS();
        }

        //20% protocolFee
        protocolFee = 2000;
        priceOracle = _oracle;
        WETH = _weth;
    }

    /**
     * @notice Retrieves the registration information for a specific token
     * @param _token Address of the token to query
     * @return TokenRecord containing the token's enabled status and handler address
     */
    function getTokenInformation(address _token) external view virtual returns (TokenRecord memory) {
        return tokenInformation[_token];
    }

    /**
     * @notice Enables multiple tokens in the protocol with their respective handlers
     * @dev Only callable by the contract owner
     * @param _token Array of token addresses to enable
     * @param _handler Array of corresponding handler addresses
     */
    function enableToken(
        address[] memory _token,
        address[] memory _handler
    ) external virtual onlyOwner {
        if (
            !((_token.length == _handler.length))
        ) revert ErrorLibrary.IncorrectArrayLength();

        for (uint256 i = 0; i < _token.length; i++) {
            if (_token[i] == address(0)) {
                revert ErrorLibrary.InvalidTokenAddress();
            }

            address underlying = IStockStrategy(_handler[i]).getUnderlyingToken(_token[i]);
            if (!(IPriceOracle(priceOracle).getPriceTokenUSD18Decimals(underlying, 1 ether) > 0)) {
                revert ErrorLibrary.TokenNotInPriceOracle();
            }
            setTokenInfo(_token[i], _handler[i], true);
        }
        emit EnableToken(_token, _handler);
    }

    /**
     * @notice Checks if a specific token is enabled in the protocol
     * @param _token Address of the token to check
     * @return bool True if the token is enabled, false otherwise
     */
    function isEnabled(address _token) external view virtual returns (bool) {
        return tokenInformation[_token].enabled;
    }

    /**
     * @notice Updates the protocol treasury address
     * @dev Only callable by the contract owner
     * @param _newTreasury Address of the new treasury
     */
    function updateTreasury(address _newTreasury) external virtual onlyOwner {
        if (_newTreasury == address(0)) {
            revert ErrorLibrary.InvalidAddress();
        }
        treasury = _newTreasury;
    }

    /**
     * @notice Updates the WETH contract address
     * @dev Only callable by the contract owner
     * @param _newWETH Address of the new WETH contract
     */
    function updateWETH(address _newWETH) external virtual onlyOwner {
        if (_newWETH == address(0)) {
            revert ErrorLibrary.InvalidAddress();
        }
        WETH = _newWETH;
    }

    /**
     * @notice Sets the protocol pause state
     * @dev Only callable by the contract owner
     * @param _state True to pause the protocol, false to unpause
     */
    function setProtocolPause(bool _state) external virtual onlyOwner {
        protocolPause = _state;
    }

    /**
     * @notice Gets the current protocol pause state
     * @return bool True if protocol is paused, false otherwise
     */
    function getProtocolState() external view virtual returns (bool) {
        return protocolPause;
    }

    /**
     * @notice Gets the current WETH contract address
     * @return address The WETH contract address
     */
    function getETH() external view virtual returns (address) {
        return WETH;
    }

    /**
     * @notice Gets the current price oracle contract address
     * @return address The price oracle contract address
     */
    function getPriceOracle() external view virtual returns (address) {
        return priceOracle;
    }

    /**
     * @notice Internal function to update token registration information
     * @param _token Address of the token to update
     * @param _handler Address of the token's handler
     * @param _enabled Whether the token should be enabled
     */
    function setTokenInfo(
        address _token,
        address _handler,
        bool _enabled
    ) internal {
        tokenInformation[_token].handler = _handler;
        tokenInformation[_token].enabled = _enabled;
    }

    /**
     * @notice Authorizes contract upgrades
     * @dev Only callable by the contract owner
     * @param newImplementation Address of the new implementation contract
     */
    function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner {}
}
