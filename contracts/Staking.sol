// SPDX-License-Identifier: unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Tokens.sol";

contract Staking is ERC1155Holder, Ownable {
    // parent ERC1155 contract address
    Tokens public parentToken;

    struct StakingPair {
        bool exists;
        uint256 rewardTokenId;
        uint256 rewardRate; // token minted per second
        uint256 depositFee;
        uint256 totalSupply;
        uint256 lastUpdateTime; // last time stake, withdraw or getRewards were called
        uint256 rewardPerTokenStored; // sum of reward rate divider by the total supply of token staked at each time
    }

    // mapping of staking pairs: staking token => struct
    mapping(uint256 => StakingPair) public stakingPairs;

    // rewards per token stored when user interacts with smart contract: address => tokenId => reward
    mapping(address => mapping(uint256 => uint256))
        public userRewardPerTokenPaid;

    // rewards of the user, updated when stake or withdraw. address => tokenId => reward
    mapping(address => mapping(uint256 => uint256)) public rewards;

    // number of token staked per user and tokenId. address => tokenId => userBalance
    mapping(address => mapping(uint256 => uint256)) public balances;

    event Staked(address indexed user, uint256 amount, uint256 tokenId);
    event Withdrawn(address indexed user, uint256 amount, uint256 tokenId);

    event RewardPaid(
        address indexed user,
        uint256 stakingTokenId,
        uint256 rewardTokenId,
        uint256 reward
    );
    event StakingPairCreated(
        uint256 stakingTokenId,
        uint256 rewardTokenId,
        uint256 rewardRate,
        uint256 depositFee
    );
    event StakingPairUpdated(
        uint256 stakingTokenId,
        uint256 rewardTokenId,
        bool exists,
        uint256 rewardRate,
        uint256 depositFee
    );

    constructor(address tokens) {
        parentToken = Tokens(tokens);
    }

    // recompute the rewards. It is executed on stake, withdraw, getRewards
    modifier updateReward(uint256 _stakingTokenId) {
        require(
            stakingPairs[_stakingTokenId].exists,
            "Input staking token not exists"
        );

        stakingPairs[_stakingTokenId].rewardPerTokenStored = rewardPerToken(
            _stakingTokenId
        );
        stakingPairs[_stakingTokenId].lastUpdateTime = block.timestamp;
        rewards[msg.sender][_stakingTokenId] = earned(_stakingTokenId);
        userRewardPerTokenPaid[msg.sender][_stakingTokenId] = stakingPairs[
            _stakingTokenId
        ].rewardPerTokenStored;

        _;
    }

    modifier validPair(
        uint256 _depositFee,
        uint256 _stakingTokenId,
        uint256 _rewardTokenId
    ) {
        require(_depositFee <= 10000, "Invalid deposit fee basis points");
        require(
            parentToken.exists(_stakingTokenId),
            "Invalid staking token Id"
        );
        require(parentToken.exists(_rewardTokenId), "Invalid reward token Id");

        _;
    }

    // rewards per token stored
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
            ((stakingPairs[_stakingTokenId].rewardRate *
                (block.timestamp -
                    stakingPairs[_stakingTokenId].lastUpdateTime) *
                1e18) / stakingPairs[_stakingTokenId].totalSupply); //elevated 10^18 to avoid grounding errors
    }

    // how much tokens the user earned so far
    function earned(uint256 _stakingTokenId) public view returns (uint256) {
        return
            ((balances[msg.sender][_stakingTokenId] *
                (rewardPerToken(_stakingTokenId) -
                    userRewardPerTokenPaid[msg.sender][_stakingTokenId])) /
                1e18) + rewards[msg.sender][_stakingTokenId]; //divide by 1e18 since rewardPerToken multiply by 1e18
    }

    function createStakingPair(
        uint256 _stakingTokenId,
        uint256 _rewardTokenId,
        uint256 _rewardRate,
        uint256 _depositFee
    ) public onlyOwner validPair(_depositFee, _stakingTokenId, _rewardTokenId) {
        require(
            !stakingPairs[_stakingTokenId].exists,
            "Staking pair already exists"
        );

        stakingPairs[_stakingTokenId] = StakingPair(
            true,
            _rewardTokenId,
            _rewardRate,
            _depositFee,
            0,
            0,
            0
        );

        emit StakingPairCreated(
            _stakingTokenId,
            _rewardTokenId,
            _rewardRate,
            _depositFee
        );
    }

    function updateStakingPair(
        uint256 _stakingTokenId,
        uint256 _rewardTokenId,
        bool _exists,
        uint256 _rewardRate,
        uint256 _depositFee
    ) public onlyOwner validPair(_depositFee, _stakingTokenId, _rewardTokenId) {
        require(
            stakingPairs[_stakingTokenId].exists,
            "Staking pair does not exists"
        );

        stakingPairs[_stakingTokenId].exists = _exists;
        stakingPairs[_stakingTokenId].rewardTokenId = _rewardTokenId;
        stakingPairs[_stakingTokenId].rewardRate = _rewardRate;
        stakingPairs[_stakingTokenId].depositFee = _depositFee;

        emit StakingPairUpdated(
            _stakingTokenId,
            _rewardTokenId,
            _exists,
            _rewardRate,
            _depositFee
        );
    }

    function stake(uint256 _stakingTokenId, uint256 _amount)
        external
        updateReward(_stakingTokenId)
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
        updateReward(_stakingTokenId)
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
        updateReward(_stakingTokenId)
    {
        uint256 reward = rewards[msg.sender][_stakingTokenId];
        parentToken.mint(
            msg.sender,
            reward,
            stakingPairs[_stakingTokenId].rewardTokenId
        );
        rewards[msg.sender][_stakingTokenId] = 0;
        parentToken.safeTransferFrom(
            address(this),
            msg.sender,
            stakingPairs[_stakingTokenId].rewardTokenId,
            reward,
            ""
        );

        emit RewardPaid(
            msg.sender,
            _stakingTokenId,
            stakingPairs[_stakingTokenId].rewardTokenId,
            reward
        );
    }
}
