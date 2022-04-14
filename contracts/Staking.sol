// SPDX-License-Identifier: unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract Staking is ERC1155Holder {
    IERC1155 public parentToken;

    struct Stake {
        uint256 amount;
        uint256 blockNumber;
    }

    // map staker address to stake details
    mapping(address => mapping(uint256 => Stake)) public stakes;

    // map staker to total staking time
    mapping(address => uint256) public stakingTime;

    event Staked(address sender, uint256 amount, uint256 tokenId);

    event Unstaked(address sender, uint256 amount, uint256 tokenId);

    constructor(address tokens) {
        parentToken = IERC1155(tokens);
    }

    function stake(uint256 _tokenId, uint256 _amount) public {
        stakes[msg.sender][_tokenId] = Stake(_amount, block.number);

        parentToken.safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId,
            _amount,
            ""
        );

        emit Staked(msg.sender, _amount, _tokenId);
    }

    function unstake(uint256 _tokenId, uint256 _amount) public {
        parentToken.safeTransferFrom(
            address(this),
            msg.sender,
            _tokenId,
            _amount,
            ""
        );

        stakingTime[msg.sender] += (block.number -
            stakes[msg.sender][_tokenId].blockNumber);
        stakes[msg.sender][_tokenId].amount =
            stakes[msg.sender][_tokenId].amount -
            _amount;

        emit Unstaked(msg.sender, _amount, _tokenId);
    }
}
