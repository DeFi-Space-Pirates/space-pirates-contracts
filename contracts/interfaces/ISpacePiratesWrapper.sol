// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISpacePiratesWrapper {

    event ERC20Added(address indexed _erc20contract, uint256 id);
    event ERC20Deposited(address indexed user, address indexed _erc20contract, uint256 id, uint256 amount);
    event ERC20Withdrawn(address indexed user, address indexed _erc20contract, uint256 id, uint256 amount);
    event ETHDeposited(address indexed user, uint256 id, uint256 amount);
    event ETHWithdrawn(address indexed user, uint256 id, uint256 amount);
    event SetFeeAddress(address indexed sender, address indexed feeAddress);

    receive() external payable;

    function erc20ToId(address _erc20Contract) external view returns(uint256 id);
    function lastId() external view returns(uint256 id);
    
    function erc20Deposit(address _addr, uint256 _amount) external;
    function erc20DepositTo(address _addr, uint256 _amount, address _to) external;
    function erc20Withdraw(address _addr, uint256 _amount) external;
    function erc20WithdrawTo(address _addr, uint256 _amount, address _to) external;
    
    function ethDepositTo(address _to) external payable;
    function ethWithdraw(uint256 _amount) external;
    function ethWithdrawTo(uint256 _amount, address _to) external;

    function addERC20(address _erc20Contract) external returns(uint256 id);

    function feeBasePoint() external view returns(uint256 fee);
    function feeAddress() external view returns (address);
    function setFeeBasePoint(uint256 _feeBasePoint) external;
    function setFeeAddress(address _feeAddress) external;
}
