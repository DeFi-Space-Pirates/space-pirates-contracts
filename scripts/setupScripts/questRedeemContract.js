const { ethers } = require("hardhat");
const roles = require("../roles.json");
const ids = require("../ids.json");

module.exports = async function questRedeemContractSetup(
  tokensContract,
  questRedeemContract
) {
  console.log("  quest redeem contract setup");
  await tokensContract.grantRole(
    roles.mint.doubloons,
    questRedeemContract.address
  );
  console.log("    granted mint role for doubloons");
  await tokensContract.grantRole(
    roles.mint.asteroids,
    questRedeemContract.address
  );
  console.log("    granted mint role for asteroids");
  await tokensContract.grantRole(roles.mint.items, questRedeemContract.address);
  console.log("    granted mint role for items");
  await tokensContract.grantRole(
    roles.mint.titles,
    questRedeemContract.address
  );
  console.log("    granted mint role for titles");
  await tokensContract.grantRole(
    roles.burn.decorations,
    questRedeemContract.address
  );
  console.log("    granted mint role for decorations\n");
};
