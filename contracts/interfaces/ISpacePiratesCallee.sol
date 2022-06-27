// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Space Pirates Callee Interface
 * @author @Gr3it
 */

interface ISpacePiratesCallee {
    function spacePiratesCall(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external;
}
