// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SpacePiratesTokens.sol";
import "./libraries/Array.sol";

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
        tokenContract.burn(msg.sender, ASTEROIDS, amount);
        tokenContract.mintBatch(
            msg.sender,
            Array.getArrayPair(VE_ASTEROIDS, STK_ASTEROIDS),
            Array.getArrayPair(amount, amount)
        );

        emit SplitAsteroids(msg.sender, amount);
    }

    function mergeAsteroids(uint256 amount) public {
        tokenContract.burnBatch(
            msg.sender,
            Array.getArrayPair(VE_ASTEROIDS, STK_ASTEROIDS),
            Array.getArrayPair(amount, amount)
        );
        tokenContract.mint(msg.sender, ASTEROIDS, amount);

        emit MergeAsteroids(msg.sender, amount);
    }
}
