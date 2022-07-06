// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Asteroids Split Contract Interface
 * @author @Gr3it
 */

interface ISpacePiratesItemsMarketPlace {
    event AddItems(uint256 indexed itemId, uint128 paymentId, uint128 price, uint64 itemQuantity, uint64 saleEnd, uint64 available);
    event BuyItem(uint256 indexed itemId, uint128 paymentId, uint128 price, uint64 quantity);

    function tokenContract() external view returns(address);
    function itemsOnSale(uint256 index) external view returns(uint256 id);
    function sales(uint256 id, uint256 index) external view returns (uint128 paymentId, uint128 price, uint64 itemQuantity, uint64 saleEnd, uint64 available);
    
    function createSale(uint256 itemId, uint128 paymentId, uint128 price, uint64 itemQuantity, uint64 saleEnd, uint64 available ) external;
    
    function buyItem(uint256 itemId, uint256 saleIndex, uint64 quantity) external;
    
    function owner() external view returns(address);
    function transferOwnership(address newOwner) external;
    function renounceOwnership() external;
}
