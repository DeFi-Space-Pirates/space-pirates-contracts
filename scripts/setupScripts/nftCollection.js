const { ethers } = require("hardhat");
const roles = require("../roles.json");
const ids = require("../ids.json");

module.exports = async function nftCollectionContractSetup(
  tokensContract,
  nftContract,
  nftCollectionContract
) {
  console.log("  nft collection factory contract setup");
  await tokensContract.grantMultiRole(
    [roles.burn.doubloons, roles.burn.asteroids, roles.burn.evocationGem],
    [
      nftCollectionContract.address,
      nftCollectionContract.address,
      nftCollectionContract.address,
    ]
  );
  console.log(
    "    granted doubloons, asteroids and evocation gem burn role to the nft collection contract"
  );
  await nftContract.grantRole(roles.nft.mint, nftCollectionContract.address);
  console.log("    granted NFT mint role to the nft collection contract\n");
};
