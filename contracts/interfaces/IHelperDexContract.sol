// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Helper Dex Contract Interface
 * @author @Gr3it
 */

interface IHelperDexContract {
    function getPairInitCodeHash() external pure returns (bytes32);
}
