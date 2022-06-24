// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISpacePiratesWrapper {
    receive() external payable;

    function erc20ToId(address _erc20Contract)
        external
        view
        returns (uint256 id);

    function erc20Deposit(address _addr, uint256 _amount) external;

    function erc20Withdraw(address _addr, uint256 _amount) external;

    function erc20DepositTo(
        address _addr,
        uint256 _amount,
        address _to
    ) external;

    function erc20WithdrawTo(
        address _addr,
        uint256 _amount,
        address _to
    ) external;

    function ethDeposit() external payable;

    function ethWithdraw(uint256 _amount) external;

    function ethDepositTo(address _to) external payable;

    function ethWithdrawTo(uint256 _amount, address _to) external;
}
