pragma solidity 0.8.20;

interface IVault {
    function deposit(address _token, uint256 _amount) external returns (uint256);
    function withdraw(address _token, uint256 _amount) external returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _account) external view returns (uint256);
}