// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Space Pirates Factory Interface
 * @author @Gr3it
 */

interface ISpacePiratesFactory {
    event PairCreated(uint256 indexed token0, uint256 indexed token1, address pair, uint256);

    function tokenContract() external view returns (address);
    
    function getPair(uint256, uint256) external view returns (address);
    function allPairs(uint256) external view returns (address);
    function allPairsLength() external view returns (uint256);

    function createPair(uint128 tokenA, uint128 tokenB) external returns (address pair);
    
    function feeTo() external view returns (address);
    function setFeeTo(address _feeTo) external;

    function owner() external view returns (address);
    function transferOwnership(address newOwner) external;
    function renounceOwnership() external;
}
