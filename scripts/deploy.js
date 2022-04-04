// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
    const Items = await hre.ethers.getContractFactory("Items");
    console.log('Deploying contracts...');
    const ItemsContract = await Items.deploy();
    await ItemsContract.deployed();
    console.log("Universal Vending Machine deployed to:", ItemsContract.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });