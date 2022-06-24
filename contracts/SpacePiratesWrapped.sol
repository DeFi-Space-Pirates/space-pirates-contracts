// SPDX-License-Identifier: unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC1155Custom.sol";

contract SpacePiratesWrapped is Ownable, ERC1155Custom {
    address[] idSupport;

    mapping(address => TokenInfo) tokens;
    mapping(address => mapping(address => bool)) approvals;

    struct TokenInfo {
        uint256 tokenId;
        string name;
        bool exists;
        uint256 totalSupply;
        mapping(address => uint256) balances;
    }

    function addNewToken(address addr, string memory name) external onlyOwner {
        require(tokens[addr].exists == false);
        tokens[addr] = new TokenInfo(idSupport.length + 1, name, true, 0);
        idSupport.push(addr);
    }

    //if necessary we can modify other fields of token info
    function updateToken(address addr, bool choose) external onlyOwner {
        tokens[addr].exists = choose;
    }

    function mintToken(address addr, uint256 amount) public {
        require(tokens[addr].exists == true);
        //TODO: erc20 transfer
        tokens[addr].totalSupply += amount;
        tokens[addr].balances[msg.sender] += amount;
    }

    function redeemToken(address addr, uint256 amount) public {
        require(tokens[addr].exists == true);
        //TODO: erc20 transfer
        tokens[addr].totalSupply -= amount;
        tokens[addr].balances[msg.sender] -= amount;
    }

    receive() external payable {
        ethDeposit();
    }

    function addToken(address _addr) external payable receive {
        nativeTokenDeposit();
    }

    function nativeTokenDeposit() public payable {
        _mint(msg.sender, 0, msg.value, "");
    }

    function nativeTokenWithdraw(uint256 amount) public {
        _burn(msg.sender, 0, amount);
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "withdrawal failed");
    }
}
