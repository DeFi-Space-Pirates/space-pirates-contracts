// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Helper Role Contract Interface
 * @author @Gr3it
 */

interface IHelperRoleContract {
    function getBurnRoleBytes(uint256 id) external pure returns (bytes32);
    function getMintRoleBytes(uint256 id) external pure returns (bytes32);

    function getMultiBurnRoleBytes(uint256[] memory ids) external pure returns (bytes32[] memory);
    function getMultiMintRoleBytes(uint256[] memory ids) external pure returns (bytes32[] memory);

    function getRangeBurnRoleBytes(uint256 from, uint256 to) external pure returns (bytes32[] memory);
    function getRangeMintRoleBytes(uint256 from, uint256 to) external pure returns (bytes32[] memory);
}
