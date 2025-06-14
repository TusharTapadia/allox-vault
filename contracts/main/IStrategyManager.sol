pragma solidity 0.8.20;

interface IStrategyManager {
    function deposit(address _token, uint256 _amount, uint256 _slippage) external returns (uint256);
    function withdraw(address _token, uint256 _amount, uint256 _slippage) external returns (uint256);
    function getUnderlyingTokenBalance() external view returns (uint256[] memory, uint256);
}
