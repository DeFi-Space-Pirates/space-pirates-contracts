// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Space Pirates NFT Contract Interface
 * @author @Gr3it
 */

interface ISpacePiratesNFT {
    event Mint(address indexed to, uint256 id, string collection, bool locked);
    event SetBaseURI(string newUri);
    event GrantRole(bytes32 indexed role, address account);
    event RevokeRole(bytes32 indexed role, address account);

    function DEFAULT_ADMIN_ROLE() external view returns (bytes32 role);
    function CAN_MINT() external view returns (bytes32 role);
    function CAN_BURN() external view returns (bytes32 role);
    function URI_SETTER() external view returns (bytes32 role);

    function name() external view returns (string memory name);
    function symbol() external view returns (string memory symbol);
    function supply() external view returns (uint256 supply);
    function tokenURI(uint256 tokenId) external view returns (string memory uri);
    function nftData(uint256) external view returns(string calldata collection, bool locked);

    function balanceOf(address owner) external view returns (uint256 amount);
    function walletOfOwner(address _owner) external view returns(uint256[] memory wallet);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    
    function isApprovedForAll(address owner, address operator) external view returns(bool);
    function getApproved(uint256 tokenId) external view returns (address);
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool approved) external;

    function mint(address to, string calldata collection, uint256 quantity, bool locked) external;
    function burn(uint256 tokenId) external;

    function getRoleAdmin(bytes32 role) external view returns (bytes32 adminRole);
    function hasRole(bytes32 role, address account) external view returns(bool);

    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;

    function transferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata _data) external;

    function setBaseURI(string calldata _baseURI) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
