// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Space Pirates Router Interface
 * @author @Gr3it
 */

interface ISpacePiratesRouter {
    function SPACE_ETH_ID() external view returns (uint256);
    
    function tokenContract() external view returns (address);
    function factory() external view returns (address);
    function wrapper() external view returns (address);
    
    function addLiquidity(uint256 tokenA, uint256 tokenB, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);
    function addLiquidityETH(uint256 token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
    function addLiquidityERC20(address erc20Contract, uint256 token, uint256 amountTokenDesired, uint256 amountERC20Desired, uint256 amountTokenMin, uint256 amountERC20Min, address to, uint256 deadline) external returns (uint256 amountToken, uint256 amountERC20, uint256 liquidityAndId);
    
    function removeLiquidity(uint256 tokenA, uint256 tokenB, uint256 liquidity, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) external returns (uint256 amountA, uint256 amountB);
    function removeLiquidityETH(uint256 token, uint256 liquidity, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external returns (uint256 amountToken, uint256 amountETH);
    function removeLiquidityERC20(address erc20Contract, uint256 token, uint256 liquidity, uint256 amountTokenMin, uint256 amountERC20Min, address to, uint256 deadline) external returns (uint256 amountToken, uint256 amountERC20);
    
    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, uint256[] memory path, address to, uint256 deadline) external returns (uint256[] memory amounts);
    function swapTokensForExactTokens(uint256 amountOut, uint256 amountInMax, uint256[] memory path, address to, uint256 deadline) external returns (uint256[] memory amounts);
    
    function swapExactETHForTokens(uint256 amountOutMin, uint256[] memory path, address to, uint256 deadline) external returns (uint256[] memory amounts);
    function swapExactTokensForETH(uint256 amountIn, uint256 amountOutMin, uint256[] memory path, address to, uint256 deadline) external returns (uint256[] memory amounts);
    function swapETHForExactTokens(uint256 amountOut, uint256[] memory path, address to, uint256 deadline) external returns (uint256[] memory amounts);
    function swapTokensForExactETH(uint256 amountOut, uint256 amountInMax, uint256[] memory path, address to, uint256 deadline) external returns (uint256[] memory amounts);
    
    function swapExactERC20ForTokens(address erc20Contract, uint256 amountIn, uint256 amountOutMin, uint256[] memory path, address to, uint256 deadline) external returns (uint256[] memory amounts);
    function swapExactTokensForERC20(address erc20Contract, uint256 amountIn, uint256 amountOutMin, uint256[] memory path, address to, uint256 deadline) external returns (uint256[] memory amounts);
    function swapERC20ForExactTokens(address erc20Contract, uint256 amountIn, uint256 amountOut, uint256[] memory path, address to, uint256 deadline) external returns (uint256[] memory amounts);
    function swapTokensForExactERC20(address erc20Contract, uint256 amountOut, uint256 amountInMax, uint256[] memory path, address to, uint256 deadline) external returns (uint256[] memory amounts);
    
    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) external returns (bytes4);
    function onERC1155Received(address, address, uint256, uint256, bytes memory) external returns (bytes4);
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    
    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external pure returns (uint256 amountB);
    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) external pure returns (uint256 amountIn);
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) external pure returns (uint256 amountOut);
    function getAmountsIn(uint256 amountOut, uint256[] memory path) external view returns (uint256[] memory amounts);
    function getAmountsOut(uint256 amountIn, uint256[] memory path) external view returns (uint256[] memory amounts);
}
