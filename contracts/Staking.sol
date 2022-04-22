// SPDX-License-Identifier: unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

//? changing to block.number instead of block.timestamp should be better

// TODO: set from the constructor the tokenIds of the stake and reward tokens

contract Staking is ERC1155Holder {
    // parent ERC1155 contract address
    IERC1155 public parentToken;

    // 100 tokens per second
    //TODO should modify reward rate into mapping in order to set the rate for each token
    //uint256 public rewardRate = 100;

    // mapping(uint256 => uint256) public lastUpdateTime;

    // mapping(uint256 => uint256) public rewardPerTokenStored;

    struct StakingToken {
        bool exist;
        uint256 totalSupply;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
    }

    struct RewardToken {
        bool exist;
        uint256 rewardRate;
    }

    mapping(uint256 => StakingToken) public stakingTokens;

    mapping(uint256 => RewardToken) public rewardTokens;

    // store rewards when user interact with smart contract: address => tokenId => reward
    mapping(address => mapping(uint256 => uint256))
        public userRewardPerTokenPaid;

    // address => tokenId => reward
    mapping(address => mapping(uint256 => uint256)) public rewards;

    // // tokenId => totalStakedToken
    // mapping(uint256 => uint256) private _totalSupply;

    // address => tokenId => userBalance
    mapping(address => mapping(uint256 => uint256)) public _balances;

    event Staked(address indexed user, uint256 amount, uint256 tokenId);
    event Withdrawn(address indexed user, uint256 amount, uint256 tokenId);
    event RewardPaid(address indexed user, uint256 reward);

    constructor(address tokens) {
        parentToken = IERC1155(tokens);
    }

    function totalSupply(uint256 _stakingTokenId)
        external
        view
        returns (uint256)
    {
        return stakingTokens[_stakingTokenId].totalSupply;
    }

    function balanceOf(address account, uint256 _stakingTokenId)
        external
        view
        returns (uint256)
    {
        return _balances[account][_stakingTokenId];
    }

    function getRewardForDuration(uint256 _duration, uint256 _stakingTokenId)
        external
        view
        returns (uint256)
    {
        return rewardTokens[_stakingTokenId].rewardRate * _duration;
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
            ((_balances[account][_stakingTokenId] *
                (rewardPerToken(_stakingTokenId, _rewardTokenId) -
                    userRewardPerTokenPaid[account][_stakingTokenId])) / 1e18) +
            rewards[account][_stakingTokenId];
    }

    modifier updateReward(
        address account,
        uint256 _stakingTokenId,
        uint256 _rewardTokenId
    ) {
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

    function stake(
        uint256 _stakingTokenId,
        uint256 _amount,
        uint256 _rewardTokenId
    ) external updateReward(msg.sender, _stakingTokenId, _rewardTokenId) {
        require(_amount > 0, "Cannot stake 0");
        stakingTokens[_stakingTokenId].totalSupply += _amount;
        _balances[msg.sender][_stakingTokenId] += _amount;
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
        _balances[msg.sender][_stakingTokenId] -= _amount;

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
