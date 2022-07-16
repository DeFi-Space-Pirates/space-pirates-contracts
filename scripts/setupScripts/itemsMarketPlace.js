const { ethers } = require("hardhat");
const roles = require("../roles.json");
const ids = require("../ids.json");

module.exports = async function itemsMarketPlaceSetup(
  tokensContract,
  itemsMarketPlace
) {
  console.log("  market place contract setup");
  await tokensContract.grantRole(
    roles.burn.doubloons,
    itemsMarketPlace.address
  );
  console.log("    granted doubloons burn role");
  await tokensContract.grantRole(
    roles.burn.asteroids,
    itemsMarketPlace.address
  );
  console.log("    granted asteroids burn role");
  await tokensContract.grantRole(roles.mint.items, itemsMarketPlace.address);
  console.log("    granted items mint role");
  await tokensContract.grantRole(
    roles.mint.decorations,
    itemsMarketPlace.address
  );
  console.log("    granted decorations mint role");
  await tokensContract.grantRole(
    roles.mint.battlefield,
    itemsMarketPlace.address
  );
  console.log("    granted battlefield mint role\n");
};
