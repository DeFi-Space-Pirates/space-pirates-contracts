// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Quest Redeem Contract Interface
 * @author @Gr3it
 */

interface ISpacePiratesQuestRedeem {
    event UpdateVerifier(address _addr);
    event QuestClaim(address indexed receiver, string questName, uint256[] ids, uint256[] amounts);

    function tokenContract() external view returns (address);

    function claimQuest(string calldata questName, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata signature) external;
    function signatureVerification(string calldata questName, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata signature) external view returns(bool);

    function verifier() external view returns (address);
    function updateVerifier(address _addr) external;

    function paused() external view returns(bool);
    function pause() external;
    function unpause() external;

    function owner() external view returns(address);
    function renounceOwnership() external;
    function transferOwnership(address newOwner) external;
}
