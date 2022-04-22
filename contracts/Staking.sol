// SPDX-License-Identifier: unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Tokens.sol";

//? changing to block.number instead of block.timestamp should be better

contract Staking is ERC1155Holder, Ownable {
    // parent ERC1155 contract address
    Tokens public parentToken;

    struct StakingToken {
        bool exists;
        uint256 totalSupply;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
    }

    struct RewardToken {
        bool exists;
        uint256 rewardRate;
    }

    // mapping of staking tokens
    mapping(uint256 => StakingToken) public stakingTokens;

    // mapping of reward tokens
    mapping(uint256 => RewardToken) public rewardTokens;

    // store rewards when user interact with smart contract: address => tokenId => reward
    mapping(address => mapping(uint256 => uint256))
        public userRewardPerTokenPaid;

    // address => tokenId => reward
    mapping(address => mapping(uint256 => uint256)) public rewards;

    // address => tokenId => userBalance
    mapping(address => mapping(uint256 => uint256)) public balances;

    event Staked(address indexed user, uint256 amount, uint256 tokenId);
    event Withdrawn(address indexed user, uint256 amount, uint256 tokenId);
    event RewardPaid(address indexed user, uint256 reward);

    constructor(address tokens) {
        parentToken = Tokens(tokens);
    }

    modifier updateReward(
        address account,
        uint256 _stakingTokenId,
        uint256 _rewardTokenId
    ) {
        require(
            stakingTokens[_stakingTokenId].exists,
            "Input staking token not exists"
        );
        require(
            rewardTokens[_rewardTokenId].exists,
            "Input reward token not exists"
        );

        stakingTokens[_stakingTokenId].rewardPerTokenStored = rewardPerToken(
            _stakingTokenId,
            _rewardTokenId
        );
        stakingTokens[_stakingTokenId].lastUpdateTime = block.timestamp;
        rewards[msg.sender][_stakingTokenId] = earned(
            account,
            _stakingTokenId,
            _rewardTokenId
        );
        userRewardPerTokenPaid[account][_stakingTokenId] = stakingTokens[
            _stakingTokenId
        ].rewardPerTokenStored;
        _;
    }

    function getRewardForDuration(uint256 _duration, uint256 _rewardTokenId)
        external
        view
        returns (uint256)
    {
        return rewardTokens[_rewardTokenId].rewardRate * _duration;
    }

    function rewardPerToken(uint256 _stakingTokenId, uint256 _rewardTokenId)
        public
        view
        returns (uint256)
    {
        if (stakingTokens[_stakingTokenId].totalSupply == 0) {
            return stakingTokens[_stakingTokenId].rewardPerTokenStored;
        }
        return
            stakingTokens[_stakingTokenId].rewardPerTokenStored +
            (((block.timestamp -
                stakingTokens[_stakingTokenId].lastUpdateTime) *
                rewardTokens[_rewardTokenId].rewardRate *
                1e18) / stakingTokens[_stakingTokenId].totalSupply);
    }

    // how much tokens the user earned so far
    function earned(
        address account,
        uint256 _stakingTokenId,
        uint256 _rewardTokenId
    ) public view returns (uint256) {
        return
            ((balances[account][_stakingTokenId] *
                (rewardPerToken(_stakingTokenId, _rewardTokenId) -
                    userRewardPerTokenPaid[account][_stakingTokenId])) / 1e18) +
            rewards[account][_stakingTokenId];
    }

    function setStakingTokens(uint256 _stakingTokenId, bool _exists)
        public
        onlyOwner
    {
        stakingTokens[_stakingTokenId].exists = _exists;
    }

    function setRewardTokens(
        uint256 _rewardTokenId,
        bool _exists,
        uint256 _rewardRate
    ) public onlyOwner {
        rewardTokens[_rewardTokenId].exists = _exists;
        rewardTokens[_rewardTokenId].rewardRate = _rewardRate;
    }

    function stake(
        uint256 _stakingTokenId,
        uint256 _amount,
        uint256 _rewardTokenId
    ) external updateReward(msg.sender, _stakingTokenId, _rewardTokenId) {
        require(_amount > 0, "Cannot stake 0");
        stakingTokens[_stakingTokenId].totalSupply += _amount;
        balances[msg.sender][_stakingTokenId] += _amount;
        parentToken.safeTransferFrom(
            msg.sender,
            address(this),
            _stakingTokenId,
            _amount,
            ""
        );

        emit Staked(msg.sender, _amount, _stakingTokenId);
    }

    function withdraw(
        uint256 _stakingTokenId,
        uint256 _amount,
        uint256 _rewardTokenId
    ) external updateReward(msg.sender, _stakingTokenId, _rewardTokenId) {
        require(_amount > 0, "Cannot withdraw 0");
        stakingTokens[_stakingTokenId].totalSupply -= _amount;
        balances[msg.sender][_stakingTokenId] -= _amount;

        parentToken.safeTransferFrom(
            address(this),
            msg.sender,
            _stakingTokenId,
            _amount,
            ""
        );

        emit Withdrawn(msg.sender, _amount, _stakingTokenId);
    }

    function getReward(uint256 _stakingTokenId, uint256 _rewardTokenId)
        external
        updateReward(msg.sender, _stakingTokenId, _rewardTokenId)
    {
        uint256 reward = rewards[msg.sender][_stakingTokenId];
        parentToken.mint(msg.sender, _rewardTokenId, reward, "");
        rewards[msg.sender][_stakingTokenId] = 0;
        parentToken.safeTransferFrom(
            address(this),
            msg.sender,
            _stakingTokenId,
            reward,
            ""
        );
        emit RewardPaid(msg.sender, reward);
    }
}
