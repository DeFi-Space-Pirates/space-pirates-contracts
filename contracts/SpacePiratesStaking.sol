// SPDX-License-Identifier: unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./SpacePiratesTokens.sol";

/**
 * @title Space Pirates Staking Contract
 * @author @yuripaoloni, @MatteoLeonesi, @Gr3it
 * @notice Create staking pool of the tokens added
 */

contract SpacePiratesStaking is ERC1155Holder, Ownable {
    // parent ERC1155 contract address
    SpacePiratesTokens public parentToken;

    address public feeAddress;

    struct StakingPool {
        uint256 tokenId;
        uint256 rewardTokenId;
        uint120 rewardRate; // token minted per second
        uint120 lastUpdateTime; // last block timestamp stake, withdraw or getRewards were called
        uint16 depositFee;
        uint256 totalSupply;
        uint256 accRewardPerShare; // sum of reward rate divided by the total supply of token staked at each time
    }

    struct UserInfo {
        uint256 rewardDebt;
        uint256 reward;
        uint256 balance;
    }

    // array of staking pools
    StakingPool[] public stakingPools;

    // mapping of usersInfo: pid => address => userInfo
    mapping(uint256 => mapping(address => UserInfo)) public usersInfo;

    event Staked(address indexed user, uint256 indexed pid, uint256 amount);
    event Unstake(address indexed user, uint256 indexed pid, uint256 amount);
    event StakingPoolCreated(
        uint256 indexed pid,
        uint128 tokenId,
        uint128 rewardTokenId,
        uint120 rewardRate,
        uint16 depositFee
    );

    event StakingPoolUpdated(
        uint256 indexed pid,
        uint120 rewardRate,
        uint16 depositFee
    );

    event SetFeeAddress(address user, address newAddress);

    constructor(address tokens) {
        parentToken = SpacePiratesTokens(tokens);
    }

    function poolLength() external view returns (uint256) {
        return stakingPools.length;
    }

    function createStakingPool(
        uint128 _stakingTokenId,
        uint128 _rewardTokenId,
        uint120 _rewardRate,
        uint16 _depositFee
    ) public onlyOwner {
        require(
            _depositFee <= 10000,
            "SpacePiratesStaking: invalid deposit fee"
        );
        uint120 timestamp = uint120(block.timestamp);
        stakingPools.push(
            StakingPool({
                tokenId: _stakingTokenId,
                rewardTokenId: _rewardTokenId,
                rewardRate: _rewardRate,
                lastUpdateTime: timestamp,
                depositFee: _depositFee,
                totalSupply: 0,
                accRewardPerShare: 0
            })
        );

        emit StakingPoolCreated(
            stakingPools.length - 1,
            _stakingTokenId,
            _rewardTokenId,
            _rewardRate,
            _depositFee
        );
    }

    function updateStakingPool(
        uint128 _pid,
        uint120 _rewardRate,
        uint16 _depositFee
    ) public onlyOwner {
        require(
            _depositFee <= 10000,
            "SpacePiratesStaking: invalid deposit fee"
        );
        require(
            _pid < stakingPools.length,
            "SpacePiratesStaking: staking pool does not exists"
        );

        if (stakingPools[_pid].rewardRate != _rewardRate) {
            updatePool(_pid);
            stakingPools[_pid].rewardRate = _rewardRate;
        }

        stakingPools[_pid].depositFee = _depositFee;

        emit StakingPoolUpdated(_pid, _rewardRate, _depositFee);
    }

    function pendingRewards(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        require(
            _pid < stakingPools.length,
            "SpacePiratesStaking: staking pool does not exists"
        );
        StakingPool storage pool = stakingPools[_pid];
        UserInfo storage user = usersInfo[_pid][_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        if (block.timestamp > pool.lastUpdateTime && pool.totalSupply != 0) {
            accRewardPerShare += ((pool.rewardRate *
                (block.timestamp - pool.lastUpdateTime) *
                1e12) / pool.totalSupply);
        }
        return
            ((user.balance * accRewardPerShare) / 1e12) -
            user.rewardDebt +
            user.reward;
    }

    // Update reward variables of the given pool to be up-to-date. It is executed on stake, unstake, getRewards
    function updatePool(uint256 _pid) public {
        require(
            _pid < stakingPools.length,
            "SpacePiratesStaking: staking pool does not exists"
        );

        StakingPool storage pool = stakingPools[_pid];

        uint120 timestamp = uint120(block.timestamp);

        if (timestamp <= pool.lastUpdateTime) {
            return;
        }

        if (pool.totalSupply == 0 || pool.rewardRate == 0) {
            pool.lastUpdateTime = timestamp;
            return;
        }

        pool.accRewardPerShare +=
            (pool.rewardRate * (timestamp - pool.lastUpdateTime) * 1e12) /
            pool.totalSupply;
        pool.lastUpdateTime = timestamp;
    }

    function stake(uint256 _pid, uint256 _amount) external {
        require(_amount > 0, "SpacePiratesStaking: cannot stake 0");
        require(
            _pid < stakingPools.length,
            "SpacePiratesStaking: staking pool does not exists"
        );
        StakingPool storage pool = stakingPools[_pid];
        UserInfo storage user = usersInfo[_pid][msg.sender];

        parentToken.safeTransferFrom(
            msg.sender,
            address(this),
            pool.tokenId,
            _amount,
            ""
        );

        updatePool(_pid);
        if (user.balance > 0) {
            user.reward +=
                (user.balance * pool.accRewardPerShare) /
                1e12 -
                user.rewardDebt;
        }

        if (pool.depositFee > 0 && feeAddress != address(0)) {
            uint256 depositFee = (_amount * pool.depositFee) / 10000;

            parentToken.safeTransferFrom(
                address(this),
                feeAddress,
                pool.tokenId,
                depositFee,
                ""
            );
            pool.totalSupply += _amount - depositFee;
            user.balance += _amount - depositFee;
        } else {
            pool.totalSupply += _amount;
            user.balance += _amount;
        }

        user.rewardDebt = (user.balance * pool.accRewardPerShare) / 1e12;

        emit Staked(msg.sender, _amount, _pid);
    }

    function unstake(uint256 _pid, uint256 _amount) external {
        require(_amount > 0, "SpacePiratesStaking: cannot withdraw 0");
        require(
            _pid < stakingPools.length,
            "SpacePiratesStaking: staking pool does not exists"
        );
        StakingPool storage pool = stakingPools[_pid];
        UserInfo storage user = usersInfo[_pid][msg.sender];
        updatePool(_pid);

        user.reward +=
            (user.balance * pool.accRewardPerShare) /
            1e12 -
            user.rewardDebt;

        pool.totalSupply -= _amount;
        user.balance -= _amount;

        parentToken.safeTransferFrom(
            address(this),
            msg.sender,
            pool.tokenId,
            _amount,
            ""
        );

        user.rewardDebt = (user.balance * pool.accRewardPerShare) / 1e12;

        emit Unstake(msg.sender, _amount, _pid);
    }

    function getReward(uint256 _pid) external {
        StakingPool storage pool = stakingPools[_pid];
        UserInfo storage user = usersInfo[_pid][msg.sender];
        updatePool(_pid);

        uint256 pending = ((user.balance * pool.accRewardPerShare) / 1e12) -
            (user.rewardDebt) +
            user.reward;

        uint256 rewardTokenId = stakingPools[_pid].rewardTokenId;
        user.rewardDebt = (user.balance * pool.accRewardPerShare) / 1e12;
        user.reward = 0;

        parentToken.mint(msg.sender, rewardTokenId, pending);
    }

    function setFeeAddress(address _feeAddress) public onlyOwner {
        feeAddress = _feeAddress;
        emit SetFeeAddress(msg.sender, _feeAddress);
    }
}
