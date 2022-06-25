const { ethers } = require("hardhat");
const roles = require("../roles.json");
const ids = require("../ids.json");

module.exports = async function factoryContractSetup(factoryContract) {
  console.log("  factory contract setup");
  await factoryContract.createPair(ids.doubloons, ids.asteroids);
  console.log("    created doubloons and asteroids pool\n");
};
