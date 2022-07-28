// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Space Pirates NFT Starter Banner Interface
 * @author @Gr3it
 */

interface INFTStarterBanner {
    function tokenContract() external view returns (address);
    function nftContract() external view returns (address);

    function starterGemId() external view returns (uint256);
    
    function mintCollectionItem(uint256 quantity) external;

    function owner() external view returns (address);
    function renounceOwnership() external;
    function transferOwnership(address newOwner) external;
}
