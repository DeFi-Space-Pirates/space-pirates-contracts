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

    struct StakingPair {
        bool exists;
        uint256 rewardToken;
        uint256 rewardRate;
        uint256 depositFee;
        uint256 totalSupply;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
    }

    // mapping of staking pairs: staking token => struct
    mapping(uint256 => StakingPair) public stakingPairs;

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
    event StakingPairCreated(
        uint256 stakingTokenId,
        bool exists,
        uint256 rewardRate,
        uint256 depositFee
    );
    event StakingPairUpdated(
        uint256 stakingTokenId,
        bool exists,
        uint256 rewardRate,
        uint256 depositFee
    );

    constructor(address tokens) {
        parentToken = Tokens(tokens);
    }

    modifier updateReward(address account, uint256 _stakingTokenId) {
        require(
            stakingPairs[_stakingTokenId].exists,
            "Input staking token not exists"
        );

        stakingPairs[_stakingTokenId].rewardPerTokenStored = rewardPerToken(
            _stakingTokenId
        );
        stakingPairs[_stakingTokenId].lastUpdateTime = block.timestamp;
        rewards[msg.sender][_stakingTokenId] = earned(account, _stakingTokenId);
        userRewardPerTokenPaid[account][_stakingTokenId] = stakingPairs[
            _stakingTokenId
        ].rewardPerTokenStored;
        _;
    }

    function getRewardForDuration(uint256 _duration, uint256 _stakingTokenId)
        external
        view
        returns (uint256)
    {
        return stakingPairs[_stakingTokenId].rewardRate * _duration;
    }

    function rewardPerToken(uint256 _stakingTokenId)
        public
        view
        returns (uint256)
    {
        if (stakingPairs[_stakingTokenId].totalSupply == 0) {
            return stakingPairs[_stakingTokenId].rewardPerTokenStored;
        }
        return
            stakingPairs[_stakingTokenId].rewardPerTokenStored +
            (((block.timestamp - stakingPairs[_stakingTokenId].lastUpdateTime) *
                stakingPairs[_stakingTokenId].rewardRate *
                1e18) / stakingPairs[_stakingTokenId].totalSupply);
    }

    // how much tokens the user earned so far
    function earned(address account, uint256 _stakingTokenId)
        public
        view
        returns (uint256)
    {
        return
            ((balances[account][_stakingTokenId] *
                (rewardPerToken(_stakingTokenId) -
                    userRewardPerTokenPaid[account][_stakingTokenId])) / 1e18) +
            rewards[account][_stakingTokenId];
    }

    function createStakingPair(
        uint256 _stakingTokenId,
        bool _exists,
        uint256 _rewardRate,
        uint256 _depositFee
    ) public onlyOwner {
        require(_depositFee <= 10000, "Invalid deposit fee basis points");

        stakingPairs[_stakingTokenId] = StakingPair(
            _exists,
            parentToken.DOUBLOONS(),
            _rewardRate,
            _depositFee,
            0,
            0,
            0
        );

        emit StakingPairCreated(
            _stakingTokenId,
            _exists,
            _rewardRate,
            _depositFee
        );
    }

    function updateStakingPair(
        uint256 _stakingTokenId,
        bool _exists,
        uint256 _rewardRate,
        uint256 _depositFee
    ) public onlyOwner {
        require(_depositFee <= 10000, "Invalid deposit fee basis points");

        stakingPairs[_stakingTokenId].exists = _exists;
        stakingPairs[_stakingTokenId].rewardRate = _rewardRate;
        stakingPairs[_stakingTokenId].depositFee = _depositFee;

        emit StakingPairUpdated(
            _stakingTokenId,
            _exists,
            _rewardRate,
            _depositFee
        );
    }

    function stake(uint256 _stakingTokenId, uint256 _amount)
        external
        updateReward(msg.sender, _stakingTokenId)
    {
        require(_amount > 0, "Cannot stake 0");

        parentToken.safeTransferFrom(
            msg.sender,
            address(this),
            _stakingTokenId,
            _amount,
            ""
        );

        if (stakingPairs[_stakingTokenId].depositFee > 0) {
            uint256 depositFee = (_amount *
                stakingPairs[_stakingTokenId].depositFee) / 10000;

            parentToken.safeTransferFrom(
                address(this),
                owner(),
                _stakingTokenId,
                depositFee,
                ""
            );
            stakingPairs[_stakingTokenId].totalSupply += _amount - depositFee;
            balances[msg.sender][_stakingTokenId] += _amount - depositFee;
        } else {
            stakingPairs[_stakingTokenId].totalSupply += _amount;
            balances[msg.sender][_stakingTokenId] += _amount;
        }

        emit Staked(msg.sender, _amount, _stakingTokenId);
    }

    function withdraw(uint256 _stakingTokenId, uint256 _amount)
        external
        updateReward(msg.sender, _stakingTokenId)
    {
        require(_amount > 0, "Cannot withdraw 0");
        stakingPairs[_stakingTokenId].totalSupply -= _amount;
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

    function getReward(uint256 _stakingTokenId)
        external
        updateReward(msg.sender, _stakingTokenId)
    {
        uint256 reward = rewards[msg.sender][_stakingTokenId];
        parentToken.mintDoubloons(msg.sender, reward);
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
