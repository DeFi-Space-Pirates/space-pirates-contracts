// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SpacePiratesNFT is ERC721, AccessControl {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;
    string private baseURI;

    bytes32 public constant TRUSTED_TRANSFER = keccak256("TRUSTED_TRANSFER");
    bytes32 public constant CAN_MINT = keccak256("CAN_MINT");
    bytes32 public constant CAN_BURN = keccak256("CAN_BURN");

    struct AdditionalInfo {
        string collection;
        uint128 charges;
        uint64 lastRecovery;
        bool locked;
    }
    mapping(uint256 => AdditionalInfo) public nftData;

    constructor() ERC721("Space Pirates NFTs", "SP-NFT") {}

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "SpacePiratesNFT: URI query for nonexistent token"
        );

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;
        uint256 supply = totalSupply();

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= supply) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    function mint(
        uint256 quantity,
        string memory collection,
        bool locked
    ) public onlyRole(CAN_MINT) {
        require(quantity > 0, "spacePiratesNFT: need to mint at least 1 NFT");
        for (uint256 i = 0; i < quantity; ++i) {
            _tokenIdCounter.increment();
            nftData[_tokenIdCounter.current()] = AdditionalInfo(
                collection,
                0,
                uint64(block.timestamp),
                locked
            );
            _mint(msg.sender, _tokenIdCounter.current());
        }
    }

    function burn(uint256 tokenId) public onlyRole(CAN_BURN) {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC721: caller is not token owner nor approved"
        );
        _burn(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        require(
            !nftData[tokenId].locked,
            "SpacePiratesNFT: NFT not transferable"
        );
        if (!hasRole(TRUSTED_TRANSFER, msg.sender)) {
            AdditionalInfo storage nft = nftData[tokenId];
            nft.lastRecovery = uint64(block.timestamp);
            nft.charges = 0;
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
