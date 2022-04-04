// SPDX-License-Identifier: unlicense
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "hardhat/console.sol";

//address->id->int
contract Items is ERC1155 {
    uint256 public constant DOUBLOONS = 0;
    uint256 public constant ASTEROIDS = 1;

    constructor() ERC1155("") {
        //@dev _mint(account, id, amount, data)
        _mint(msg.sender, DOUBLOONS, 10**18, "");
        _mint(msg.sender, ASTEROIDS, 10**7, "");
    }
}
