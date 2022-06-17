const { ethers } = require("hardhat");
const roles = require("./roles.json");
const ids = require("./ids.json");

async function main() {
  /* Contracts loading */
  const TokensContract = await ethers.getContractFactory("SpacePiratesTokens");
  const StakingContract = await ethers.getContractFactory(
    "SpacePiratesStaking"
  );
  const SplitContract = await ethers.getContractFactory(
    "AsteroidsSplitContract"
  );
  const FaucetContract = await ethers.getContractFactory("SpacePiratesFaucet");

  /* Contracts deploy */
  console.log("\nDeploying contracts...");

  const tokensContract = await TokensContract.deploy();
  console.log("Space Pirates Tokens deployed to:", tokensContract.address);

  const stakingContract = await StakingContract.deploy(tokensContract.address);
  console.log("Space Pirates Staking deployed to:", stakingContract.address);

  const splitContract = await SplitContract.deploy(tokensContract.address);
  console.log("Asteroids Split Contract deployed to:", splitContract.address);

  const faucetContract = await FaucetContract.deploy(tokensContract.address);
  console.log("Faucet Contract deployed to:", faucetContract.address);

  /* Contracts setup*/
  console.log("\nContracts setup...");
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
  console.log("    created stk-asteroids staking pool");

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
  console.log("    granted mint & burn role to the split contract");

  console.log("  faucet contract setup");
  await tokensContract.grantMultiRole(
    [roles.mint.asteroids, roles.mint.doubloons],
    [faucetContract.address, faucetContract.address]
  );
  console.log("    granted mint role to the faucet contract");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
