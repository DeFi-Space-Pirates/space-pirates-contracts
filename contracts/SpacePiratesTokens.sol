// SPDX-License-Identifier: unlicense
pragma solidity ^0.8.0;

import "./ERC1155Custom.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "hardhat/console.sol";

contract SpacePiratesTokens is ERC1155Custom, AccessControl {
    uint256 public constant SPACE_ETH = 0; // Wrapped eth for the dex
    uint256 public constant DOUBLOONS = 1;
    uint256 public constant ASTEROIDS = 2;
    uint256 public constant VE_ASTEROIDS = 3;
    uint256 public constant STK_ASTEROIDS = 4;

    // Minting role = keccak256(abi.encodePacked("MINT_ROLE_FOR_ID",id));
    // Burning role = keccak256(abi.encodePacked("BURN_ROLE_FOR_ID",id));
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

    function mint(
        address to,
        uint256 amount,
        uint256 id
    ) public onlyRole(keccak256(abi.encodePacked("MINT_ROLE_FOR_ID", id))) {
        require(id != 0, "cant't mind SpaceEth");
        _mint(to, id, amount, "");
    }

    function burn(
        address from,
        uint256 amount,
        uint256 id
    ) public onlyRole(keccak256(abi.encodePacked("BURN_ROLE_FOR_ID", id))) {
        require(id != 0, "cant't burn SpaceEth");
        _burn(from, id, amount);
    }

    function grantMultiRole(
        bytes32[] calldata roles,
        address[] calldata accounts
    ) public {
        require(
            roles.length == accounts.length,
            "AccessControl: array of different length"
        );
        for (uint256 i; i < roles.length; ++i) {
            _checkRole(getRoleAdmin(roles[i]), msg.sender);
            _grantRole(roles[i], accounts[i]);
        }
    }

    function revokeMultiRole(
        bytes32[] calldata roles,
        address[] calldata accounts
    ) public {
        require(
            roles.length == accounts.length,
            "AccessControl: array of different length"
        );
        for (uint256 i; i < roles.length; ++i) {
            _checkRole(getRoleAdmin(roles[i]), msg.sender);
            _revokeRole(roles[i], accounts[i]);
        }
    }

    receive() external payable {
        ethDeposit();
    }

    function ethDeposit() public payable {
        _mint(msg.sender, 0, msg.value, "");
    }

    function ethWithdraw(uint256 amount) public {
        _burn(msg.sender, 0, amount);
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "withdrawal failed");
    }
}
