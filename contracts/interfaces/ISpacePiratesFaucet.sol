// SPDX-License-Identifier: unlicense
pragma solidity ^0.8.0;

interface ISpacePiratesFaucet {
    event MintLimitUpdate(uint256 mintLimit);
    event DoubloonsMint(address indexed to, uint256 value);
    event AsteroidsMint(address indexed to, uint256 value);

    function ASTEROIDS() external view returns (uint256);
    function DOUBLOONS() external view returns (uint256);

    function tokenContract() external view returns (address);
    function mintLimit() external view returns (uint256);
    function mintedAsteroids(address) external view returns (uint256);
    function mintedDoubloons(address) external view returns (uint256);

    function mintAsteroids(uint256 _amount) external;
    function mintDoubloons(uint256 _amount) external;
    
    function setMintLimit(uint256 _mintLimit) external;
    
    function owner() external view returns (address);
    function transferOwnership(address newOwner) external;
    function renounceOwnership() external;
}
