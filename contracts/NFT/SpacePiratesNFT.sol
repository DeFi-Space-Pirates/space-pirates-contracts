// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title Space Pirates NFT Storage
 * @author @Gr3it, @yuripaoloni (reviewer)
 * @notice Storage all the NFTs data of the protocol
 */

contract SpacePiratesNFT is ERC721, AccessControl {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;
    string private baseURI;

    bytes32 public constant CAN_MINT = keccak256("CAN_MINT");
    bytes32 public constant CAN_BURN = keccak256("CAN_BURN");
    bytes32 public constant URI_SETTER = keccak256("URI_SETTER");

    struct AdditionalInfo {
        string collection;
        bool locked;
    }
    mapping(uint256 => AdditionalInfo) public nftData;

    event Mint(address indexed to, uint256 id, string collection, bool locked);
    event SetBaseURI(string newUri);
    event GrantRole(bytes32 indexed role, address account);
    event RevokeRole(bytes32 indexed role, address account);

    constructor(string memory _baseURI) ERC721("Space Pirates NFTs", "SP-NFT") {
        baseURI = _baseURI;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function supply() public view returns (uint256) {
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

        return string(abi.encodePacked(baseURI, tokenId.toString()));
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
        uint256 currentSupply = supply();

        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= currentSupply
        ) {
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
        address to,
        string memory collection,
        uint256 quantity,
        bool locked
    ) public onlyRole(CAN_MINT) {
        require(quantity > 0, "spacePiratesNFT: need to mint at least 1 NFT");
        for (uint256 i = 0; i < quantity; ++i) {
            _tokenIdCounter.increment();
            uint256 id = _tokenIdCounter.current();
            nftData[id] = AdditionalInfo(collection, locked);
            _mint(to, id);
            emit Mint(to, id, collection, locked);
        }
    }

    function burn(uint256 tokenId) public onlyRole(CAN_BURN) {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC721: caller is not token owner nor approved"
        );
        _burn(tokenId);
    }

    function setBaseURI(string calldata _baseURI)
        external
        onlyRole(URI_SETTER)
    {
        baseURI = _baseURI;
        emit SetBaseURI(_baseURI);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        require(
            !nftData[tokenId].locked || from == address(0) || to == address(0),
            "SpacePiratesNFT: NFT not transferable"
        );
    }

    function grantRole(bytes32 role, address account)
        public
        override
        onlyRole(getRoleAdmin(role))
    {
        _grantRole(role, account);
        emit GrantRole(role, account);
    }

    function revokeRole(bytes32 role, address account)
        public
        override
        onlyRole(getRoleAdmin(role))
    {
        _revokeRole(role, account);
        emit RevokeRole(role, account);
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
