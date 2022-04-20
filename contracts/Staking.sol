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
    uint256 public rewardRate = 100;

    mapping(uint256 => uint256) public lastUpdateTime;

    mapping(uint256 => uint256) public rewardPerTokenStored;

    // store rewards when user interact with smart contract: address => tokenId => reward
    mapping(address => mapping(uint256 => uint256))
        public userRewardPerTokenPaid;

    // address => tokenId => reward
    mapping(address => mapping(uint256 => uint256)) public rewards;

    // tokenId => totalStakedToken
    mapping(uint256 => uint256) private _totalSupply;

    // address => tokenId => userBalance
    mapping(address => mapping(uint256 => uint256)) public _balances;

    event Staked(address indexed user, uint256 amount, uint256 tokenId);
    event Withdrawn(address indexed user, uint256 amount, uint256 tokenId);
    event RewardPaid(address indexed user, uint256 reward);

    constructor(address tokens) {
        parentToken = IERC1155(tokens);
    }

    function totalSupply(uint256 _tokenId) external view returns (uint256) {
        return _totalSupply[_tokenId];
    }

    function balanceOf(address account, uint256 _tokenId)
        external
        view
        returns (uint256)
    {
        return _balances[account][_tokenId];
    }

    function getRewardForDuration(uint256 _duration)
        external
        view
        returns (uint256)
    {
        return rewardRate * _duration;
    }

    function rewardPerToken(uint256 _tokenId) public view returns (uint256) {
        if (_totalSupply[_tokenId] == 0) {
            return rewardPerTokenStored[_tokenId];
        }
        return
            rewardPerTokenStored[_tokenId] +
            (((block.timestamp - lastUpdateTime[_tokenId]) *
                rewardRate *
                1e18) / _totalSupply[_tokenId]);
    }

    // how much tokens the user earned so far
    function earned(address account, uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        return
            ((_balances[account][_tokenId] *
                (rewardPerToken(_tokenId) -
                    userRewardPerTokenPaid[account][_tokenId])) / 1e18) +
            rewards[account][_tokenId];
    }

    modifier updateReward(address account, uint256 _tokenId) {
        rewardPerTokenStored[_tokenId] = rewardPerToken(_tokenId);
        lastUpdateTime[_tokenId] = block.timestamp;
        rewards[msg.sender][_tokenId] = earned(account, _tokenId);
        userRewardPerTokenPaid[account][_tokenId] = rewardPerTokenStored[
            _tokenId
        ];
        _;
    }

    function stake(uint256 _tokenId, uint256 _amount)
        external
        updateReward(msg.sender, _tokenId)
    {
        require(_amount > 0, "Cannot stake 0");
        _totalSupply[_tokenId] += _amount;
        _balances[msg.sender][_tokenId] += _amount;
        parentToken.safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId,
            _amount,
            ""
        );

        emit Staked(msg.sender, _amount, _tokenId);
    }

    function withdraw(uint256 _tokenId, uint256 _amount)
        external
        updateReward(msg.sender, _tokenId)
    {
        require(_amount > 0, "Cannot withdraw 0");
        _totalSupply[_tokenId] -= _amount;
        _balances[msg.sender][_tokenId] -= _amount;

        parentToken.safeTransferFrom(
            address(this),
            msg.sender,
            _tokenId,
            _amount,
            ""
        );

        emit Withdrawn(msg.sender, _amount, _tokenId);
    }

    function getReward(uint256 _tokenId)
        external
        updateReward(msg.sender, _tokenId)
    {
        uint256 reward = rewards[msg.sender][_tokenId];
        rewards[msg.sender][_tokenId] = 0;
        parentToken.safeTransferFrom(
            address(this),
            msg.sender,
            _tokenId,
            reward,
            ""
        );
        emit RewardPaid(msg.sender, reward);
    }
}
