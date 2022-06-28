// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "../libraries/Array.sol";

/**
 * @title ERC1155 Batch Contract
 * @author @Gr3it, @yuripaoloni (reviewer), @MatteoLeonesi (reviewer)
 * @notice Prevent Stack Too Deep Errors
 */

contract ERC1155Batch {
    address public tokenContract;

    function _batchInit(address _tokenContract) internal {
        tokenContract = _tokenContract;
    }

    // avoids stack too deep errors
    function safeBatchTransferFromPair(
        address from,
        address to,
        uint256 id0,
        uint256 id1,
        uint256 amount0,
        uint256 amount1
    ) internal {
        IERC1155(tokenContract).safeBatchTransferFrom(
            from,
            to,
            Array.getArrayPair(id0, id1),
            Array.getArrayPair(amount0, amount1),
            ""
        );
    }

    // avoids stack too deep errors
    function balanceOfBatchPair(
        address account,
        uint256 id0,
        uint256 id1
    ) internal view returns (uint256 balance0, uint256 balance1) {
        uint256[] memory batchBalances = new uint256[](2);

        batchBalances = IERC1155(tokenContract).balanceOfBatch(
            Array.getArrayPair(account, account),
            Array.getArrayPair(id0, id1)
        );

        balance0 = batchBalances[0];
        balance1 = batchBalances[1];
    }
}
