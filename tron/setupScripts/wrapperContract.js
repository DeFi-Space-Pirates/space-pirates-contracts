const roles = require("../roles.json");
const ids = require("../ids.json");

module.exports = async function wrapperContractSetup(
  tokensContract,
  wrapperContract
) {
  console.log("  wrapper contract setup");
  await tokensContract
    .grantRole(roles.mint.wrapped, wrapperContract.address)
    .send({ shouldPollResponse: true });
  console.log("    granted mint role for the wrapped tokens");
  await tokensContract
    .grantRole(roles.burn.wrapped, wrapperContract.address)
    .send({ shouldPollResponse: true });
  console.log("    granted burn role for the wrapped tokens\n");
};
