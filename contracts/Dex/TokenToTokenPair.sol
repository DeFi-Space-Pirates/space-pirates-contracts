// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../libraries/Math.sol";
import "../libraries/Array.sol";
import "./LPToken.sol";

contract EthToTokenPair is ERC1155Holder, LPToken, Ownable {
    uint256 public constant MINIMUM_LIQUIDITY = 10**3;

    address public factory;
    IERC1155 public immutable token;
    uint256 public immutable token0Id;
    uint256 public immutable token1Id;
    uint256 public fee = 997; //on fee/1000 basis

    event TokenToTokenSwap(
        address swapperAddress,
        uint256 ethAmount,
        uint256 tokenAmount
    );

    event LiquidityProvided(
        address provider,
        uint256 LPToken,
        uint256 ethAmount,
        uint256 tokenAmount
    );

    event LiquidityRemoved(
        address provider,
        uint256 LPToken,
        uint256 ethAmount,
        uint256 tokenAmount
    );

    constructor(
        address token_addr,
        uint256 _token0Id,
        uint256 _token1Id,
        string memory name0,
        string memory name1
    ) LPToken(string(abi.encodePacked(name0, "-", name1, " LPToken")), "LP") {
        token = IERC1155(token_addr);
        token0Id = _token0Id;
        token1Id = _token1Id;
    }

    function init(uint256 token0Amount, uint256 token1Amount)
        public
        payable
        returns (uint256)
    {
        require(token0Amount > 0, "cannot init with 0 Token");
        require(token1Amount > 0, "cannot init with 0 Token");
        require(totalSupply == 0, "Contract has already liquidity");

        uint256 liquidity = Math.sqrt(token0Amount * token1Amount) -
            MINIMUM_LIQUIDITY;

        require(liquidity > 0, "Insufficend liquidity minted");

        token.safeBatchTransferFrom(
            msg.sender,
            address(this),
            Array.getArray(token0Id, token1Id),
            Array.getArray(token0Amount, token1Amount),
            ""
        );

        _mint(msg.sender, liquidity);

        emit LiquidityProvided(
            msg.sender,
            liquidity,
            token0Amount,
            token1Amount
        );
        return liquidity;
    }

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "Insufficent found");
        require(reserveA > 0 && reserveB > 0, "insufficent liquidity");
        amountB = (amountA * reserveB) / reserveA;
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) public view returns (uint256 amountOut) {
        require(amountIn > 0, "Insufficent found");
        require(reserveIn > 0 && reserveOut > 0, "insufficent liquidity");
        uint256 amountInWithFee = amountIn * fee;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) public view returns (uint256 amountIn) {
        require(amountOut > 0, "Insufficent found");
        require(reserveIn > 0 && reserveOut > 0, "insufficent liquidity");
        uint256 numerator = reserveIn * amountOut * 1000;
        uint256 denominator = (reserveOut - amountOut) * fee;
        amountIn = (numerator / denominator) + 1;
    }

    function TokenSwap(uint256 inputAmount, uint256 outputTokenId)
        public
        payable
        returns (uint256 tokenOutput)
    {
        require(
            outputTokenId == token0Id || outputTokenId == token1Id,
            "output token ivalid id"
        );
        uint256 inputTokenId = outputTokenId == token0Id ? token1Id : token0Id;

        uint256 inputTokenBalance = token.balanceOf(
            address(this),
            inputTokenId
        );
        uint256 outputTokenBalance = token.balanceOf(
            address(this),
            tokenOutput
        );

        uint256 amount = getAmountOut(
            inputAmount,
            inputTokenBalance,
            outputTokenBalance
        );
        token.safeTransferFrom(
            msg.sender,
            address(this),
            inputTokenId,
            inputAmount,
            ""
        );
        token.safeTransferFrom(
            address(this),
            msg.sender,
            outputTokenId,
            amount,
            ""
        );
        emit TokenToTokenSwap(msg.sender, inputAmount, amount);
        return amount;
    }

    function deposit(uint256 token0Amount, uint256 token1Amount)
        public
        payable
        returns (uint256)
    {
        require(token0Amount > 0, "0 eth value");
        require(token1Amount > 0, "0 token");

        uint256 token0Balance = token.balanceOf(address(this), token0Id);
        uint256 token1Balance = token.balanceOf(address(this), token1Id);

        uint256 liquidity = Math.min(
            (token0Amount * totalSupply) / token0Balance,
            (token1Amount * totalSupply) / token1Balance
        );

        require(liquidity > 0, "0 liquidity");

        token.safeBatchTransferFrom(
            msg.sender,
            address(this),
            Array.getArray(token0Id, token1Id),
            Array.getArray(token0Amount, token1Amount),
            ""
        );

        _mint(msg.sender, liquidity);

        emit LiquidityProvided(
            msg.sender,
            liquidity,
            token0Amount,
            token1Amount
        );
        return liquidity;
    }

    function withdraw(uint256 amount) public returns (uint256, uint256) {
        uint256 token0Balance = token.balanceOf(address(this), token0Id);
        uint256 token1Balance = token.balanceOf(address(this), token1Id);

        uint256 token0Amount = (amount * token0Balance) / totalSupply;
        uint256 token1Amount = (amount * token1Balance) / totalSupply;

        require(
            token0Amount > 0 && token1Amount > 0,
            "insufficent liquidity burned"
        );

        _burn(msg.sender, amount);

        token.safeBatchTransferFrom(
            address(this),
            msg.sender,
            Array.getArray(token0Id, token1Id),
            Array.getArray(token0Amount, token1Amount),
            ""
        );

        emit LiquidityRemoved(msg.sender, amount, token0Amount, token1Amount);
        return (token0Amount, token1Amount);
    }

    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }
}
