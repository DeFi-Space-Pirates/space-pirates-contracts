// SPDX-License-Identifier: unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./SpacePiratesTokens.sol";

/**
 * @title Space Pirates Faucet Contract
 * @author @yuripaoloni, @MatteoLeonesi, @Gr3it
 * @notice Mint up to 10k doubloons and asteroids to users in testnet
 */

contract SpacePiratesFaucet is Ownable {
    SpacePiratesTokens public immutable tokenContract;

    mapping(uint256 => uint256) public tokenMintLimit;
    uint256[] public supportedTokens;

    event SetMintLimit(uint256 indexed tokenId, uint256 mintLimit);
    event TokenMint(address indexed to, uint256 indexed tokenId, uint256 value);

    constructor(SpacePiratesTokens _tokenContract) {
        tokenContract = _tokenContract;
    }

    function getSupportedTokens() external view returns (uint256[] memory) {
        return supportedTokens;
    }

    function mintToken(uint256 tokenId, uint256 amount) public {
        require(
            amount <= tokenMintLimit[tokenId],
            "SpacePiratesFaucet: mint limit exceeded"
        );

        tokenContract.mint(msg.sender, tokenId, amount);
        emit TokenMint(msg.sender, tokenId, amount);
    }

    function setMintLimit(uint256 tokenId, uint256 mintLimit) public onlyOwner {
        if (tokenMintLimit[tokenId] == 0) {
            supportedTokens.push(tokenId);
        }
        tokenMintLimit[tokenId] = mintLimit;
        emit SetMintLimit(tokenId, mintLimit);
    }
}
