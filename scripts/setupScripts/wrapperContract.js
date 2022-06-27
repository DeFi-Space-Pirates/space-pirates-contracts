const { ethers } = require("hardhat");
const roles = require("../roles.json");
const ids = require("../ids.json");

module.exports = async function wrapperContractSetup(
  tokensContract,
  wrapperContract
) {
  console.log("  wrapper contract setup");
  await tokensContract.grantMultiRole(
    [
      roles.mint.wrapped1,
      roles.mint.wrapped2,
      roles.mint.wrapped3,
      roles.mint.wrapped4,
      roles.mint.wrapped5,
    ],
    [
      wrapperContract.address,
      wrapperContract.address,
      wrapperContract.address,
      wrapperContract.address,
      wrapperContract.address,
    ]
  );
  console.log("    granted mint role for the first 5 wrapped tokens");
  await tokensContract.grantMultiRole(
    [
      roles.burn.wrapped1,
      roles.burn.wrapped2,
      roles.burn.wrapped3,
      roles.burn.wrapped4,
      roles.burn.wrapped5,
    ],
    [
      wrapperContract.address,
      wrapperContract.address,
      wrapperContract.address,
      wrapperContract.address,
      wrapperContract.address,
    ]
  );
  console.log("    granted burn role for the first 5 wrapped tokens");
};
