// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Asteroids Split Contract Interface
 * @author @Gr3it
 */

interface ISpacePiratesItemsMarketPlace {
    event AddItems(uint256[] indexed itemsIds, uint256[] itemsQuantities, uint128 paymentId, uint128 price, uint120 saleEnd, uint120 available, uint16 maxBuyPerAddress);
    event BuyItem(uint256[] indexed itemsIds, uint128 paymentId, uint128 price, uint64 quantity);

    function tokenContract() external view returns(address tokenContract);

    function itemsOnSale(uint256 index) external view returns(uint256 id);
    function itemsOnSaleArray() external view returns (uint256[] memory ids);

    function saleItemsIds(uint256 saleIndex) external view returns (uint256[] memory ids);
    function saleItemsQuantities(uint256 saleIndex) external view returns (uint256[] memory quantities);
    
    function saleIndexes(uint256 id, uint256 index) external view returns (uint256 saleIndex);
    function salesIndexesFromId(uint256 id) external view returns (uint256[] memory saleIndexes);

    function sales(uint256 saleIndex) external view returns (uint128 paymentId, uint128 price, uint120 saleEnd, uint120 available, uint16 maxBuyPerAddress);
    function salesAmount() external view returns (uint256 amount);

    function createSale(uint256 itemId, uint128 paymentId, uint128 price, uint64 itemQuantity, uint64 saleEnd, uint64 available ) external;
    
    function buyItem(uint256 itemId, uint256 saleIndex, uint64 quantity) external;
    
    function owner() external view returns(address);
    function transferOwnership(address newOwner) external;
    function renounceOwnership() external;
}
