// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./SpacePiratesPair.sol";

contract UniswapV2Factory is Ownable {
    address public feeTo;

    mapping(uint256 => mapping(uint256 => address)) public getPair;
    address[] public allPairs;

    event PairCreated(
        uint256 indexed token0,
        uint256 indexed token1,
        address pair,
        uint256
    );

    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

    function createPair(uint128 tokenA, uint128 tokenB)
        external
        onlyOwner
        returns (address pair)
    {
        require(tokenA != tokenB, "SpacePiratesFactory: IDENTICAL_IDS");
        (uint128 token0, uint128 token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(
            getPair[token0][token1] == address(0),
            "SpacePiratesFactory: PAIR_EXISTS"
        ); // single check is sufficient
        bytes memory bytecode = type(SpacePiratesPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        SpacePiratesPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external onlyOwner {
        feeTo = _feeTo;
    }
}
