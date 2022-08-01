// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../SpacePiratesTokens.sol";
import "./SpacePiratesNFT.sol";

/**
 * @title Space Pirates NFT Starter Collection
 * @author @Gr3it, @yuripaoloni (reviewer)
 * @notice NFT Starter collection
 */

contract NFTStarterBanner is Ownable {
    SpacePiratesNFT public immutable nftContract;
    SpacePiratesTokens public immutable tokenContract;

    uint256 public constant starterGemId = 1000;

    constructor(SpacePiratesTokens _tokenContract, SpacePiratesNFT _nftContract)
    {
        tokenContract = _tokenContract;
        nftContract = _nftContract;
    }

    function mintCollectionItem(uint256 quantity) external {
        require(quantity > 0, "NFTCollectionFactory: can't mint 0 NFT");
        tokenContract.burn(msg.sender, starterGemId, quantity);
        nftContract.mint(msg.sender, "Starter collection", quantity, true);
    }
}
