const { ethers } = require("hardhat");
const roles = require("../roles.json");
const ids = require("../ids.json");

module.exports = async function faucetContractSetup(
  tokensContract,
  faucetContract
) {
  console.log("  faucet contract setup");
  await tokensContract.grantMultiRole(
    [roles.mint.asteroids, roles.mint.doubloons],
    [faucetContract.address, faucetContract.address]
  );
  console.log("    granted mint role to the faucet contract");
  await faucetContract.setMintLimit(1, ethers.utils.parseUnits("10000"));
  console.log("    setted mint limit of doubloons to 10000");
  await faucetContract.setMintLimit(2, ethers.utils.parseUnits("10"));
  console.log("    setted mint limit of asteroids to 10");
};
