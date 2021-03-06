const { ethers } = require("hardhat");
const roles = require("../roles.json");
const ids = require("../ids.json");

module.exports = async function stakingContractSetup(
  tokensContract,
  stakingContract
) {
  console.log("  staking contract setup");
  await tokensContract.grantRole(roles.mint.doubloons, stakingContract.address);
  console.log("    granted doubloons mint role");
  await stakingContract.createStakingPool(
    ids.doubloons,
    ids.doubloons,
    ethers.BigNumber.from("2000000000000000000"),
    0
  );
  console.log("    created doubloons staking pool");
  await stakingContract.createStakingPool(
    ids.stkAsteroids,
    ids.doubloons,
    ethers.BigNumber.from("2000000000000000000"),
    0
  );
  console.log("    created stk-asteroids staking pool\n");
};
