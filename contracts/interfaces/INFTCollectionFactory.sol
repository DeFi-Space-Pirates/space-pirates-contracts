// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Space Pirates NFT Collection Factory Interface
 * @author @Gr3it
 */

interface INFTCollectionFactory {
    event CreateCollection(string name, uint112 available, uint64 start, uint64 end, uint16 maxMintPerAddress);
    event EditCollection(string indexed name, uint112 available, uint64 start, uint64 end, uint16 maxMintPerAddress);
    event SetPrice(uint128 newDoubloonsPrice, uint128 newAsteroidsPrice);

    function ASTEROIDS() external view returns (uint256 id);
    function DOUBLOONS() external view returns (uint256 id);
    function EVOCATION_GEM() external view returns (uint256 id);

    function tokenContract() external view returns (address);
    function nftContract() external view returns (address);

    function asteroidsPrice() external view returns (uint128 price);
    function doubloonsPrice() external view returns (uint128 price);

    function availableCollections(uint256 index) external view returns (string memory name);

    function exist(string calldata) external view returns (bool);
    function collections(string calldata name) external view returns (uint112 available, uint64 start, uint64 end, uint16 maxMintPerAddress);
    function nbrOfCollectionMinted(string calldata, address) external view returns (uint256);
    function getCollectionsList() external view returns (string[] memory);

    function mintCollectionItem(string calldata name, uint256 quantity) external;
    
    function createCollection(string calldata name, uint112 available, uint64 start, uint64 end, uint16 maxMintPerAddress) external;
    function editCollection(string calldata name, uint112 available, uint64 start, uint64 end, uint16 maxMintPerAddress) external;

    function setPrice(uint128 newDoubloonsPrice, uint128 newAsteroidsPrice) external;

    function owner() external view returns (address);
    function renounceOwnership() external;
    function transferOwnership(address newOwner) external;
}
