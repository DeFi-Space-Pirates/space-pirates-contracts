// SPDX-License-Identifier: unlicense
pragma solidity ^0.8.0;

/**
 * @title Chain Id Contract
 * @author @Gr3it
 * @notice Get Chain Id (for tron)
 */

contract ChainId {
    uint256 public immutable CHAIN_ID;

    constructor() {
        CHAIN_ID = block.chainid;
    }
}
