// SPDX-License-Identifier: unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./SpacePiratesTokens.sol";

/**
 * @title Space Pirates Items Market Place
 * @author @Gr3it, @yuripaoloni (reviewer)
 * @notice Create sales of items, titles and battle fields
 */

contract SpacePiratesItemsMarketPlace is Ownable {
    SpacePiratesTokens public immutable tokenContract;

    event AddItems(
        uint256[] indexed itemsIds,
        uint256[] itemsQuantities,
        uint128 paymentId,
        uint128 price,
        uint120 saleEnd,
        uint120 available,
        uint16 maxBuyPerAddress
    );

    event BuyItem(
        uint256[] indexed itemsIds,
        uint128 paymentId,
        uint128 price,
        uint64 quantity
    );

    struct Sale {
        uint256[] itemsIds;
        uint256[] itemsQuantities;
        uint128 paymentId;
        uint128 price;
        uint120 saleEnd; // 0 for a continued sale
        uint120 available; // type(uint120).max for unlimited supply
        uint16 maxBuyPerAddress; // 0 for unlimited amount
    }

    Sale[] public sales;
    mapping(uint256 => mapping(address => uint256)) bought; // SaleIndex -> Address -> Number Of Items bought
    mapping(uint256 => uint256[]) public saleIndexes; // store the indexes of the sales that include the items
    uint256[] public itemsOnSale;

    constructor(SpacePiratesTokens _tokenContract) {
        tokenContract = _tokenContract;
    }

    function itemsOnSaleArray() external view returns (uint256[] memory) {
        return itemsOnSale;
    }

    function salesIndexesFromId(uint256 id)
        external
        view
        returns (uint256[] memory)
    {
        return saleIndexes[id];
    }

    function salesAmount() external view returns (uint256 amount) {
        return sales.length;
    }

    function saleItemsIds(uint256 saleIndex)
        external
        view
        returns (uint256[] memory)
    {
        Sale memory sale = sales[saleIndex];
        return sale.itemsIds;
    }

    function saleItemsQuantities(uint256 saleIndex)
        external
        view
        returns (uint256[] memory)
    {
        Sale memory sale = sales[saleIndex];
        return sale.itemsQuantities;
    }

    function createSale(
        uint256[] calldata itemsIds,
        uint256[] calldata itemsQuantities,
        uint128 paymentId,
        uint128 price,
        uint120 saleEnd,
        uint120 available,
        uint16 maxBuyPerAddress
    ) external onlyOwner {
        require(
            itemsIds.length == itemsQuantities.length,
            "SpacePiratesItemsMarketPlace: array with different sizes"
        );

        uint256 saleIndex = sales.length;
        for (uint256 i = 0; i < itemsIds.length; i++) {
            uint256 itemsId = itemsIds[i];
            require(
                (itemsId >= 20_000 && itemsId <= 99_999) ||
                    (itemsId >= 1_000 && itemsId <= 9_999) ||
                    (itemsId >= 100_000 && itemsId <= 199_999),
                "SpacePiratesItemsMarketPlace: invalid id"
            );
            if (saleIndexes[itemsId].length == 0) {
                itemsOnSale.push(itemsId);
            }
            saleIndexes[itemsId].push(saleIndex);
        }

        sales.push(
            Sale(
                itemsIds,
                itemsQuantities,
                paymentId,
                price,
                saleEnd,
                available,
                maxBuyPerAddress
            )
        );

        emit AddItems(
            itemsIds,
            itemsQuantities,
            paymentId,
            price,
            saleEnd,
            available,
            maxBuyPerAddress
        );
    }

    function buyItem(uint256 saleIndex, uint16 quantity) external {
        Sale memory sale = sales[saleIndex];
        require(
            sale.saleEnd == 0 || sale.saleEnd >= block.timestamp,
            "SpacePiratesItemsMarketPlace: sale ended"
        );
        if (sale.available != type(uint120).max) {
            require(
                quantity <= sale.available,
                "SpacePiratesItemsMarketPlace: buy exceed available quantity"
            );
            sales[saleIndex].available -= quantity;
        }
        if (sale.maxBuyPerAddress != 0) {
            require(
                bought[saleIndex][msg.sender] + quantity <=
                    sale.maxBuyPerAddress,
                "SpacePiratesItemsMarketPlace: exceed user max mint"
            );
            bought[saleIndex][msg.sender] += quantity;
        }
        for (uint256 i = 0; i < sale.itemsQuantities.length; ++i) {
            sale.itemsQuantities[i] *= quantity;
        }

        tokenContract.burn(msg.sender, sale.paymentId, quantity * sale.price);
        tokenContract.mintBatch(
            msg.sender,
            sale.itemsIds,
            sale.itemsQuantities
        );

        emit BuyItem(sale.itemsIds, sale.paymentId, sale.price, quantity);
    }
}
