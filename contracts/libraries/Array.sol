// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Array {
    function getArray(uint256 x, uint256 y)
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
