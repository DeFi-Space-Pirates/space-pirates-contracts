const TronWeb = require("tronweb");
const feeLimit = 1000000000;

const stakingContractSetup = require("./setupScripts/stakingContract");
const splitContractSetup = require("./setupScripts/splitContract");
const faucetContractSetup = require("./setupScripts/faucetContract");
const factoryContractSetup = require("./setupScripts/factoryContract");
const masterChefContractSetup = require("./setupScripts/masterChefContract");
const wrapperContractSetup = require("./setupScripts/wrapperContract");
const questRedeemContractSetup = require("./setupScripts/questRedeemContract");
const battleFieldContractSetup = require("./setupScripts/battleFieldContract");
const itemsMarketPlaceSetup = require("./setupScripts/itemsMarketPlace");

async function main() {
  /* CONTRACT PARAMETERS */
  const tronWeb = new TronWeb({
    fullHost: process.env.TRON_FULL_HOST,
    privateKey: process.env.TRON_PRIVATE_KEY,
  });

  const devAddress = tronWeb.defaultAddress.hex;
  const feeAddress = "T9yD14Nj9j7xAB4dbGeiX9h8unkKHxuWwb";
  const doubloonsPerBlock = 100;
  const startBlock = 0;
  const BFMintStart = 1640995200; // 2020/1/1
  const BFMintDuration = 31536000; // 1 year

  /* CONTRACTS CREATION */
  const TokensContract = require("../build/contracts/SpacePiratesTokens.json");
  const StakingContract = require("../build/contracts/SpacePiratesStaking.json");
  const SplitContract = require("../build/contracts/AsteroidsSplitContract.json");
  const FaucetContract = require("../build/contracts/SpacePiratesFaucet.json");
  const WrapperContract = require("../build/contracts/SpacePiratesWrapper.json");
  const FactoryContract = require("../build/contracts/SpacePiratesFactory.json");
  const RouterContract = require("../build/contracts/SpacePiratesRouter.json");
  const MasterChefContract = require("../build/contracts/SpacePiratesMasterChef.json");
  const QuestRedeemContract = require("../build/contracts/SpacePiratesQuestRedeem.json");
  const BattleFieldMintContract = require("../build/contracts/BattleFieldFirstCollection.json");
  const ItemsMarketPlace = require("../build/contracts/SpacePiratesItemsMarketPlace.json");

  /* CONTRACTS DEPLOY */
  console.log("\nDeploying contracts...\n");
  const tokensContract = await tronWeb.contract().new({
    abi: TokensContract.abi,
    bytecode: TokensContract.bytecode,
    feeLimit: feeLimit,
    parameters: ["testuri.com/token/"],
  });
  console.log("Space Pirates Tokens deployed to:", tokensContract.address);

  const stakingContract = await tronWeb.contract().new({
    abi: StakingContract.abi,
    bytecode: StakingContract.bytecode,
    feeLimit: feeLimit,
    parameters: [tokensContract.address],
  });
  console.log("Space Pirates Staking deployed to:", stakingContract.address);

  const splitContract = await tronWeb.contract().new({
    abi: SplitContract.abi,
    bytecode: SplitContract.bytecode,
    feeLimit: feeLimit,
    parameters: [tokensContract.address],
  });
  console.log("Asteroids Split Contract deployed to:", splitContract.address);

  const faucetContract = await tronWeb.contract().new({
    abi: FaucetContract.abi,
    bytecode: FaucetContract.bytecode,
    feeLimit: feeLimit,
    parameters: [tokensContract.address],
  });
  console.log("Faucet Contract deployed to:", faucetContract.address);

  const wrapperContract = await tronWeb.contract().new({
    abi: WrapperContract.abi,
    bytecode: WrapperContract.bytecode,
    feeLimit: feeLimit,
    parameters: [tokensContract.address],
  });
  console.log("Wrapper Contract deployed to:", wrapperContract.address);

  const factoryContract = await tronWeb.contract().new({
    abi: FactoryContract.abi,
    bytecode: FactoryContract.bytecode,
    feeLimit: feeLimit,
    parameters: [tokensContract.address],
  });
  console.log("Factory Contract deployed to:", factoryContract.address);

  const routerContract = await tronWeb.contract().new({
    abi: RouterContract.abi,
    bytecode: RouterContract.bytecode,
    feeLimit: feeLimit,
    parameters: [
      factoryContract.address,
      tokensContract.address,
      wrapperContract.address,
    ],
  });
  console.log("Router Contract deployed to:", routerContract.address);

  const masterChefContract = await tronWeb.contract().new({
    abi: MasterChefContract.abi,
    bytecode: MasterChefContract.bytecode,
    feeLimit: feeLimit,
    parameters: [
      tokensContract.address,
      devAddress,
      feeAddress,
      doubloonsPerBlock,
      startBlock,
    ],
  });
  console.log("MasterChef Contract deployed to:", masterChefContract.address);

  const questRedeemContract = await tronWeb.contract().new({
    abi: QuestRedeemContract.abi,
    bytecode: QuestRedeemContract.bytecode,
    feeLimit: feeLimit,
    parameters: [tokensContract.address],
  });
  console.log(
    "Quest Redeem Contract deployed to:",
    questRedeemContract.address
  );

  const battleFieldMintContract = await tronWeb.contract().new({
    abi: BattleFieldMintContract.abi,
    bytecode: BattleFieldMintContract.bytecode,
    feeLimit: feeLimit,
    parameters: [tokensContract.address, BFMintStart, BFMintDuration],
  });
  console.log("BFMint Contract deployed to:", battleFieldMintContract.address);

  const itemsMarketPlace = await tronWeb.contract().new({
    abi: ItemsMarketPlace.abi,
    bytecode: ItemsMarketPlace.bytecode,
    feeLimit: feeLimit,
    parameters: [tokensContract.address],
  });
  console.log("Market Place Contract deployed to:", itemsMarketPlace.address);
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
  await battleFieldContractSetup(tokensContract, battleFieldMintContract);
  await itemsMarketPlaceSetup(tokensContract, questRedeemContract);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
