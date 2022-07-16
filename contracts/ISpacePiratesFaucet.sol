interface ISpacePiratesFaucet {
  function mintToken ( uint256 tokenId, uint256 amount ) external;
  function owner (  ) external view returns ( address );
  function renounceOwnership (  ) external;
  function setMintLimit ( uint256 tokenId, uint256 mintLimit ) external;
  function supportedTokens ( uint256 ) external view returns ( uint256 );
  function tokenContract (  ) external view returns ( address );
  function tokenMintLimit ( uint256 ) external view returns ( uint256 );
  function transferOwnership ( address newOwner ) external;
}
