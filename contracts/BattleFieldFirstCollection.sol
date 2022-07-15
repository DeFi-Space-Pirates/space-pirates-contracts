// SPDX-License-Identifier: unlicense
pragma solidity ^0.8.0;

import "./SpacePiratesTokens.sol";

/**
 * @title Inaugural first battle field collection
 * @author @Gr3it, @yuripaoloni (reviewer)
 * @notice Implement the logic to mint the first collection of battlefield (only estetic, no perks)
 */

contract BattleFieldFirstCollection {
    SpacePiratesTokens public immutable tokenContract;

    uint256 public constant MAX_SUPPLY = 100;
    uint256 public constant MAX_MINT_PER_ADDRESS = 2;
    uint256 public constant PAYING_ID = 1;
    uint256 public constant PRICE = 100_000;

    uint256 public immutable startTime;
    uint256 public immutable duration;

    uint256 public mintId = 99_999;

    mapping(address => uint256) public nbOfBFsMintedBy;

    event Mint(address indexed user, uint256 id);

    constructor(
        SpacePiratesTokens _tokenContract,
        uint256 _startTime,
        uint256 _duration
    ) {
        tokenContract = _tokenContract;
        startTime = _startTime;
        duration = _duration;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function totalSupply() public view returns (uint256) {
        return mintId - 99_999;
    }

    function mint(uint256 _quantity) external callerIsUser {
        require(
            block.timestamp >= startTime,
            "BattleFieldFirstCollection: mint not started yet"
        );
        require(
            block.timestamp <= startTime + duration,
            "BattleFieldFirstCollection: mint already ended"
        );
        require(
            mintId - 99_999 + _quantity <= MAX_SUPPLY,
            "BattleFieldFirstCollection: mint quantity exceeds max supply"
        );
        require(
            nbOfBFsMintedBy[msg.sender] + _quantity <= MAX_MINT_PER_ADDRESS,
            "BattleFieldFirstCollection: mint quantity exceeds allowance for this address"
        );
        require(
            _quantity > 0,
            "BattleFieldFirstCollection: need to mint at least 1 NFT"
        );
        _mintQuantity(_quantity);
    }

    function _mintQuantity(uint256 _quantity) internal {
        tokenContract.burn(msg.sender, PAYING_ID, _quantity * PRICE);
        nbOfBFsMintedBy[msg.sender] += _quantity;
        for (uint256 i = 0; i < _quantity; i++) {
            tokenContract.mint(msg.sender, ++mintId, 1);
            emit Mint(msg.sender, mintId);
        }
    }
}
