// SPDX-License-Identifier: unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/SafeERC20.sol";
import "./SpacePiratesTokens.sol";

/**
    @title Wrapper contract for ERC20 and native tokens
    @author @yuripaoloni, @MatteoLeonesi, @Gr3it (reviewer)
    @notice Wrap ERC20 and native tokens in order to use them in the ERC1155 contract
 */
contract SpacePiratesWrapper is Ownable {
    using SafeERC20 for IERC20;

    SpacePiratesTokens public immutable tokenContract;

    uint256 public constant spaceETH = 100;

    uint256 public lastId = 100;
    address[] public supportedTokens;
    mapping(address => uint256) public erc20ToId;

    address public feeAddress;
    uint256 public feeBasePoint;

    event ERC20Added(address indexed _erc20contract, uint256 id);
    event ERC20Deposited(
        address indexed user,
        address indexed _erc20contract,
        uint256 id,
        uint256 amount
    );
    event ERC20Withdrawn(
        address indexed user,
        address indexed _erc20contract,
        uint256 id,
        uint256 amount
    );
    event ETHDeposited(address indexed user, uint256 id, uint256 amount);
    event ETHWithdrawn(address indexed user, uint256 id, uint256 amount);
    event SetFeeAddress(address indexed sender, address indexed feeAddress);

    constructor(SpacePiratesTokens _tokenContract) {
        tokenContract = _tokenContract;
    }

    function addERC20(address _erc20Contract)
        external
        onlyOwner
        returns (uint256 id)
    {
        require(
            erc20ToId[_erc20Contract] == 0,
            "SpacePiratesWrapper: TOKEN ALREADY EXISTS"
        );

        erc20ToId[_erc20Contract] = ++lastId;
        supportedTokens.push(_erc20Contract);

        id = erc20ToId[_erc20Contract];

        emit ERC20Added(_erc20Contract, id);
    }

    function erc20Deposit(address _addr, uint256 _amount) external {
        require(
            erc20ToId[_addr] != 0,
            "SpacePiratesWrapper: TOKEN DOES NOT EXISTS"
        );

        IERC20(_addr).safeTransferFrom(msg.sender, address(this), _amount);

        tokenContract.mint(msg.sender, _amount, erc20ToId[_addr]);

        emit ERC20Deposited(msg.sender, _addr, erc20ToId[_addr], _amount);
    }

    function erc20DepositTo(
        address _addr,
        uint256 _amount,
        address _to
    ) external {
        require(
            erc20ToId[_addr] != 0,
            "SpacePiratesWrapper: TOKEN DOES NOT EXISTS"
        );

        IERC20(_addr).safeTransferFrom(_to, address(this), _amount);

        tokenContract.mint(_to, _amount, erc20ToId[_addr]);

        emit ERC20Deposited(_to, _addr, erc20ToId[_addr], _amount);
    }

    function erc20Withdraw(address _addr, uint256 _amount) external {
        require(
            erc20ToId[_addr] != 0,
            "SpacePiratesWrapper: TOKEN DOES NOT EXISTS"
        );

        if (feeBasePoint > 0) {
            uint256 depositFee = (_amount * feeBasePoint) / 10000;
            IERC20(_addr).safeTransfer(feeAddress, depositFee);
            IERC20(_addr).safeTransfer(msg.sender, _amount - depositFee);
        } else {
            IERC20(_addr).safeTransfer(msg.sender, _amount);
        }

        tokenContract.burn(msg.sender, _amount, erc20ToId[_addr]);

        emit ERC20Withdrawn(msg.sender, _addr, erc20ToId[_addr], _amount);
    }

    function erc20WithdrawTo(
        address _addr,
        uint256 _amount,
        address _to
    ) external {
        require(
            erc20ToId[_addr] != 0,
            "SpacePiratesWrapper: TOKEN DOES NOT EXISTS"
        );

        if (feeBasePoint > 0) {
            uint256 depositFee = (_amount * feeBasePoint) / 10000;
            IERC20(_addr).safeTransfer(feeAddress, depositFee);
            IERC20(_addr).safeTransfer(_to, _amount - depositFee);
        } else {
            IERC20(_addr).safeTransfer(_to, _amount);
        }

        tokenContract.burn(_to, _amount, erc20ToId[_addr]);

        emit ERC20Withdrawn(_to, _addr, erc20ToId[_addr], _amount);
    }

    receive() external payable {
        tokenContract.mint(msg.sender, msg.value, spaceETH);

        emit ETHDeposited(msg.sender, spaceETH, msg.value);
    }

    function ethDepositTo(address _to) external payable {
        tokenContract.mint(_to, msg.value, spaceETH);

        emit ETHDeposited(_to, spaceETH, msg.value);
    }

    function ethWithdraw(uint256 _amount) external {
        tokenContract.burn(msg.sender, _amount, spaceETH);

        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "SpacePiratesWrapper: WITHDRAW FAILED");

        emit ETHWithdrawn(msg.sender, spaceETH, _amount);
    }

    function ethWithdrawTo(uint256 _amount, address _to) external {
        tokenContract.burn(_to, _amount, spaceETH);

        (bool success, ) = address(_to).call{value: _amount}("");
        require(success, "SpacePiratesWrapper: WITHDRAW FAILED");

        emit ETHWithdrawn(_to, spaceETH, _amount);
    }

    function setFeeBasePoint(uint256 _feeBasePoint) external onlyOwner {
        require(
            _feeBasePoint <= 10000,
            "SpacePiratesWrapper: invalid deposit fee basis points"
        );

        feeBasePoint = _feeBasePoint;
    }

    function setFeeAddress(address _feeAddress) external onlyOwner {
        require(msg.sender == feeAddress, "SpacePiratesWrapper: FORBIDDEN");

        feeAddress = _feeAddress;
        emit SetFeeAddress(msg.sender, _feeAddress);
    }
}
