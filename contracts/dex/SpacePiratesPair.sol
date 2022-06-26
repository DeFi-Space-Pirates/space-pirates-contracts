// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./SpacePiratesLPToken.sol";
import "./ERC1155Batch.sol";
import "../libraries/UQ112x112.sol";
import "../libraries/Math.sol";
import "../interfaces/ISpacePiratesFactory.sol";
import "../interfaces/ISpacePiratesCallee.sol";

/**
 * @title Space Pirates Pair Contract
 * @author @Gr3it, @yuripaoloni (reviewer), @MatteoLeonesi (reviewer)
 * @notice Let swap token if added liquidity
 */


contract SpacePiratesPair is SpacePiratesLPToken, ERC1155Batch, ERC1155Holder {
    using UQ112x112 for uint224;

    uint256 public constant MINIMUM_LIQUIDITY = 10**3;

    address public immutable factory;
    uint128 private token0; // uses single storage slot, accessible via getTokenIds
    uint128 private token1; // uses single storage slot, accessible via getTokenIds

    uint112 private reserve0; // uses single storage slot, accessible via getReserves
    uint112 private reserve1; // uses single storage slot, accessible via getReserves
    uint32 private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    uint256 public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    uint256 private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, "SpacePiratesPair: LOCKED");

        unlocked = 0;
        _;
        unlocked = 1;
    }

    function getReserves()
        public
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        )
    {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function getTokenIds()
        public
        view
        returns (uint128 _token0, uint128 _token1)
    {
        _token0 = token0;
        _token1 = token1;
    }

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    constructor() {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(
        uint128 _token0,
        uint128 _token1,
        address _tokenContract
    ) external {
        require(msg.sender == factory, "SpacePiratesPair: FORBIDDEN"); // sufficient check
        _batchInit(_tokenContract);
        token0 = _token0;
        token1 = _token1;
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(
        uint256 balance0,
        uint256 balance1,
        uint112 _reserve0,
        uint112 _reserve1
    ) private {
        require(
            balance0 <= type(uint112).max && balance1 <= type(uint112).max,
            "SpacePiratesPair: OVERFLOW"
        );
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed;
        unchecked {
            timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        }
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            unchecked {
                price0CumulativeLast +=
                    uint256(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) *
                    timeElapsed;
                price1CumulativeLast +=
                    uint256(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) *
                    timeElapsed;
            }
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    function _mintFee(uint112 _reserve0, uint112 _reserve1)
        private
        returns (bool feeOn)
    {
        address feeTo = ISpacePiratesFactory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint256 _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint256 rootK = Math.sqrt(uint256(_reserve0) * _reserve1);
                uint256 rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint256 numerator = totalSupply * (rootK - rootKLast);
                    uint256 denominator = rootK * 5 + rootKLast;
                    uint256 liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external lock returns (uint256 liquidity) {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        (uint256 balance0, uint256 balance1) = balanceOfBatchPair(
            address(this),
            token0,
            token1
        );

        uint256 amount0 = balance0 - _reserve0;
        uint256 amount1 = balance1 - _reserve1;

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(
                (amount0 * _totalSupply) / _reserve0,
                (amount1 * _totalSupply) / _reserve1
            );
        }
        require(
            liquidity > 0,
            "SpacePiratesPair: INSUFFICIENT_LIQUIDITY_MINTED"
        );
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint256(reserve0) * reserve1; // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to)
        external
        lock
        returns (uint256 amount0, uint256 amount1)
    {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        (uint128 _token0, uint128 _token1) = getTokenIds(); // gas savings
        (uint256 balance0, uint256 balance1) = balanceOfBatchPair(
            address(this),
            _token0,
            _token1
        );
        uint256 liquidity = balanceOf[address(this)];

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = (liquidity * balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = (liquidity * balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(
            amount0 > 0 && amount1 > 0,
            "SpacePiratesPair: INSUFFICIENT_LIQUIDITY_BURNED"
        );
        _burn(address(this), liquidity);

        safeBatchTransferFromPair(
            address(this),
            to,
            _token0,
            _token1,
            amount0,
            amount1
        );

        (balance0, balance1) = balanceOfBatchPair(
            address(this),
            _token0,
            _token1
        );

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint256(reserve0) * reserve1; // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external lock {
        require(
            amount0Out > 0 || amount1Out > 0,
            "SpacePiratesPair: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        require(
            amount0Out < _reserve0 && amount1Out < _reserve1,
            "SpacePiratesPair: INSUFFICIENT_LIQUIDITY"
        );

        uint256 balance0;
        uint256 balance1;
        {
            // scope for _token{0,1}, avoids stack too deep errors
            (uint128 _token0, uint128 _token1) = getTokenIds(); // gas savings
            if (amount0Out > 0)
                IERC1155(tokenContract).safeTransferFrom(
                    address(this),
                    to,
                    _token0,
                    amount0Out,
                    ""
                ); // optimistically transfer tokens
            if (amount1Out > 0)
                IERC1155(tokenContract).safeTransferFrom(
                    address(this),
                    to,
                    _token1,
                    amount1Out,
                    ""
                ); // optimistically transfer tokens
            if (data.length > 0)
                ISpacePiratesCallee(to).spacePiratesCall(
                    msg.sender,
                    amount0Out,
                    amount1Out,
                    data
                );
            (balance0, balance1) = balanceOfBatchPair(
                address(this),
                _token0,
                _token1
            );
        }
        uint256 amount0In = balance0 > _reserve0 - amount0Out
            ? balance0 - (_reserve0 - amount0Out)
            : 0;
        uint256 amount1In = balance1 > _reserve1 - amount1Out
            ? balance1 - (_reserve1 - amount1Out)
            : 0;
        require(
            amount0In > 0 || amount1In > 0,
            "SpacePiratesPair: INSUFFICIENT_INPUT_AMOUNT"
        );
        {
            // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            uint256 balance0Adjusted = balance0 * 1000 - (amount0In * 3);
            uint256 balance1Adjusted = balance1 * 1000 - (amount1In * 3);
            require(
                balance0Adjusted * balance1Adjusted >=
                    uint256(_reserve0) * _reserve1 * (1000**2),
                "SpacePiratesPair: K"
            );
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // force balances to match reserves
    function skim(address to) external lock {
        uint128 _token0 = token0; // gas savings
        uint128 _token1 = token1; // gas savings

        (uint256 balance0, uint256 balance1) = balanceOfBatchPair(
            address(this),
            _token0,
            _token1
        );

        safeBatchTransferFromPair(
            address(this),
            to,
            _token0,
            _token1,
            balance0 - reserve0,
            balance1 - reserve1
        );
    }

    // force reserves to match balances
    function sync() external lock {
        (uint256 balance0, uint256 balance1) = balanceOfBatchPair(
            address(this),
            token0,
            token1
        );
        _update(balance0, balance1, reserve0, reserve1);
    }
}
