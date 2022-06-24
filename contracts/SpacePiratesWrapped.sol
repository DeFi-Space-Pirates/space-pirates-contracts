// SPDX-License-Identifier: unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SpacePiratesWrapped is Ownable {

    struct TokenInfo {
        uint256 id;
        string name;
        bool exists;
        uint256 totalSupply;
    }

    address[] supportedTokens;
    mapping(address => TokenInfo) public tokens;

    mapping(address => mapping(address => bool)) public approvals;

    mapping(address => mapping(address => uint256)) public balances;

    constructor() {
        tokens[address(0)] = TokenInfo(0, "spaceETH", true, 0);
        supportedTokens.push(address(0));
    }

    function addNewToken(address _addr, string memory name) external onlyOwner {
        require(tokens[_addr].exists == false, "SpacePiratesWrapped: TOKEN ALREADY EXISTS");
        
        tokens[_addr] = TokenInfo(supportedTokens.length + 1, name, true, 0);
        supportedTokens.push(_addr);
    }

    //if necessary we can modify other fields of token info
    //? is actually needed this function?
    function updateToken(address _addr, bool _exists) external onlyOwner {
        tokens[_addr].exists = _exists;

        // code to update the other fields
    }

    function mintTokens(address _addr, uint256 _amount) public {
        require(tokens[_addr].exists == true, "SpacePiratesWrapped: TOKEN DOES NOT EXISTS");
        
        IERC20(_addr).approve(address(this), _amount); 
        IERC20(_addr).transferFrom(msg.sender, address(this), _amount);

        tokens[_addr].totalSupply += _amount;
        balances[_addr][msg.sender] += _amount;
    }

    function redeemTokens(address _addr, uint256 _amount) public {
        require(tokens[_addr].exists == true, "SpacePiratesWrapped: TOKEN DOES NOT EXISTS");
        require(balances[_addr][msg.sender] >= _amount, "SpacePiratesWrapped: NOT ENOUGH TOKENS");
        
        IERC20(_addr).transferFrom(address(this), msg.sender, _amount);

        tokens[_addr].totalSupply -= _amount;
        balances[_addr][msg.sender] -= _amount;
    }

    receive() external payable {
        ethDeposit();
    }

    function ethDeposit() public payable {
        mintTokens(address(0), msg.value);
    }

    function ethWithdraw(uint256 _amount) public {
        redeemTokens(address(0), _amount);

        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "SpacePiratesWrapped: WITHDRAW FAILED");
    }

    // TODO
    function transferToken() public {}
}
