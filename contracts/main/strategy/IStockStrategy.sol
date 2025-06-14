pragma solidity 0.8.20;

interface IStockStrategy {
    function deposit(address _depositToken, uint256 _amount, uint256 _slippage) external returns (uint256);
    function withdraw(address _withdrawToken, uint256 _amount, uint256 _slippage) external returns (uint256);
    function getUnderlyingTokenBalance(address _token) external view returns (uint256);
    function getUnderlyingToken(address _token) external view returns (address);
}
