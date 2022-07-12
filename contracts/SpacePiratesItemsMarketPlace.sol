// SPDX-License-Identifier: unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./SpacePiratesTokens.sol";

/**
 * @title Space Pirates Items Market Place
 * @author @Gr3it, @yuripaoloni (reviewer), @MatteoLeonesi (reviewer)
 * @notice Split Asteroids tokens in their underlying tokens and vice versa
 */

contract SpacePiratesItemsMarketPlace is Ownable {
    SpacePiratesTokens public immutable tokenContract;

    event AddItems(
        uint32[] indexed itemsIds,
        uint16[] itemsQuantities,
        uint128 paymentId,
        uint128 price,
        uint120 saleEnd,
        uint120 available,
        uint16 maxBuyPerAddress
    );

    event BuyItem(
        uint32[] indexed itemsIds,
        uint128 paymentId,
        uint128 price,
        uint64 quantity
    );

    struct Sale {
        uint32[] itemsIds;
        uint16[] itemsQuantities;
        uint128 paymentId;
        uint128 price;
        uint120 saleEnd; // 0 for a continued sale
        uint120 available; // type(uint64).max for unlimited supply
        uint16 maxBuyPerAddress; // 0 for unlimited amount
        mapping(address => uint256) Bought;
    }

    Sale[] public sales;
    mapping(uint256 => uint256[]) public saleIndexes; // store the indexes of the sales that include the items
    uint256[] public itemsOnSale;

    constructor(SpacePiratesTokens _tokenContract) {
        tokenContract = _tokenContract;
    }

    function createSale(
        uint32[] calldata itemsIds,
        uint16[] calldata itemsQuantities,
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
            uint32 itemsId = itemsIds[i];
            require(
                (itemsId >= 20_000 && itemsId <= 99_999) ||
                    (itemsId >= 100_000 && itemsId <= 199_999) ||
                    (itemsId >= 1_000 && itemsId <= 9_999),
                "SpacePiratesItemsMarketPlace: invalid id"
            );
            if (saleIndexes[itemsId].length == 0) {
                itemsOnSale.push(itemsId);
            }
            saleIndexes[itemsId].push(saleIndex);
        }

        Sale storage sale = sales.push();
        sale.itemsIds = itemsIds;
        sale.itemsQuantities = itemsQuantities;
        sale.paymentId = paymentId;
        sale.price = price;
        sale.saleEnd = saleEnd;
        sale.available = available;
        sale.maxBuyPerAddress = maxBuyPerAddress;

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

    function buyItem(
        uint256 itemId,
        uint256 saleIndex,
        uint64 quantity
    ) external {
        Sale memory sale = sales[itemId][saleIndex];
        require(
            sale.saleEnd == 0 || sale.saleEnd >= block.timestamp,
            "SpacePiratesItemsMarketPlace: sale ended"
        );
        if (sale.available != type(uint64).max) {
            require(
                quantity <= sale.available,
                "SpacePiratesItemsMarketPlace: buy exceed available quantity"
            );
            sales[itemId][saleIndex].available -= quantity;
        }
        tokenContract.burn(msg.sender, quantity * sale.price, sale.paymentId);
        tokenContract.mint(msg.sender, quantity * sale.itemQuantity, itemId);

        emit BuyItem(itemId, sale.paymentId, sale.price, quantity);
    }
}
