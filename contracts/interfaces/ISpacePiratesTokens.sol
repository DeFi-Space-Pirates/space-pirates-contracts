// SPDX-License-Identifier: unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/**
 * @title Space Pirates Tokens Interface
 * @author @Gr3it
 */

interface ISpacePiratesTokens is IERC1155 {
    event Mint(address indexed sender, uint256 id, uint256 amount, address indexed to);
    event Burn(address indexed sender, uint256 id, uint256 amount);
    event MintBatch(address indexed sender, uint256[] ids, uint256[] amounts, address indexed to);
    event BurnBatch(address indexed sender, uint256[] ids, uint256[] amounts);

    event GrantRole(bytes32 indexed role, address account);
    event RevokeRole(bytes32 indexed role, address account);
    event GrantMultiRole(bytes32[] indexed roles, address[] accounts);
    event RevokeMultiRole(bytes32[] indexed roles, address[] accounts);
    event RenounceRole(bytes32 indexed role, address account);

    event Pause();
    event Unpause();

    event LockTokenTransfer();
    event UnLockTokenTransfer();
    
    event UriUpdate(string newUri);

    function DOUBLOONS() external view returns(uint256);
    function ASTEROIDS() external view returns(uint256);
    function STK_ASTEROIDS() external view returns(uint256);
    function VE_ASTEROIDS() external view returns(uint256);
    
    function DEFAULT_ADMIN_ROLE() external view returns(bytes32);
    function CAN_PAUSE_ROLE() external view returns(bytes32);
    function CAN_UNPAUSE_ROLE() external view returns(bytes32);
    function URI_SETTER_ROLE() external view returns(bytes32);
    function TRANSFERABLE_SETTER_ROLE() external view returns(bytes32);
    
    function totalSupply(uint256 id ) external view returns(uint256);
    function exists(uint256 id) external view returns(bool);
    
    function mint(address to, uint256 id, uint256 amount) external;
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts) external;
    function burn(address from, uint256 id, uint256 amount) external;
    function burnBatch(address from, uint256[] memory ids, uint256[] memory amounts) external;
    
    function hasRole(bytes32 role, address account) external view returns(bool);
    function getRoleAdmin(bytes32 role) external view returns(bytes32);
    function grantRole(bytes32 role, address account) external;
    function grantMultiRole(bytes32[] memory roles, address[] memory accounts) external;
    function revokeRole(bytes32 role, address account) external;
    function revokeMultiRole(bytes32[] memory roles, address[] memory accounts) external;
    function renounceRole(bytes32 role, address account) external;
    
    function paused() external view returns(bool);
    function pause() external;
    function unpause() external;
    
    function canBeTransferred(uint256 id) external view returns(bool);
    function lockTokenTransfer(uint256 id) external;
    function unLockTokenTransfer(uint256 id) external;
    
    function uri(uint256 tokenId) external view returns(string memory);
    function setURI(string memory newuri) external;
}
