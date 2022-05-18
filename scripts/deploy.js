const { ethers } = require("hardhat");

async function main() {
  const addresses = await ethers.getSigners();
  const owner = await addresses[0].getAddress();

  const SpacePiratesTokens = await ethers.getContractFactory(
    "SpacePiratesTokens"
  );
  const SpacePiratesStaking = await ethers.getContractFactory(
    "SpacePiratesStaking"
  );
  const SpacePiratesFactory = await ethers.getContractFactory(
    "SpacePiratesFactory"
  );
  const SpacePiratesRouter = await ethers.getContractFactory(
    "SpacePiratesRouter"
  );
  const SpacePiratesMasterChef = await ethers.getContractFactory(
    "SpacePiratesMasterChef"
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

  const spacePiratesFactory = await SpacePiratesFactory.deploy(
    spacePiratesTokens.address
  );
  console.log(
    "\nSpace Pirates Factory deployed to:",
    spacePiratesFactory.address
  );

  const spacePiratesRouter = await SpacePiratesRouter.deploy(
    spacePiratesFactory.address,
    spacePiratesTokens.address
  );
  console.log(
    "\nSpace Pirates Router deployed to:",
    spacePiratesRouter.address
  );

  const spacePiratesMasterChef = await SpacePiratesMasterChef.deploy(
    spacePiratesTokens.address,
    owner,
    "0x0000000000000000000000000000000000000000",
    100,
    0
  );
  console.log(
    "\nSpace Pirates MasterChef deployed to:",
    spacePiratesMasterChef.address
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
