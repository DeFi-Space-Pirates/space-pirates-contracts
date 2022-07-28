// SPDX-License-Identifier: unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./ERC1155Custom.sol";

/**
 * @title Space Pirates Tokens Contract
 * @author @Gr3it, @yuripaoloni, @MatteoLeonesi
 * @notice Store all the tokens data and give to other contract permission to implements logic on top of the tokens
 */

contract SpacePiratesTokens is ERC1155Custom, AccessControl {
    /**
     * Tokens' Ids distribution
     *       1 -      99 Projects tokens
     *     100 -     199 Wrapped tokens
     *   1 000 -   9 999 Items
     *  10 000 -  19 999 Titles
     *  20 000 -  99 999 Decorations
     * 100 000 - 199 999 Battle Fields
     */
    uint256 public constant DOUBLOONS = 1;
    uint256 public constant ASTEROIDS = 2;
    uint256 public constant VE_ASTEROIDS = 3;
    uint256 public constant STK_ASTEROIDS = 4;

    // Minting role = keccak256(abi.encodePacked("MINT_ROLE_FOR_ID",id));
    // Burning role = keccak256(abi.encodePacked("BURN_ROLE_FOR_ID",id));
    bytes32 public constant WRAPPED_MINT_ROLE = keccak256("WRAPPED_MINT_ROLE");
    bytes32 public constant WRAPPED_BURN_ROLE = keccak256("WRAPPED_BURN_ROLE");
    bytes32 public constant ITEMS_MINT_ROLE = keccak256("ITEMS_MINT_ROLE");
    bytes32 public constant ITEMS_BURN_ROLE = keccak256("ITEMS_BURN_ROLE");
    bytes32 public constant TITLES_MINT_ROLE = keccak256("TITLES_MINT_ROLE");
    bytes32 public constant TITLES_BURN_ROLE = keccak256("TITLES_BURN_ROLE");
    bytes32 public constant DECORATIONS_MINT_ROLE =
        keccak256("DECORATIONS_MINT_ROLE");
    bytes32 public constant DECORATIONS_BURN_ROLE =
        keccak256("DECORATIONS_BURN_ROLE");
    bytes32 public constant BF_MINT_ROLE = keccak256("BF_MINT_ROLE");
    bytes32 public constant BF_BURN_ROLE = keccak256("BF_BURN_ROLE");

    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant CAN_PAUSE_ROLE = keccak256("CAN_PAUSE_ROLE");
    bytes32 public constant CAN_UNPAUSE_ROLE = keccak256("CAN_UNPAUSE_ROLE");
    bytes32 public constant TRANSFERABLE_SETTER_ROLE =
        keccak256("TRANSFERABLE_SETTER_ROLE");

    event Mint(
        address indexed sender,
        uint256 id,
        uint256 amount,
        address indexed to
    );
    event Burn(address indexed sender, uint256 id, uint256 amount);
    event MintBatch(
        address indexed sender,
        uint256[] ids,
        uint256[] amounts,
        address indexed to
    );
    event BurnBatch(address indexed sender, uint256[] ids, uint256[] amounts);
    event GrantRole(bytes32 indexed role, address account);
    event RevokeRole(bytes32 indexed role, address account);
    event GrantMultiRole(bytes32[] indexed roles, address[] accounts);
    event RevokeMultiRole(bytes32[] indexed roles, address[] accounts);
    event RenounceRole(bytes32 indexed role, address account);
    event Pause();
    event Unpause();
    event LockTokenTransfer();
    event UnLockTokenTransfer();
    event UriUpdate(string newUri);

    constructor(string memory uri) ERC1155Custom(uri) {
        _mint(msg.sender, DOUBLOONS, 1_000_000 * (10**18), "");
        _mint(msg.sender, ASTEROIDS, 100 * (10**18), "");

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155Custom, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setURI(string memory newUri) public onlyRole(URI_SETTER_ROLE) {
        _setURI(newUri);
        emit UriUpdate(newUri);
    }

    function lockTokenTransfer(uint256 id)
        public
        onlyRole(TRANSFERABLE_SETTER_ROLE)
    {
        _setTrasferBlock(id, true);
        emit LockTokenTransfer();
    }

    function unLockTokenTransfer(uint256 id)
        public
        onlyRole(TRANSFERABLE_SETTER_ROLE)
    {
        _setTrasferBlock(id, false);
        emit UnLockTokenTransfer();
    }

    function pause() public onlyRole(CAN_PAUSE_ROLE) {
        _pause();
        emit Pause();
    }

    function unpause() public onlyRole(CAN_UNPAUSE_ROLE) {
        _unpause();
        emit Unpause();
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) public {
        _checkMintRole(id);
        _mint(to, id, amount, "");
        emit Mint(msg.sender, id, amount, to);
    }

    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) public {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _checkBurnRole(id);
        _burn(from, id, amount);
        emit Burn(from, id, amount);
    }

    function mintBatch(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) public {
        _checkMintBatchRole(ids);
        _mintBatch(to, ids, amounts, "");
        emit MintBatch(msg.sender, ids, amounts, to);
    }

    function burnBatch(
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) public {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _checkBurnBatchRole(ids);
        _burnBatch(from, ids, amounts);
        emit BurnBatch(from, ids, amounts);
    }

    function grantRole(bytes32 role, address account)
        public
        override
        onlyRole(getRoleAdmin(role))
    {
        _grantRole(role, account);
        emit GrantRole(role, account);
    }

    function revokeRole(bytes32 role, address account)
        public
        override
        onlyRole(getRoleAdmin(role))
    {
        _revokeRole(role, account);
        emit RevokeRole(role, account);
    }

    function grantMultiRole(
        bytes32[] calldata roles,
        address[] calldata accounts
    ) public {
        require(
            roles.length == accounts.length,
            "AccessControl: array of different length"
        );
        for (uint256 i = 0; i < roles.length; ++i) {
            _checkRole(getRoleAdmin(roles[i]), msg.sender);
            _grantRole(roles[i], accounts[i]);
        }
        emit GrantMultiRole(roles, accounts);
    }

    function revokeMultiRole(
        bytes32[] calldata roles,
        address[] calldata accounts
    ) public {
        require(
            roles.length == accounts.length,
            "AccessControl: array of different length"
        );
        for (uint256 i = 0; i < roles.length; ++i) {
            _checkRole(getRoleAdmin(roles[i]), msg.sender);
            _revokeRole(roles[i], accounts[i]);
        }
        emit RevokeMultiRole(roles, accounts);
    }

    function _checkMintRole(uint256 id) internal view {
        if (
            hasRole(
                keccak256(abi.encodePacked("MINT_ROLE_FOR_ID", id)),
                msg.sender
            )
        ) return;
        if (id <= 199 && id >= 100 && hasRole(WRAPPED_MINT_ROLE, msg.sender))
            return;
        if (id <= 9_999 && id >= 1_000 && hasRole(ITEMS_MINT_ROLE, msg.sender))
            return;
        if (
            id <= 19_999 &&
            id >= 10_000 &&
            hasRole(TITLES_MINT_ROLE, msg.sender)
        ) return;
        if (
            id <= 99_999 &&
            id >= 20_000 &&
            hasRole(DECORATIONS_MINT_ROLE, msg.sender)
        ) return;
        if (id <= 199_999 && id >= 100_000 && hasRole(BF_MINT_ROLE, msg.sender))
            return;
        revert("AccessControl: missing mint role");
    }

    function _checkBurnRole(uint256 id) internal view {
        if (
            hasRole(
                keccak256(abi.encodePacked("BURN_ROLE_FOR_ID", id)),
                msg.sender
            )
        ) return;
        if (id <= 199 && id >= 100 && hasRole(WRAPPED_BURN_ROLE, msg.sender))
            return;
        if (id <= 9_999 && id >= 1_000 && hasRole(ITEMS_BURN_ROLE, msg.sender))
            return;
        if (
            id <= 19_999 &&
            id >= 10_000 &&
            hasRole(TITLES_BURN_ROLE, msg.sender)
        ) return;
        if (
            id <= 99_999 &&
            id >= 20_000 &&
            hasRole(DECORATIONS_BURN_ROLE, msg.sender)
        ) return;
        if (id <= 199_999 && id >= 100_000 && hasRole(BF_BURN_ROLE, msg.sender))
            return;
        revert("AccessControl: missing burn role");
    }

    function _checkMintBatchRole(uint256[] calldata ids) internal view {
        for (uint256 i = 0; i < ids.length; ++i) {
            _checkMintRole(ids[i]);
        }
    }

    function _checkBurnBatchRole(uint256[] calldata ids) internal view {
        for (uint256 i = 0; i < ids.length; ++i) {
            _checkBurnRole(ids[i]);
        }
    }
}
