
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  const Bolts = await hre.ethers.getContractFactory("BoltsToken");
  const Screws = await hre.ethers.getContractFactory("ScrewsToken");
  const Uvm = await hre.ethers.getContractFactory("Uvm");
  console.log('Deploying contracts...');
  const bolts = await Bolts.deploy();
  await bolts.deployed();
  const screws = await Screws.deploy();
  await screws.deployed();
  const uvm = await Uvm.deploy(bolts.address, screws.address);
  await uvm.deployed();
  console.log("Bolts token deployed at:", bolts.address);
  console.log("Srews token deployed at:", screws.address);
  console.log("Universal Vending Machine deployed to:", uvm.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });