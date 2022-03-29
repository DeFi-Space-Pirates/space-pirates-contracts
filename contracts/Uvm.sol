// SPDX-License-Identifier: unlicense
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Uvm {
    address payable Evm;
    uint256 deployDate;
    IERC20 bolts;
    IERC20 screws;

    constructor(address BoltsToken, address ScrewsToken) {
        Evm = payable(msg.sender);
        deployDate = block.timestamp;
        bolts = IERC20(BoltsToken);
        screws = IERC20(ScrewsToken);
    }

    struct Account {
        bool exists;
        address[] currentTokenAddresses;
        mapping(address => uint256) balances;
        uint256 timestampForInterests; // We need this to calculate interests
    }
    mapping(address => Account) private accounts;

    event AccountCreated(address account, uint256 time);
    event AccountClosed(address account, uint256 time);

    modifier accountExists() {
        require(accounts[msg.sender].exists, "TomNook ATM: Account not Exists");
        _;
    }

    modifier onlyValidTokens(address tokenAddress) {
        require(
            tokenAddress == address(bolts) || tokenAddress == address(screws),
            "EVM: Wrong token"
        );
        _;
    }

    function createAccount() external {
        require(!accounts[msg.sender].exists, "EVM: Already have an account");
        console.log("msg.sender : ", msg.sender);
        accounts[msg.sender].exists = true;
        accounts[msg.sender].timestampForInterests = block.timestamp;
        emit AccountCreated(msg.sender, block.timestamp);
    }

    function closeAccount() external accountExists {
        require(
            accounts[msg.sender].balances[
                accounts[msg.sender].currentTokenAddresses[0]
            ] != 0
        );
        require(
            accounts[msg.sender].balances[
                accounts[msg.sender].currentTokenAddresses[1]
            ] != 0
        );
        accounts[msg.sender].exists = false;
        emit AccountClosed(msg.sender, block.timestamp);
    }
}
