// SPDX-License-Identifier: unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./SpacePiratesTokens.sol";

/**
 * @title Asteroids Split Contract
 * @author @Gr3it, @yuripaoloni (reviewer), @MatteoLeonesi (reviewer)
 * @notice Split Asteroids tokens in their underlying tokens and vice versa
 */

contract SpacePiratesItemsMarketPlace is Ownable {
    SpacePiratesTokens public immutable tokenContract;

    event AddItems(
        uint256 indexed itemId,
        uint128 paymentId,
        uint128 price,
        uint64 itemQuantity,
        uint64 saleEnd,
        uint64 available
    );
    event BuyItem(
        uint256 indexed itemId,
        uint128 paymentId,
        uint128 price,
        uint64 quantity
    );

    struct Sale {
        uint128 paymentId;
        uint128 price;
        uint64 itemQuantity;
        uint64 saleEnd; // 0 for a continued sale
        uint64 available; // type(uint62).max for unlimited supply
    }

    mapping(uint256 => Sale[]) public sales;
    uint256[] public itemsOnSale;

    constructor(SpacePiratesTokens _tokenContract) {
        tokenContract = _tokenContract;
    }

    function createSale(
        uint256 itemId,
        uint128 paymentId,
        uint128 price,
        uint64 itemQuantity,
        uint64 saleEnd,
        uint64 available
    ) external onlyOwner {
        require(
            (itemId >= 20_000 && itemId <= 99_999) ||
                (itemId >= 1_000 && itemId <= 9_999),
            "SpacePiratesItemsMarketPlace: invalid id"
        );
        if (sales[itemId].length == 0) {
            itemsOnSale.push(itemId);
        }
        sales[itemId].push(
            Sale(paymentId, price, itemQuantity, saleEnd, available)
        );
        emit AddItems(
            itemId,
            paymentId,
            price,
            itemQuantity,
            saleEnd,
            available
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
