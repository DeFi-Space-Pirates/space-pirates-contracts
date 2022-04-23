// SPDX-License-Identifier: unlicense
pragma solidity ^0.8.0;

import "./ERC1155Custom.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "hardhat/console.sol";

contract Tokens is ERC1155Custom, AccessControl {
    uint256 public constant DOUBLOONS = 0;
    uint256 public constant ASTEROIDS = 1;
    uint256 public constant VE_ASTEROIDS = 2;
    uint256 public constant STK_ASTEROIDS = 3;

    bytes32 public constant DOUBLOONS_MINTER_ROLE =
        keccak256("DOUBLOONS_MINTER_ROLE");
    bytes32 public constant DOUBLOONS_BURNER_ROLE =
        keccak256("DOUBLOONS_BURNER_ROLE");
    bytes32 public constant ASTEROIDS_MINTER_ROLE =
        keccak256("ASTEROIDS_MINTER_ROLE");
    bytes32 public constant ASTEROIDS_BURNER_ROLE =
        keccak256("ASTEROIDS_BURNER_ROLE");
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant CAN_PAUSE_ROLE = keccak256("CAN_PAUSE_ROLE");
    bytes32 public constant CAN_UNPAUSE_ROLE = keccak256("CAN_UNPAUSE_ROLE");

    constructor() {
        _mint(msg.sender, DOUBLOONS, 1000000 * (10**18), "");
        _mint(msg.sender, ASTEROIDS, 100 * (10**18), "");

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155Custom, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setURI(string memory newuri, uint256 id)
        public
        onlyRole(URI_SETTER_ROLE)
    {
        _setURI(newuri, id);
    }

    function pause() public onlyRole(CAN_PAUSE_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(CAN_UNPAUSE_ROLE) {
        _unpause();
    }

    function mintDoubloons(address to, uint256 amount)
        public
        onlyRole(DOUBLOONS_MINTER_ROLE)
    {
        _mint(to, 0, amount, "");
    }

    function burnDoubloons(address from, uint256 amount)
        public
        onlyRole(DOUBLOONS_BURNER_ROLE)
    {
        _burn(from, 0, amount);
    }

    function mintAsteroids(address to, uint256 amount)
        public
        onlyRole(ASTEROIDS_MINTER_ROLE)
    {
        _mint(to, 1, amount, "");
    }

    function burnAsteroids(address from, uint256 amount)
        public
        onlyRole(ASTEROIDS_BURNER_ROLE)
    {
        _burn(from, 1, amount);
    }
}
