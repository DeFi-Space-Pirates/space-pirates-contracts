// SPDX-License-Identifier: unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./SpacePiratesTokens.sol";

/**
 * @title Space Pirates Quest Redeem Contract
 * @author @Gr3it, @yuripaoloni (reviewer), @MatteoLeonesi (reviewer)
 * @notice Let user claim their quest via a valid signature
 */

contract SpacePiratesQuestRedeem is Ownable, EIP712, Pausable {
    string private constant SIGNING_DOMAIN = "Space Pirates";
    string private constant SIGNATURE_VERSION = "1";

    SpacePiratesTokens public immutable tokenContract;
    address public verifier;

    mapping(bytes => bool) claimed;

    event UpdateVerifier(address _addr);
    event QuestClaim(
        address indexed receiver,
        string questName,
        uint256[] ids,
        uint256[] amounts
    );

    constructor(SpacePiratesTokens _tokenContract)
        EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION)
    {
        tokenContract = _tokenContract;
    }

    function claimQuest(
        string calldata questName,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata signature
    ) public whenNotPaused {
        require(
            !claimed[signature],
            "SpacePiratesQuestRedeem: quest already claimed"
        );
        require(
            signatureVerification(questName, ids, amounts, signature),
            "SpacePiratesQuestRedeem: invalid signature"
        );
        claimed[signature] = true;
        tokenContract.mintBatch(msg.sender, ids, amounts);
        emit QuestClaim(msg.sender, questName, ids, amounts);
    }

    function signatureVerification(
        string calldata questName,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata signature
    ) public view returns (bool) {
        bytes32 digest = _hash(questName, ids, amounts, msg.sender);
        return ECDSA.recover(digest, signature) == verifier;
    }

    function _hash(
        string calldata questName,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        address receiver
    ) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "SpacePiratesQuest(string questName,uint256[] ids,uint256[] amounts,address receiver)"
                        ),
                        keccak256(bytes(questName)),
                        keccak256(abi.encodePacked(ids)),
                        keccak256(abi.encodePacked(amounts)),
                        receiver
                    )
                )
            );
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function updateVerifier(address _addr) public onlyOwner {
        verifier = _addr;
        emit UpdateVerifier(_addr);
    }
}
