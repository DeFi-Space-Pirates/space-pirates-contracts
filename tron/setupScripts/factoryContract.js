const roles = require("../roles.json");
const ids = require("../ids.json");

module.exports = async function factoryContractSetup(factoryContract) {
  console.log("  factory contract setup");
  await factoryContract
    .createPair(ids.doubloons, ids.asteroids)
    .send({ shouldPollResponse: true });
  console.log("    created doubloons and asteroids pool\n");
};
