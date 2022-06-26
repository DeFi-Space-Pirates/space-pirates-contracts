// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SpacePiratesTokens.sol";

/**
 * @title Asteroids Split Contract
 * @author @Gr3it, @yuripaoloni (reviewer), @MatteoLeonesi (reviewer)
 * @notice Split Asteroids tokens in their underlying tokens and vice versa
 */

contract AsteroidsSplitContract {
    uint256 public constant ASTEROIDS = 2;
    uint256 public constant VE_ASTEROIDS = 3;
    uint256 public constant STK_ASTEROIDS = 4;

    SpacePiratesTokens public immutable tokenContract;

    event SplitAsteroids(address indexed sender, uint256 amount);
    event MergeAsteroids(address indexed sender, uint256 amount);

    constructor(SpacePiratesTokens _tokenContract) {
        tokenContract = _tokenContract;
    }

    function splitAsteroids(uint256 amount) public {
        tokenContract.burn(msg.sender, amount, ASTEROIDS);
        tokenContract.mintBatch(
            msg.sender,
            getArrayPair(VE_ASTEROIDS, STK_ASTEROIDS),
            getArrayPair(amount, amount)
        );

        emit SplitAsteroids(msg.sender, amount);
    }

    function mergeAsteroids(uint256 amount) public {
        tokenContract.burnBatch(
            msg.sender,
            getArrayPair(VE_ASTEROIDS, STK_ASTEROIDS),
            getArrayPair(amount, amount)
        );
        tokenContract.mint(msg.sender, amount, ASTEROIDS);

        emit MergeAsteroids(msg.sender, amount);
    }

    function getArrayPair(uint256 x, uint256 y)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory array = new uint256[](2);
        array[0] = x;
        array[1] = y;
        return array;
    }
}
