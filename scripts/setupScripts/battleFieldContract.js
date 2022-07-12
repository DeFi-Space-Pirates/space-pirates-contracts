const { ethers } = require("hardhat");
const roles = require("../roles.json");
const ids = require("../ids.json");

module.exports = async function battleFieldContractSetup(
  tokensContract,
  BFMintContract
) {
  console.log("  BFMint contract setup");
  await tokensContract.grantRole(
    roles.mint.battlefield,
    BFMintContract.address
  );
  console.log("    granted NFT mint role to the BFMint contract");
  await tokensContract.grantRole(roles.burn.doubloons, BFMintContract.address);
  console.log("    granted doubloons burn role to the BFMint contract\n");
};
