const { ethers } = require("hardhat");
const roles = require("../roles.json");
const ids = require("../ids.json");

module.exports = async function nftStarterContractSetup(
  tokensContract,
  nftContract,
  nftStarterContract
) {
  console.log("  nft starter collection contract setup");
  await tokensContract.grantRole(
    roles.burn.starterGem,
    nftStarterContract.address
  );
  console.log(
    "    granted starter gem burn role to the nft collection contract"
  );
  await nftContract.grantRole(roles.nft.mint, nftStarterContract.address);
  console.log("    granted NFT mint role to the nft collection contract\n");
};
