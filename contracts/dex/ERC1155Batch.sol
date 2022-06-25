// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract ERC1155Batch {
    address public tokenContract;

    function _batchInit(address _tokenContract) internal {
        tokenContract = _tokenContract;
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
            getArrayPair(id0, id1),
            getArrayPair(amount0, amount1),
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
            getArrayPair(account, account),
            getArrayPair(id0, id1)
        );

        balance0 = batchBalances[0];
        balance1 = batchBalances[1];
    }
}
