// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../SpacePiratesTokens.sol";
import "./SpacePiratesNFT.sol";

/**
 * @title Space Pirates NFT Collection Factory
 * @author @Gr3it, @yuripaoloni (reviewer)
 * @notice Create collection settig parameters like start, end, supply
 */

contract NFTCollectionFactory is Ownable {
    SpacePiratesNFT public immutable nftContract;
    SpacePiratesTokens public immutable tokenContract;

    uint256 public constant DOUBLOONS = 1;
    uint256 public constant ASTEROIDS = 2;
    uint256 public constant EVOCATION_GEM = 1001;

    uint128 public doubloonsPrice = 10_000 * 1e18;
    uint128 public asteroidsPrice = 20 * 1e18;

    struct Collection {
        uint112 available; // type(uint112).max for unlimited supply
        uint64 start; //start of the sale of the collection
        uint64 end; //end of the sale of the collection. 0 for unlimited time collection
        uint16 maxMintPerAddress; // 0 for disabled option
    }
    string[] public availableCollections;

    mapping(string => bool) public exist;
    mapping(string => Collection) public collections;
    mapping(string => mapping(address => uint256)) public nbrOfCollectionMinted; //collection -> address -> number minted

    event CreateCollection(
        string name,
        uint112 available,
        uint64 start,
        uint64 end,
        uint16 maxMintPerAddress
    );
    event EditCollection(
        string indexed name,
        uint112 available,
        uint64 start,
        uint64 end,
        uint16 maxMintPerAddress
    );
    event SetPrice(uint128 newDoubloonsPrice, uint128 newAsteroidsPrice);

    constructor(SpacePiratesTokens _tokenContract, SpacePiratesNFT _nftContract)
    {
        tokenContract = _tokenContract;
        nftContract = _nftContract;
    }

    function getCollectionsList() external view returns (string[] memory) {
        return availableCollections;
    }

    function mintCollectionItem(string calldata name, uint256 quantity)
        external
    {
        require(quantity > 0, "NFTCollectionFactory: can't mint 0 NFT");
        require(
            exist[name],
            "NFTCollectionFactory: the collection does not exist"
        );
        Collection memory collection = collections[name];
        require(
            block.timestamp >= collection.start,
            "NFTCollectionFactory: collection not started yet"
        );
        require(
            collection.end == 0 || block.timestamp <= collection.end,
            "NFTCollectionFactory: collection already ended"
        );
        if (collection.available != type(uint112).max) {
            require(
                quantity <= collection.available,
                "NFTCollectionFactory: mint quantity exceed availability"
            );
            collections[name].available -= uint112(quantity);
        }
        if (collection.maxMintPerAddress != 0) {
            require(
                nbrOfCollectionMinted[name][msg.sender] + quantity <=
                    collection.maxMintPerAddress,
                "NFTCollectionFactory: exceeded address mint limit"
            );
            nbrOfCollectionMinted[name][msg.sender] += quantity;
        }

        uint256[] memory ids = new uint256[](3);
        ids[0] = DOUBLOONS;
        ids[1] = ASTEROIDS;
        ids[2] = EVOCATION_GEM;

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = quantity * doubloonsPrice;
        amounts[1] = quantity * asteroidsPrice;
        amounts[2] = quantity;

        tokenContract.burnBatch(msg.sender, ids, amounts);
        nftContract.mint(msg.sender, name, quantity, false);
    }

    function createCollection(
        string calldata name,
        uint112 available,
        uint64 start,
        uint64 end,
        uint16 maxMintPerAddress
    ) external onlyOwner {
        require(!exist[name], "NFTCollectionFactory: collection already exist");
        require(
            available != 0,
            "NFTCollectionFactory: collection of 0 element"
        );
        exist[name] = true;
        availableCollections.push(name);
        collections[name] = Collection(
            available,
            start,
            end,
            maxMintPerAddress
        );
        emit CreateCollection(name, available, start, end, maxMintPerAddress);
    }

    function editCollection(
        string calldata name,
        uint112 available,
        uint64 start,
        uint64 end,
        uint16 maxMintPerAddress
    ) external onlyOwner {
        require(exist[name], "NFTCollectionFactory: collection does not exist");
        require(
            available != 0,
            "NFTCollectionFactory: collection of 0 element"
        );
        collections[name] = Collection(
            available,
            start,
            end,
            maxMintPerAddress
        );
        emit EditCollection(name, available, start, end, maxMintPerAddress);
    }

    function setPrice(uint128 newDoubloonsPrice, uint128 newAsteroidsPrice)
        external
        onlyOwner
    {
        doubloonsPrice = newDoubloonsPrice;
        asteroidsPrice = newAsteroidsPrice;
        emit SetPrice(newDoubloonsPrice, newAsteroidsPrice);
    }
}
