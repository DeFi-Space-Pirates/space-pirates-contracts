const { ethers } = require("hardhat");

async function main() {
  const SpacePiratesTokens = await ethers.getContractFactory(
    "SpacePiratesTokens"
  );
  const SpacePiratesStaking = await ethers.getContractFactory(
    "SpacePiratesStaking"
  );

  console.log("\nDeploying contracts...");

  const spacePiratesTokens = await SpacePiratesTokens.deploy();
  console.log(
    "\nSpace Pirates Tokens deployed to:",
    spacePiratesTokens.address
  );

  const spacePiratesStaking = await SpacePiratesStaking.deploy(
    spacePiratesTokens.address
  );
  console.log(
    "\nSpace Pirates Staking deployed to:",
    spacePiratesStaking.address
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
