// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAsteroidsSplitContract {
    event SplitAsteroids(address indexed sender, uint256 amount);
    event MergeAsteroids(address indexed sender, uint256 amount);
    
    function ASTEROIDS() external view returns (uint256);
    function STK_ASTEROIDS() external view returns (uint256);
    function VE_ASTEROIDS() external view returns (uint256);

    function tokenContract() external view returns (address);

    function mergeAsteroids(uint256 amount) external;
    function splitAsteroids(uint256 amount) external;
}
