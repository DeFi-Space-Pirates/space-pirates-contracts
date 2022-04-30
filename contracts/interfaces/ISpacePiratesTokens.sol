// SPDX-License-Identifier: unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface ISpacePiratesTokens is IERC1155 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function setURI(string memory newuri, uint256 id) external;

    function pause() external;

    function unpause() external;

    function mint(
        address to,
        uint256 amount,
        uint256 id
    ) external;

    function burn(
        address from,
        uint256 amount,
        uint256 id
    ) external;

    function grantMultiRole(
        bytes32[] calldata roles,
        address[] calldata accounts
    ) external;

    function revokeMultiRole(
        bytes32[] calldata roles,
        address[] calldata accounts
    ) external;

    receive() external payable;

    function ethDeposit() external payable;

    function ethWithdraw(uint256 amount) external payable;
}
