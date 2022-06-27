// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Space Pirates Pair Interface
 * @author @Gr3it
 */

import "./ISpacePiratesLPToken.sol";

interface ISpacePiratesPair is ISpacePiratesLPToken {
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external view returns (uint256);
    
    function factory() external view returns (address);
    function tokenContract() external view returns (address);
    function initialize(uint128 _token0, uint128 _token1, address _tokenContract) external;
    
    function kLast() external view returns (uint256);
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    function getTokenIds() external view returns (uint128 _token0, uint128 _token1);
    function price0CumulativeLast() external view returns (uint256);
    function price1CumulativeLast() external view returns (uint256);
    
    function mint(address to) external returns (uint256 liquidity);
    function burn(address to) external returns (uint256 amount0, uint256 amount1);
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes memory data) external;
    function skim(address to) external;
    function sync() external;
    
    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) external returns (bytes4);
    function onERC1155Received(address, address, uint256, uint256, bytes memory data) external returns (bytes4);
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
