// SPDX-License-Identifier: unlicense
pragma solidity ^0.8.0;

/**
 * @title Space Pirates Staking Interface
 * @author @Gr3it
 */

interface ISpacePiratesStaking {
    event Staked(address indexed user, uint256 indexed tokenId, uint256 amount);
    event Unstake(address indexed user, uint256 indexed tokenId, uint256 amount);
    event RewardPaid(address indexed user, uint256 indexed stakingTokenId, uint256 indexed rewardTokenId, uint256 reward);
    event StakingPoolCreated( uint256 indexed stakingTokenId, uint104 rewardTokenId, uint64 rewardRate, uint16 depositFee);
    event StakingPoolUpdated( uint256 indexed stakingTokenId, uint104 rewardTokenId, uint64 rewardRate, uint16 depositFee);
    event SetFeeAddress(address indexed user, address indexed newAddress);
    
    function parentToken() external view returns (address);
    
    function stakingPools(uint256) external view returns (bool exists, uint104 rewardTokenId, uint64 rewardRate, uint16 depositFee, uint64 lastUpdateTime, uint256 totalSupply, uint256 accRewardPerShare);
    function createStakingPool( uint256 _stakingTokenId, uint104 _rewardTokenId, uint64 _rewardRate, uint16 _depositFee) external;
    function updateStakingPool(uint256 _stakingTokenId, uint104 _rewardTokenId, uint64 _rewardRate, uint16 _depositFee) external;
    function poolAmount() external view returns (uint256);
    function poolIds(uint256) external view returns (uint256);
    
    function stake(uint256 _stakingTokenId, uint256 _amount) external;
    function unstake(uint256 _stakingTokenId, uint256 _amount) external;
    
    function usersInfo(uint256, address) external view returns (uint256 rewardDebt, uint256 rewards, uint256 balances);
    function getReward(uint256 _stakingTokenId) external;
    function pendingRewards(uint256 _stakingTokenId, address _user) external view returns (uint256);
    
    function onERC1155BatchReceived( address, address, uint256[] memory, uint256[] memory, bytes memory) external returns (bytes4);
    function onERC1155Received( address, address, uint256, uint256, bytes memory) external returns (bytes4);
    
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    
    function owner() external view returns (address);
    function renounceOwnership() external;
    function transferOwnership(address newOwner) external;
    
    function setFeeAddress(address _feeAddress) external;
    function feeAddress() external view returns (address);
}
