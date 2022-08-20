// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/ISpacePiratesPair.sol";

library SpacePiratesDexLibrary {
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(uint256 tokenA, uint256 tokenB)
        internal
        pure
        returns (uint256 token0, uint256 token1)
    {
        require(tokenA != tokenB, "SpacePiratesDexLibrary: IDENTICAL_IDS");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        uint256 tokenA,
        uint256 tokenB
    ) internal pure returns (address pair) {
        (uint256 token0, uint256 token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encodePacked(token0, token1)),
                            hex"a351fc001cc4b002bd0b5d16720fd490c335e1133f20186ae4814f59876c46dc" // init code hash generated using EVM solc 0.8.7(commit.e28d00a7) optimizer enabled and setted at 200 runs
                        )
                    )
                )
            )
        );
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        uint256 tokenA,
        uint256 tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (uint256 token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = ISpacePiratesPair(
            pairFor(factory, tokenA, tokenB)
        ).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "SpacePiratesDexLibrary: INSUFFICIENT_AMOUNT");
        require(
            reserveA > 0 && reserveB > 0,
            "SpacePiratesDexLibrary: INSUFFICIENT_LIQUIDITY"
        );
        amountB = (amountA * reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(
            amountIn > 0,
            "SpacePiratesDexLibrary: INSUFFICIENT_INPUT_AMOUNT"
        );
        require(
            reserveIn > 0 && reserveOut > 0,
            "SpacePiratesDexLibrary: INSUFFICIENT_LIQUIDITY"
        );
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(
            amountOut > 0,
            "SpacePiratesDexLibrary: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        require(
            reserveIn > 0 && reserveOut > 0,
            "SpacePiratesDexLibrary: INSUFFICIENT_LIQUIDITY"
        );
        uint256 numerator = reserveIn * amountOut * 1000;
        uint256 denominator = (reserveOut - amountOut) * 997;
        amountIn = (numerator / denominator) + 1;
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        uint256[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "SpacePiratesDexLibrary: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i = 0; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i],
                path[i + 1]
            );
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        uint256[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "SpacePiratesDexLibrary: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i - 1],
                path[i]
            );
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}
