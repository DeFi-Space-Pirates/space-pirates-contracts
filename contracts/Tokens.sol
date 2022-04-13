// SPDX-License-Identifier: unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract Tokens is ERC1155, AccessControl, Ownable {
    uint256 public constant DOUBLOONS = 0;
    uint256 public constant ASTEROIDS = 1;
    uint256 public constant VE_ASTEROIDS = 2;
    uint256 public constant STK_ASTEROIDS = 3;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    constructor() ERC1155("ipfs://fakeurl") {
        //TODO define tokens supply
        _mint(msg.sender, DOUBLOONS, 10**18, "");
        _mint(msg.sender, ASTEROIDS, 10**7, "");
        _mint(msg.sender, VE_ASTEROIDS, 10**7, "");
        _mint(msg.sender, STK_ASTEROIDS, 10**7, "");

        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(BURNER_ROLE, msg.sender);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        _mint(to, id, amount, data);
    }

    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) public {
        require(hasRole(BURNER_ROLE, msg.sender), "Caller is not a burner");
        _burn(from, id, amount);
    }

    function grantRole(bytes32 role, address account)
        public
        virtual
        override
        onlyOwner
    {
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account)
        public
        virtual
        override
        onlyOwner
    {
        _revokeRole(role, account);
    }
}
