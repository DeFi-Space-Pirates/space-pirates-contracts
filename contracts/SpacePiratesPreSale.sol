// SPDX-License-Identifier: unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/SafeERC20.sol";
import "./libraries/Array.sol";
import "./SpacePiratesTokens.sol";

/**
 * @title Pre Sale Contract
 * @author @Gr3it, @yuripaoloni (reviewer), @MatteoLeonesi (reviewer)
 * @notice Create a pre sale of the tokens, raising liquidity for the dex
 */

contract SpacePiratesPreSale is Ownable {
    using SafeERC20 for IERC20;

    SpacePiratesTokens public immutable tokenContract;

    uint256 public constant DEPOSIT_PHASE_DURATION = 7 days;
    uint256 public constant CONVERT_PHASE_DURATION = 7 days;
    uint256 public constant CLAIM_PHASE_DURATION = 14 days;
    uint256 public constant PRECISION = 10e15;

    uint256 public constant DOUBLOONS = 1;
    uint256 public constant ASTEROIDS = 2;

    uint256 public immutable saleStart;
    address public immutable payedToken;
    uint256 public immutable doubloonsIssued;
    uint256 public immutable asteroidsIssued;

    uint256 public totalUsers = 0;
    uint256 public totalDeposited = 0;
    uint256 public totalTicket = 0;
    uint256 public totalNotConverted = 0;

    mapping(address => uint256) public balances;
    mapping(address => uint256) public ticket;

    event Deposit(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event ConvertToTicket(
        address indexed user,
        uint256 depositAmount,
        uint256 ticketAmount
    );
    event Claim(
        address indexed user,
        uint256 doubloonsAmount,
        uint256 asteroidsAmount,
        uint256 repaidAmount
    );
    event AdminWithdrawn(address indexed user, uint256 amount);

    constructor(
        uint256 _doubloonsIssued,
        uint256 _asteroidsIssued,
        uint256 _saleStart,
        address _payedToken,
        SpacePiratesTokens _tokenContract
    ) {
        doubloonsIssued = _doubloonsIssued;
        asteroidsIssued = _asteroidsIssued;
        saleStart = _saleStart;
        payedToken = _payedToken;
        tokenContract = _tokenContract;
    }

    function deposit(uint256 amount) external {
        require(amount != 0, "SpacePiratesPreSale: can not deposit 0 amount");
        require(
            block.timestamp >= saleStart,
            "SpacePiratesPreSale: pre sale deposit phase not started yet"
        );
        require(
            block.timestamp <= saleStart + DEPOSIT_PHASE_DURATION,
            "SpacePiratesPreSale: pre sale deposit phase ended"
        );
        if (balances[msg.sender] == 0) {
            ++totalUsers;
        }

        balances[msg.sender] += amount;
        totalDeposited += amount;
        emit Deposit(msg.sender, amount);
        IERC20(payedToken).safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdrawn(uint256 amount) external {
        require(amount != 0, "SpacePiratesPreSale: can not withdrawn 0 amount");
        require(
            block.timestamp >= saleStart,
            "SpacePiratesPreSale: pre sale deposit phase not started yet"
        );
        require(
            block.timestamp <= saleStart + DEPOSIT_PHASE_DURATION,
            "SpacePiratesPreSale: pre sale deposit phase ended"
        );
        if (balances[msg.sender] == amount) {
            --totalUsers;
        }

        balances[msg.sender] -= amount;
        totalDeposited -= amount;
        emit Withdrawn(msg.sender, amount);
        IERC20(payedToken).safeTransfer(msg.sender, amount);
    }

    function convertToTicket() external returns (uint256) {
        require(
            ticket[msg.sender] == 0,
            "SpacePiratesPreSale: deposit already converted to ticket"
        );
        require(
            block.timestamp >= saleStart + DEPOSIT_PHASE_DURATION,
            "SpacePiratesPreSale: pre sale convertion phase not started yet"
        );
        require(
            block.timestamp <=
                saleStart + DEPOSIT_PHASE_DURATION + CONVERT_PHASE_DURATION,
            "SpacePiratesPreSale: pre sale convertion phase ended"
        );

        uint256 userBalance = balances[msg.sender];
        require(userBalance != 0, "SpacePiratesPreSale: no token deposited");

        uint256 ticketAmount = ticketAmountOfUser(msg.sender);
        ticket[msg.sender] = ticketAmount;
        totalTicket += ticketAmount;
        emit ConvertToTicket(msg.sender, userBalance, ticketAmount);
        return ticketAmount;
    }

    function claimToken()
        external
        returns (
            uint256 doubloonsAmount,
            uint256 asteroidsAmount,
            uint256 repaidAmount
        )
    {
        require(
            block.timestamp >=
                saleStart + DEPOSIT_PHASE_DURATION + CONVERT_PHASE_DURATION,
            "SpacePiratesPreSale: pre sale claim phase not started yet"
        );
        require(
            block.timestamp <=
                saleStart +
                    DEPOSIT_PHASE_DURATION +
                    CONVERT_PHASE_DURATION +
                    CLAIM_PHASE_DURATION,
            "SpacePiratesPreSale: pre sale claim phase ended"
        );

        uint256 userBalance = balances[msg.sender];
        require(userBalance != 0, "SpacePiratesPreSale: no token deposited");
        balances[msg.sender] = 0;

        uint256 ticketAmount = ticket[msg.sender];
        if (ticketAmount == 0) {
            ticketAmount = ticketAmountOfUser(msg.sender);
            totalNotConverted += ticketAmount;
            doubloonsAmount = 0;
            asteroidsAmount = 0;
        } else {
            doubloonsAmount = (ticketAmount * doubloonsIssued) / totalTicket;
            asteroidsAmount = (ticketAmount * asteroidsAmount) / totalTicket;

            tokenContract.mintBatch(
                msg.sender,
                Array.getArrayPair(DOUBLOONS, ASTEROIDS),
                Array.getArrayPair(doubloonsAmount, asteroidsAmount)
            );
        }
        repaidAmount = userBalance - ticketAmount;
        emit Claim(msg.sender, doubloonsAmount, asteroidsAmount, repaidAmount);
        IERC20(payedToken).safeTransfer(msg.sender, repaidAmount);
    }

    function ticketAmountOfUser(address user) internal view returns (uint256) {
        uint256 userBalance = balances[user];
        uint256 depositPercentage = (userBalance * PRECISION) / totalDeposited;
        uint256 ticketAmount = (userBalance * PRECISION);

        if (depositPercentage >= threshold()) {
            return
                ticketAmount /
                (totalUsers * (depositPercentage - threshold()) + PRECISION);
        } else {
            return ticketAmount / PRECISION;
        }
    }

    function threshold() internal view returns (uint256) {
        return (PRECISION / 4) / totalUsers;
    }

    function tokenWithdrawn() external onlyOwner {
        require(
            block.timestamp >
                saleStart +
                    DEPOSIT_PHASE_DURATION +
                    CONVERT_PHASE_DURATION +
                    CLAIM_PHASE_DURATION,
            "SpacePiratesPreSale: pre sale not ended"
        );
        uint256 amount = IERC20(payedToken).balanceOf(address(this));
        emit AdminWithdrawn(msg.sender, amount);
        IERC20(payedToken).safeTransfer(msg.sender, amount);
    }
}
