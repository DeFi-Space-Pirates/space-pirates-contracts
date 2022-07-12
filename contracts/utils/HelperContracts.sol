// SPDX-License-Identifier: unlicense
pragma solidity ^0.8.0;

import "../dex/SpacePiratesPair.sol";

/**
 * @title Helper Contract
 * @author @Gr3it
 * @notice Give access to usefull functions
 */

contract HelperRoleContract {
    function getMintRoleBytes(uint256 id) public pure returns (bytes32) {
        return (keccak256(abi.encodePacked("MINT_ROLE_FOR_ID", id)));
    }

    function getBurnRoleBytes(uint256 id) public pure returns (bytes32) {
        return (keccak256(abi.encodePacked("BURN_ROLE_FOR_ID", id)));
    }

    function getMultiMintRoleBytes(uint256[] calldata ids)
        public
        pure
        returns (bytes32[] memory)
    {
        bytes32[] memory roles = new bytes32[](ids.length);
        for (uint256 i = 0; i < ids.length; ++i) {
            roles[i] = getMintRoleBytes(ids[i]);
        }
        return roles;
    }

    function getMultiBurnRoleBytes(uint256[] calldata ids)
        public
        pure
        returns (bytes32[] memory)
    {
        bytes32[] memory roles = new bytes32[](ids.length);
        for (uint256 i = 0; i < ids.length; ++i) {
            roles[i] = getBurnRoleBytes(ids[i]);
        }
        return roles;
    }

    // from and to id included
    function getRangeMintRoleBytes(uint256 from, uint256 to)
        public
        pure
        returns (bytes32[] memory)
    {
        require(
            to >= from,
            "HelperFunctions: to must be greather or equal that from"
        );
        uint256 length = to - from + 1;
        bytes32[] memory roles = new bytes32[](length);
        for (uint256 i = 0; i < length; ++i) {
            roles[i] = getMintRoleBytes(i + from);
        }
        return roles;
    }

    // from and to id included
    function getRangeBurnRoleBytes(uint256 from, uint256 to)
        public
        pure
        returns (bytes32[] memory)
    {
        require(
            to >= from,
            "HelperFunctions: to must be greather or equal that from"
        );
        uint256 length = to - from + 1;
        bytes32[] memory roles = new bytes32[](length);
        for (uint256 i = 0; i < length; ++i) {
            roles[i] = getBurnRoleBytes(i + from);
        }
        return roles;
    }
}

contract HelperDexContract {
    // get the pair creation code hash
    function getPairInitCodeHash() public pure returns (bytes32) {
        bytes memory bytecode = type(SpacePiratesPair).creationCode;
        return keccak256(bytecode);
    }
}

contract HelperMaxUint {
    function maxUint(uint256 identifier) external pure returns (uint256) {
        return 2**identifier - 1;
    }
}
