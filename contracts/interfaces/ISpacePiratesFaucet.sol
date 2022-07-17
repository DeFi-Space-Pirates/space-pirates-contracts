// SPDX-License-Identifier: unlicense
pragma solidity ^0.8.0;

/**
 * @title Space Pirates Faucet Interface
 * @author @Gr3it
 */

interface ISpacePiratesFaucet {
    event SetMintLimit(uint256 indexed tokenId, uint256 mintLimit);
    event TokenMint(address indexed to, uint256 indexed tokenId, uint256 value);

    function tokenContract() external view returns (address tokenContract);
    function tokenMintLimit(uint256 tokenId) external view returns (uint256 limit);
    function supportedTokens(uint256 index) external view returns (uint256 tokenId);
    function getSupportedTokens() external view returns (uint256[] memory supportedTokens);

    function mintToken(uint256 tokenId, uint256 amount) external;

    function setMintLimit(uint256 tokenId, uint256 mintLimit) external;

    function owner() external view returns (address owner);
    function transferOwnership(address newOwner) external;
    function renounceOwnership() external;
}
