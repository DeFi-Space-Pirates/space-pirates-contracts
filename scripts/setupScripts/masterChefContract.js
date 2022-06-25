const { ethers } = require("hardhat");
const roles = require("../roles.json");
const ids = require("../ids.json");

module.exports = async function masterChefContractSetup(
  tokensContract,
  masterChefContract,
  factoryContract
) {
  console.log("  master chef contract setup");
  await tokensContract.grantRole(
    roles.mint.doubloons,
    masterChefContract.address
  );
  console.log("    granted doubloons mint role");
  const lpTokenAddress = await factoryContract.getPair(
    ids.doubloons,
    ids.asteroids
  );
  masterChefContract.add(1000, lpTokenAddress, 0, false);
  console.log("    created doubloons and asteroids pool\n");
};
