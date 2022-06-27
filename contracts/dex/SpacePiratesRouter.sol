// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./ERC1155Batch.sol";
import "../interfaces/ISpacePiratesFactory.sol";
import "../interfaces/ISpacePiratesPair.sol";
import "../interfaces/ISpacePiratesWrapper.sol";
import "../libraries/SpacePiratesDexLibrary.sol";

/**
 * @title Space Pirates Router Contract
 * @author @Gr3it, @yuripaoloni (reviewer), @MatteoLeonesi (reviewer)
 * @notice Let users interfact safely with the dex
 */

contract SpacePiratesRouter is ERC1155Batch, ERC1155Holder {
    uint256 public constant SPACE_ETH_ID = 100;

    ISpacePiratesWrapper public immutable wrapper;
    address public immutable factory;

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "SpacePiratesRouter: EXPIRED");
        _;
    }

    constructor(
        address _factory,
        address _tokenContract,
        ISpacePiratesWrapper _wrapper
    ) {
        factory = _factory;
        wrapper = _wrapper;
        _batchInit(_tokenContract);
    }

    receive() external payable {
        assert(msg.sender == address(wrapper)); // only accept ETH via fallback from the wrapper contract
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        uint256 tokenA,
        uint256 tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal virtual returns (uint256 amountA, uint256 amountB) {
        require(
            ISpacePiratesFactory(factory).getPair(tokenA, tokenB) != address(0),
            "SpacePiratesRouter: MISSING POOL"
        );
        (uint256 reserveA, uint256 reserveB) = SpacePiratesDexLibrary
            .getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = SpacePiratesDexLibrary.quote(
                amountADesired,
                reserveA,
                reserveB
            );
            if (amountBOptimal <= amountBDesired) {
                require(
                    amountBOptimal >= amountBMin,
                    "SpacePiratesRouter: INSUFFICIENT_B_AMOUNT"
                );
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = SpacePiratesDexLibrary.quote(
                    amountBDesired,
                    reserveB,
                    reserveA
                );
                assert(amountAOptimal <= amountADesired);
                require(
                    amountAOptimal >= amountAMin,
                    "SpacePiratesRouter: INSUFFICIENT_A_AMOUNT"
                );
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function addLiquidity(
        uint256 tokenA,
        uint256 tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        virtual
        ensure(deadline)
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        (amountA, amountB) = _addLiquidity(
            tokenA,
            tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin
        );
        address pair = SpacePiratesDexLibrary.pairFor(factory, tokenA, tokenB);

        safeBatchTransferFromPair(
            msg.sender,
            pair,
            tokenA,
            tokenB,
            amountA,
            amountB
        );

        liquidity = ISpacePiratesPair(pair).mint(to);
    }

    function addLiquidityETH(
        uint256 token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        virtual
        ensure(deadline)
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        )
    {
        (amountToken, amountETH) = _addLiquidity(
            token,
            SPACE_ETH_ID,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pair = SpacePiratesDexLibrary.pairFor(
            factory,
            token,
            SPACE_ETH_ID
        );

        IERC1155(tokenContract).safeTransferFrom(
            msg.sender,
            pair,
            token,
            amountToken,
            ""
        );
        wrapper.ethDepositTo{value: amountETH}(pair);
        liquidity = ISpacePiratesPair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountETH) {
            (bool success, ) = msg.sender.call{value: msg.value - amountETH}(
                ""
            );
            require(success, "SpacePiratesRouter: ETH transfer failed");
        }
    }

    function addLiquidityERC20(
        address erc20Contract,
        uint256 token,
        uint256 amountTokenDesired,
        uint256 amountERC20Desired,
        uint256 amountTokenMin,
        uint256 amountERC20Min,
        address to,
        uint256 deadline
    )
        external
        virtual
        ensure(deadline)
        returns (
            uint256 amountToken,
            uint256 amountERC20,
            uint256 liquidityAndId //variable reuse preventing stack too deep compile error
        )
    {
        liquidityAndId = wrapper.erc20ToId(erc20Contract); //variable reuse preventing stack too deep compile error
        (amountToken, amountERC20) = _addLiquidity(
            token,
            liquidityAndId,
            amountTokenDesired,
            amountERC20Desired,
            amountTokenMin,
            amountERC20Min
        );
        address pair = SpacePiratesDexLibrary.pairFor(
            factory,
            token,
            liquidityAndId
        );

        IERC1155(tokenContract).safeTransferFrom(
            msg.sender,
            pair,
            token,
            amountToken,
            ""
        );
        wrapper.erc20DepositTo(erc20Contract, amountERC20, pair);
        liquidityAndId = ISpacePiratesPair(pair).mint(to); //variable reuse preventing stack too deep compile error
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        uint256 tokenA,
        uint256 tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        public
        virtual
        ensure(deadline)
        returns (uint256 amountA, uint256 amountB)
    {
        address pair = SpacePiratesDexLibrary.pairFor(factory, tokenA, tokenB);
        ISpacePiratesPair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint256 amount0, uint256 amount1) = ISpacePiratesPair(pair).burn(to);
        (uint256 token0, ) = SpacePiratesDexLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0
            ? (amount0, amount1)
            : (amount1, amount0);
        require(
            amountA >= amountAMin,
            "SpacePiratesRouter: INSUFFICIENT_A_AMOUNT"
        );
        require(
            amountB >= amountBMin,
            "SpacePiratesRouter: INSUFFICIENT_B_AMOUNT"
        );
    }

    function removeLiquidityETH(
        uint256 token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        public
        virtual
        ensure(deadline)
        returns (uint256 amountToken, uint256 amountETH)
    {
        (amountToken, amountETH) = removeLiquidity(
            token,
            SPACE_ETH_ID,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        IERC1155(tokenContract).safeTransferFrom(
            address(this),
            to,
            token,
            amountToken,
            ""
        );
        wrapper.ethWithdrawTo(amountETH, to);
    }

    function removeLiquidityERC20(
        address erc20Contract,
        uint256 token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountERC20Min,
        address to,
        uint256 deadline
    )
        public
        virtual
        ensure(deadline)
        returns (uint256 amountToken, uint256 amountERC20)
    {
        uint256 erc20Id = wrapper.erc20ToId(erc20Contract);
        (amountToken, amountERC20) = removeLiquidity(
            token,
            erc20Id,
            liquidity,
            amountTokenMin,
            amountERC20Min,
            address(this),
            deadline
        );
        IERC1155(tokenContract).safeTransferFrom(
            address(this),
            to,
            token,
            amountToken,
            ""
        );
        wrapper.erc20WithdrawTo(erc20Contract, amountERC20, msg.sender);
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(
        uint256[] memory amounts,
        uint256[] memory path,
        address _to
    ) internal virtual {
        for (uint256 i = 0; i < path.length - 1; i++) {
            (uint256 input, uint256 output) = (path[i], path[i + 1]);
            (uint256 token0, ) = SpacePiratesDexLibrary.sortTokens(
                input,
                output
            );
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOut)
                : (amountOut, uint256(0));
            address to = i < path.length - 2
                ? SpacePiratesDexLibrary.pairFor(factory, output, path[i + 2])
                : _to;
            ISpacePiratesPair(
                SpacePiratesDexLibrary.pairFor(factory, input, output)
            ).swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        uint256[] calldata path,
        address to,
        uint256 deadline
    ) external virtual ensure(deadline) returns (uint256[] memory amounts) {
        amounts = SpacePiratesDexLibrary.getAmountsOut(factory, amountIn, path);
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "SpacePiratesRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        IERC1155(tokenContract).safeTransferFrom(
            msg.sender,
            SpacePiratesDexLibrary.pairFor(factory, path[0], path[1]),
            path[0],
            amounts[0],
            ""
        );
        _swap(amounts, path, to);
    }

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        uint256[] calldata path,
        address to,
        uint256 deadline
    ) external virtual ensure(deadline) returns (uint256[] memory amounts) {
        amounts = SpacePiratesDexLibrary.getAmountsIn(factory, amountOut, path);
        require(
            amounts[0] <= amountInMax,
            "SpacePiratesRouter: EXCESSIVE_INPUT_AMOUNT"
        );
        IERC1155(tokenContract).safeTransferFrom(
            msg.sender,
            SpacePiratesDexLibrary.pairFor(factory, path[0], path[1]),
            path[0],
            amounts[0],
            ""
        );
        _swap(amounts, path, to);
    }

    function swapExactETHForTokens(
        uint256 amountOutMin,
        uint256[] calldata path,
        address to,
        uint256 deadline
    )
        external
        payable
        virtual
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        require(path[0] == SPACE_ETH_ID, "SpacePiratesRouter: INVALID_PATH");
        amounts = SpacePiratesDexLibrary.getAmountsOut(
            factory,
            msg.value,
            path
        );
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "SpacePiratesRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        wrapper.ethDepositTo{value: amounts[0]}(
            SpacePiratesDexLibrary.pairFor(factory, path[0], path[1])
        );

        _swap(amounts, path, to);
    }

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        uint256[] calldata path,
        address to,
        uint256 deadline
    ) external virtual ensure(deadline) returns (uint256[] memory amounts) {
        require(
            path[path.length - 1] == SPACE_ETH_ID,
            "SpacePiratesRouter: INVALID_PATH"
        );
        amounts = SpacePiratesDexLibrary.getAmountsIn(factory, amountOut, path);
        require(
            amounts[0] <= amountInMax,
            "SpacePiratesRouter: EXCESSIVE_INPUT_AMOUNT"
        );
        IERC1155(tokenContract).safeTransferFrom(
            msg.sender,
            SpacePiratesDexLibrary.pairFor(factory, path[0], path[1]),
            path[0],
            amounts[0],
            ""
        );
        _swap(amounts, path, address(this));

        wrapper.ethWithdrawTo(amounts[amounts.length - 1], to);
    }

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        uint256[] calldata path,
        address to,
        uint256 deadline
    ) external virtual ensure(deadline) returns (uint256[] memory amounts) {
        require(
            path[path.length - 1] == SPACE_ETH_ID,
            "SpacePiratesRouter: INVALID_PATH"
        );
        amounts = SpacePiratesDexLibrary.getAmountsOut(factory, amountIn, path);
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "SpacePiratesRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        IERC1155(tokenContract).safeTransferFrom(
            msg.sender,
            SpacePiratesDexLibrary.pairFor(factory, path[0], path[1]),
            path[0],
            amounts[0],
            ""
        );
        _swap(amounts, path, address(this));

        wrapper.ethWithdrawTo(amounts[amounts.length - 1], to);
    }

    function swapETHForExactTokens(
        uint256 amountOut,
        uint256[] calldata path,
        address to,
        uint256 deadline
    )
        external
        payable
        virtual
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        require(path[0] == SPACE_ETH_ID, "SpacePiratesRouter: INVALID_PATH");
        amounts = SpacePiratesDexLibrary.getAmountsIn(factory, amountOut, path);
        require(
            amounts[0] <= msg.value,
            "SpacePiratesRouter: EXCESSIVE_INPUT_AMOUNT"
        );
        wrapper.ethDepositTo{value: amounts[0]}(
            SpacePiratesDexLibrary.pairFor(factory, path[0], path[1])
        );
        _swap(amounts, path, to);
        // refund dust eth, if any
        if (msg.value > amounts[0]) {
            (bool success, ) = msg.sender.call{value: msg.value - amounts[0]}(
                new bytes(0)
            );
            require(success, "SpacePiratesRouter: ETH transfer failed");
        }
    }

    function swapExactERC20ForTokens(
        address erc20Contract,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256[] calldata path,
        address to,
        uint256 deadline
    ) external virtual ensure(deadline) returns (uint256[] memory amounts) {
        uint256 erc20Id = wrapper.erc20ToId(erc20Contract);
        require(path[0] == erc20Id, "SpacePiratesRouter: INVALID_PATH");
        amounts = SpacePiratesDexLibrary.getAmountsOut(factory, amountIn, path);
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "SpacePiratesRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        wrapper.erc20DepositTo(
            erc20Contract,
            amounts[0],
            SpacePiratesDexLibrary.pairFor(factory, path[0], path[1])
        );

        _swap(amounts, path, to);
    }

    function swapTokensForExactERC20(
        address erc20Contract,
        uint256 amountOut,
        uint256 amountInMax,
        uint256[] calldata path,
        address to,
        uint256 deadline
    ) external virtual ensure(deadline) returns (uint256[] memory amounts) {
        uint256 erc20Id = wrapper.erc20ToId(erc20Contract);
        require(
            path[path.length - 1] == erc20Id,
            "SpacePiratesRouter: INVALID_PATH"
        );
        amounts = SpacePiratesDexLibrary.getAmountsIn(factory, amountOut, path);
        require(
            amounts[0] <= amountInMax,
            "SpacePiratesRouter: EXCESSIVE_INPUT_AMOUNT"
        );
        IERC1155(tokenContract).safeTransferFrom(
            msg.sender,
            SpacePiratesDexLibrary.pairFor(factory, path[0], path[1]),
            path[0],
            amounts[0],
            ""
        );
        _swap(amounts, path, address(this));

        wrapper.erc20WithdrawTo(erc20Contract, amounts[amounts.length - 1], to);
    }

    function swapExactTokensForERC20(
        address erc20Contract,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256[] calldata path,
        address to,
        uint256 deadline
    ) external virtual ensure(deadline) returns (uint256[] memory amounts) {
        uint256 erc20Id = wrapper.erc20ToId(erc20Contract);
        require(
            path[path.length - 1] == erc20Id,
            "SpacePiratesRouter: INVALID_PATH"
        );
        amounts = SpacePiratesDexLibrary.getAmountsOut(factory, amountIn, path);
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "SpacePiratesRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        IERC1155(tokenContract).safeTransferFrom(
            msg.sender,
            SpacePiratesDexLibrary.pairFor(factory, path[0], path[1]),
            path[0],
            amounts[0],
            ""
        );
        _swap(amounts, path, address(this));

        wrapper.erc20WithdrawTo(erc20Contract, amounts[amounts.length - 1], to);
    }

    function swapERC20ForExactTokens(
        address erc20Contract,
        uint256 amountIn,
        uint256 amountOut,
        uint256[] calldata path,
        address to,
        uint256 deadline
    ) external virtual ensure(deadline) returns (uint256[] memory amounts) {
        uint256 erc20Id = wrapper.erc20ToId(erc20Contract);
        require(path[0] == erc20Id, "SpacePiratesRouter: INVALID_PATH");
        amounts = SpacePiratesDexLibrary.getAmountsIn(factory, amountOut, path);
        require(
            amounts[0] <= amountIn,
            "SpacePiratesRouter: EXCESSIVE_INPUT_AMOUNT"
        );
        wrapper.erc20DepositTo(
            erc20Contract,
            amounts[0],
            SpacePiratesDexLibrary.pairFor(factory, path[0], path[1])
        );
        _swap(amounts, path, to);
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) public pure virtual returns (uint256 amountB) {
        return SpacePiratesDexLibrary.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure virtual returns (uint256 amountOut) {
        return
            SpacePiratesDexLibrary.getAmountOut(
                amountIn,
                reserveIn,
                reserveOut
            );
    }

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure virtual returns (uint256 amountIn) {
        return
            SpacePiratesDexLibrary.getAmountIn(
                amountOut,
                reserveIn,
                reserveOut
            );
    }

    function getAmountsOut(uint256 amountIn, uint256[] memory path)
        public
        view
        virtual
        returns (uint256[] memory amounts)
    {
        return SpacePiratesDexLibrary.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint256 amountOut, uint256[] memory path)
        public
        view
        virtual
        returns (uint256[] memory amounts)
    {
        return SpacePiratesDexLibrary.getAmountsIn(factory, amountOut, path);
    }
}
