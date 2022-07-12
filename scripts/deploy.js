const { ethers } = require("hardhat");

const stakingContractSetup = require("./setupScripts/stakingContract");
const splitContractSetup = require("./setupScripts/splitContract");
const faucetContractSetup = require("./setupScripts/faucetContract");
const factoryContractSetup = require("./setupScripts/factoryContract");
const masterChefContractSetup = require("./setupScripts/masterChefContract");
const wrapperContractSetup = require("./setupScripts/wrapperContract");
const questRedeemContractSetup = require("./setupScripts/questRedeemContract");
const itemsMarketPlaceSetup = require("./setupScripts/itemsMarketPlace");

async function main() {
  /* CONTRACT PARAMETERS */
  const addresses = await ethers.getSigners();
  const devAddress = await addresses[0].getAddress();
  const feeAddress = "0x0000000000000000000000000000000000000000";
  const doubloonsPerBlock = 100;
  const startBlock = 0;

  /* CONTRACTS CREATION */
  const TokensContract = await ethers.getContractFactory("SpacePiratesTokens");

  const StakingContract = await ethers.getContractFactory(
    "SpacePiratesStaking"
  );

  const SplitContract = await ethers.getContractFactory(
    "AsteroidsSplitContract"
  );

  const FaucetContract = await ethers.getContractFactory("SpacePiratesFaucet");

  const WrapperContract = await ethers.getContractFactory(
    "SpacePiratesWrapper"
  );

  const FactoryContract = await ethers.getContractFactory(
    "SpacePiratesFactory"
  );

  const RouterContract = await ethers.getContractFactory("SpacePiratesRouter");

  const MasterChefContract = await ethers.getContractFactory(
    "SpacePiratesMasterChef"
  );

  const QuestRedeemContract = await ethers.getContractFactory(
    "SpacePiratesQuestRedeem"
  );

  const ItemsMarketPlace = await ethers.getContractFactory(
    "SpacePiratesItemsMarketPlace"
  );

  /* CONTRACTS DEPLOY */
  console.log("\nDeploying contracts...\n");

  const tokensContract = await TokensContract.deploy("testuri.com/token/");
  console.log("Space Pirates Tokens deployed to:", tokensContract.address);

  const stakingContract = await StakingContract.deploy(tokensContract.address);
  console.log("Space Pirates Staking deployed to:", stakingContract.address);

  const splitContract = await SplitContract.deploy(tokensContract.address);
  console.log("Asteroids Split Contract deployed to:", splitContract.address);

  const faucetContract = await FaucetContract.deploy(tokensContract.address);
  console.log("Faucet Contract deployed to:", faucetContract.address);

  const wrapperContract = await WrapperContract.deploy(tokensContract.address);
  console.log("Faucet Contract deployed to:", wrapperContract.address);

  const factoryContract = await FactoryContract.deploy(tokensContract.address);
  console.log("Factory Contract deployed to:", factoryContract.address);

  const routerContract = await RouterContract.deploy(
    factoryContract.address,
    tokensContract.address,
    wrapperContract.address
  );
  console.log("Router Contract deployed to:", routerContract.address);

  const masterChefContract = await MasterChefContract.deploy(
    tokensContract.address,
    devAddress,
    feeAddress,
    doubloonsPerBlock,
    startBlock
  );
  console.log("MasterChef Contract deployed to:", masterChefContract.address);

  const questRedeemContract = await QuestRedeemContract.deploy(
    tokensContract.address
  );
  console.log(
    "Quest Redeem Contract deployed to:",
    questRedeemContract.address
  );

  const itemsMarketPlace = await ItemsMarketPlace.deploy(
    tokensContract.address
  );

  /* CONTRACTS SETUP */
  console.log("\nContracts setup...\n");

  await stakingContractSetup(tokensContract, stakingContract);
  await splitContractSetup(tokensContract, splitContract);
  await faucetContractSetup(tokensContract, faucetContract);
  await factoryContractSetup(factoryContract);
  await masterChefContractSetup(
    tokensContract,
    masterChefContract,
    factoryContract
  );
  await wrapperContractSetup(tokensContract, wrapperContract);
  await questRedeemContractSetup(tokensContract, questRedeemContract);
  await itemsMarketPlaceSetup(tokensContract, questRedeemContract);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
