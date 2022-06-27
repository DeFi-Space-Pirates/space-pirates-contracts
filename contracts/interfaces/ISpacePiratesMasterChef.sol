// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Space Pirates MasterChef Interface
 * @author @Gr3it
 */

interface ISpacePiratesMasterChef {
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SetFeeAddress(address indexed user, address indexed newAddress);
    event SetDevAddress(address indexed user, address indexed newAddress);
    event UpdateEmissionRate(address indexed user, uint256 doubloonsPerBlock);

    function DOUBLOONS_ID() external view returns (uint256);
    function BONUS_MULTIPLIER() external view returns (uint256);
    
    function doubloons() external view returns (address);
    function doubloonsPerBlock() external view returns (uint256);
    function startBlock() external view returns (uint256);
    function totalAllocPoint() external view returns (uint256);
    
    function userInfo(uint256, address) external view returns (uint256 amount, uint256 rewardDebt);
    
    function poolInfo(uint256) external view returns (address lpToken, uint256 allocPoint, uint256 lastRewardBlock, uint256 accDoubloonsPerShare, uint16 depositFeeBP);
    function poolExistence(address) external view returns (bool);
    function poolLength() external view returns (uint256);
    function massUpdatePools() external;
    function updatePool(uint256 _pid) external;
    
    function getMultiplier(uint256 _from, uint256 _to) external pure returns (uint256);
    function pendingDoubloons(uint256 _pid, address _user) external view returns (uint256);
    
    function add(uint256 _allocPoint, address _lpToken, uint16 _depositFeeBP, bool _withUpdate) external;
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, bool _withUpdate) external;
    
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function emergencyWithdraw(uint256 _pid) external;
    
    function updateEmissionRate(uint256 _doubloonsPerBlock) external;
    
    function devaddr() external view returns (address);
    function dev(address _devaddr) external;
    
    function feeAddress() external view returns (address);
    function setFeeAddress(address _feeAddress) external;
    
    function owner() external view returns (address);
    function renounceOwnership() external;
    function transferOwnership(address newOwner) external;
}
