const { ethers } = require("hardhat");
const roles = require("../roles.json");
const ids = require("../ids.json");

module.exports = async function wrapperContractSetup(
  tokensContract,
  wrapperContract
) {
  console.log("  wrapper contract setup");
  await tokensContract.grantRole(roles.mint.wrapped, wrapperContract.address);
  console.log("    granted mint role for the wrapped tokens");
  await tokensContract.grantRole(roles.burn.wrapped, wrapperContract.address);
  console.log("    granted burn role for the wrapped tokens\n");
};
