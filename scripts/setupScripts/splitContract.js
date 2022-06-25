const { ethers } = require("hardhat");
const roles = require("../roles.json");
const ids = require("../ids.json");

module.exports = async function splitContractSetup(
  tokensContract,
  splitContract
) {
  console.log("  asteroids split contract setup");
  await tokensContract.grantMultiRole(
    [
      roles.mint.asteroids,
      roles.mint.veAsteroids,
      roles.mint.stkAsteroids,
      roles.burn.asteroids,
      roles.burn.veAsteroids,
      roles.burn.stkAsteroids,
    ],
    [
      splitContract.address,
      splitContract.address,
      splitContract.address,
      splitContract.address,
      splitContract.address,
      splitContract.address,
    ]
  );
  console.log("    granted mint & burn role to the split contract\n");
};
