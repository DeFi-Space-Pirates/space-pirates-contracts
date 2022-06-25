// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IHelperDexContract {
    function getPairInitCodeHash() external pure returns (bytes32);
}
