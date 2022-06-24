// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISpacePiratesFactory {
    event PairCreated(
        uint256 indexed token0,
        uint256 indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function getPair(uint256 tokenA, uint256 tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(uint256 tokenA, uint256 tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;
}
