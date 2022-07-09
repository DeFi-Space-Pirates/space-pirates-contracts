// SPDX-License-Identifier: unlicense
pragma solidity ^0.8.0;

/**
 * @title Battle Field First Collection Mint Implementation
 * @author @Gr3it
 */

interface IBattleFieldFirstCollection {
    event Mint(address indexed user, uint256 id);
    
    function MAX_MINT_PER_ADDRESS() external view returns(uint256 maxMint);
    function MAX_SUPPLY() external view returns(uint256 maxSupply);
    function PAYING_ID() external view returns(uint256 payingId);
    function PRICE() external view returns(uint256 price);

    function tokenContract() external view returns(address tokenContract);
    
    function totalSupply() external view returns(uint256 totalSupply);
    function mintId() external view returns(uint256 mintId);
    function nbOfBFsMintedBy(address) external view returns(uint256 amount);
    
    function startTime() external view returns(uint256 startTime);
    function duration() external view returns(uint256 duration);
    
    function mint(uint256 _quantity) external;
}
