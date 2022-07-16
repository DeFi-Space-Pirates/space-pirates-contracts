// SPDX-License-Identifier: unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./SpacePiratesTokens.sol";

/**
 * @title Space Pirates Staking Contract
 * @author @yuripaoloni, @MatteoLeonesi, @Gr3it (reviewer)
 * @notice Create staking pool of the tokens added
 */

contract SpacePiratesStaking is ERC1155Holder, Ownable {
    // parent ERC1155 contract address
    SpacePiratesTokens public parentToken;

    address public feeAddress;

    struct StakingPool {
        bool exists;
        uint104 rewardTokenId;
        uint64 rewardRate; // token minted per second
        uint16 depositFee;
        uint64 lastUpdateTime; // last block timestamp stake, withdraw or getRewards were called
        uint256 totalSupply;
        uint256 accRewardPerShare; // sum of reward rate divided by the total supply of token staked at each time
    }

    struct UserInfo {
        uint256 rewardDebt;
        uint256 rewards;
        uint256 balances;
    }

    // mapping of staking pools: staking tokenId => struct
    mapping(uint256 => StakingPool) public stakingPools;

    // mapping of usersInfo: staking tokenId => address => userInfo
    mapping(uint256 => mapping(address => UserInfo)) public usersInfo;

    // pool info, keep track of created pool indexes
    uint256[] public poolIds;

    event Staked(address indexed user, uint256 indexed tokenId, uint256 amount);

    event Unstake(
        address indexed user,
        uint256 indexed tokenId,
        uint256 amount
    );

    event RewardPaid(
        address indexed user,
        uint256 indexed stakingTokenId,
        uint256 indexed rewardTokenId,
        uint256 reward
    );

    event StakingPoolCreated(
        uint256 indexed stakingTokenId,
        uint104 rewardTokenId,
        uint64 rewardRate,
        uint16 depositFee
    );

    event StakingPoolUpdated(
        uint256 indexed stakingTokenId,
        uint104 rewardTokenId,
        uint64 rewardRate,
        uint16 depositFee
    );

    event SetFeeAddress(address indexed user, address indexed newAddress);

    constructor(address tokens) {
        parentToken = SpacePiratesTokens(tokens);
    }

    function poolAmount() external view returns (uint256) {
        return poolIds.length;
    }

    function createStakingPool(
        uint256 _stakingTokenId,
        uint104 _rewardTokenId,
        uint64 _rewardRate,
        uint16 _depositFee
    ) public onlyOwner {
        require(
            _depositFee <= 10000,
            "SpacePiratesStaking: invalid deposit fee"
        );
        require(
            !stakingPools[_stakingTokenId].exists,
            "SpacePiratesStaking: staking pool already exists"
        );

        stakingPools[_stakingTokenId] = StakingPool(
            true,
            _rewardTokenId,
            _rewardRate,
            _depositFee,
            uint64(block.timestamp),
            0,
            0
        );

        poolIds.push(_stakingTokenId);

        emit StakingPoolCreated(
            _stakingTokenId,
            _rewardTokenId,
            _rewardRate,
            _depositFee
        );
    }

    function updateStakingPool(
        uint256 _stakingTokenId,
        uint104 _rewardTokenId,
        uint64 _rewardRate,
        uint16 _depositFee
    ) public onlyOwner {
        require(
            _depositFee <= 10000,
            "SpacePiratesStaking: invalid deposit fee"
        );
        require(
            stakingPools[_stakingTokenId].exists,
            "SpacePiratesStaking: staking pool does not exists"
        );

        stakingPools[_stakingTokenId].rewardTokenId = _rewardTokenId;
        stakingPools[_stakingTokenId].rewardRate = _rewardRate;
        stakingPools[_stakingTokenId].depositFee = _depositFee;

        emit StakingPoolUpdated(
            _stakingTokenId,
            _rewardTokenId,
            _rewardRate,
            _depositFee
        );
    }

    function pendingRewards(uint256 _stakingTokenId, address _user)
        external
        view
        returns (uint256)
    {
        StakingPool storage pool = stakingPools[_stakingTokenId];
        UserInfo storage user = usersInfo[_stakingTokenId][_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        if (block.timestamp > pool.lastUpdateTime && pool.totalSupply != 0) {
            accRewardPerShare += ((pool.rewardRate *
                (block.timestamp - pool.lastUpdateTime) *
                1e18) / pool.totalSupply);
        }
        return (((user.balances * (accRewardPerShare - user.rewardDebt)) /
            1e18) + user.rewards);
    }

    // Update reward variables of the given pool to be up-to-date. It is executed on stake, unstake, getRewards
    modifier updatePool(uint256 _stakingTokenId) {
        require(
            stakingPools[_stakingTokenId].exists,
            "SpacePiratesStaking: not existing token"
        );

        StakingPool storage pool = stakingPools[_stakingTokenId];
        uint64 timestamp = uint64(block.timestamp);

        if (timestamp > pool.lastUpdateTime) {
            if (pool.totalSupply == 0 || pool.rewardRate == 0) {
                pool.lastUpdateTime = timestamp;
            } else {
                pool.accRewardPerShare +=
                    (pool.rewardRate *
                        (timestamp - pool.lastUpdateTime) *
                        1e18) /
                    pool.totalSupply;
                pool.lastUpdateTime = timestamp;
            }
        }

        _;
    }

    // Update user rewards. It is executed on stake, unstake, getRewards
    modifier updateUserRewards(uint256 _stakingTokenId) {
        uint256 accRewardPerShare = stakingPools[_stakingTokenId]
            .accRewardPerShare;
        UserInfo storage user = usersInfo[_stakingTokenId][msg.sender];
        user.rewards +=
            (user.balances * (accRewardPerShare - user.rewardDebt)) /
            1e18;
        user.rewardDebt = accRewardPerShare;

        _;
    }

    function stake(uint256 _stakingTokenId, uint256 _amount)
        external
        updatePool(_stakingTokenId)
        updateUserRewards(_stakingTokenId)
    {
        require(_amount > 0, "SpacePiratesStaking: cannot stake 0");
        StakingPool storage pool = stakingPools[_stakingTokenId];
        UserInfo storage user = usersInfo[_stakingTokenId][msg.sender];

        parentToken.safeTransferFrom(
            msg.sender,
            address(this),
            _stakingTokenId,
            _amount,
            ""
        );

        if (pool.depositFee > 0 && feeAddress != address(0)) {
            uint256 depositFee = (_amount * pool.depositFee) / 10000;

            parentToken.safeTransferFrom(
                address(this),
                feeAddress,
                _stakingTokenId,
                depositFee,
                ""
            );
            pool.totalSupply += _amount - depositFee;
            user.balances += _amount - depositFee;
        } else {
            pool.totalSupply += _amount;
            user.balances += _amount;
        }

        emit Staked(msg.sender, _amount, _stakingTokenId);
    }

    function unstake(uint256 _stakingTokenId, uint256 _amount)
        external
        updatePool(_stakingTokenId)
        updateUserRewards(_stakingTokenId)
    {
        require(_amount > 0, "SpacePiratesStaking: cannot withdraw 0");
        StakingPool storage pool = stakingPools[_stakingTokenId];
        UserInfo storage user = usersInfo[_stakingTokenId][msg.sender];
        pool.totalSupply -= _amount;
        user.balances -= _amount;

        parentToken.safeTransferFrom(
            address(this),
            msg.sender,
            _stakingTokenId,
            _amount,
            ""
        );

        emit Unstake(msg.sender, _amount, _stakingTokenId);
    }

    function getReward(uint256 _stakingTokenId)
        external
        updatePool(_stakingTokenId)
        updateUserRewards(_stakingTokenId)
    {
        UserInfo storage user = usersInfo[_stakingTokenId][msg.sender];
        uint256 rewardTokenId = stakingPools[_stakingTokenId].rewardTokenId;
        uint256 rewards = user.rewards;
        user.rewards = 0;
        parentToken.mint(msg.sender, rewardTokenId, rewards);

        emit RewardPaid(msg.sender, _stakingTokenId, rewardTokenId, rewards);
    }

    function setFeeAddress(address _feeAddress) public onlyOwner {
        feeAddress = _feeAddress;
        emit SetFeeAddress(msg.sender, _feeAddress);
    }
}
