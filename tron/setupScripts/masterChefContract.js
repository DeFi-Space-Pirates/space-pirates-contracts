const roles = require("../roles.json");
const ids = require("../ids.json");

module.exports = async function masterChefContractSetup(
  tokensContract,
  masterChefContract,
  factoryContract
) {
  console.log("  master chef contract setup");
  await tokensContract
    .grantRole(roles.mint.doubloons, masterChefContract.address)
    .send({ shouldPollResponse: true });
  console.log("    granted doubloons mint role");
  const lpTokenAddress = await factoryContract
    .getPair(ids.doubloons, ids.asteroids)
    .call();
  await masterChefContract
    .add(1000, lpTokenAddress, 0, false)
    .send({ shouldPollResponse: true });
  console.log("    created doubloons and asteroids pool\n");
};
