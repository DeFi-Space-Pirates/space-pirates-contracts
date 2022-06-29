// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Helpers internal library
 * @author @HenricoW
 * @notice Collection of utility functions
 */
library Array {
    /**
     * @notice Convert pair of uint256 inputs to an array
     */
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

    /**
     * @notice Convert pair of address inputs to an array
     */
    function getArrayPair(address x, address y)
        internal
        pure
        returns (address[] memory)
    {
        address[] memory array = new address[](2);
        array[0] = x;
        array[1] = y;
        return array;
    }
}