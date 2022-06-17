const { expect } = require("chai");
const { ethers } = require("hardhat");

let accounts;
let ownerAddress;
let tokensContract;
let helperRoleContract;
let faucetContract;
let asteroids;
let doubloons;

describe("SpacePiratesFaucet", () => {
  before(async () => {
    const HelperRoleContract = await ethers.getContractFactory(
      "HelperRoleContract"
    );
    helperRoleContract = await HelperRoleContract.deploy();
    const TokenContract = await ethers.getContractFactory("SpacePiratesTokens");
    tokensContract = await TokenContract.deploy();
    accounts = await ethers.getSigners();
    ownerAddress = accounts[0].getAddress();
    asteroids = await tokensContract.ASTEROIDS();
    doubloons = await tokensContract.DOUBLOONS();

    const FaucetContract = await ethers.getContractFactory(
      "SpacePiratesFaucet"
    );
    faucetContract = await FaucetContract.deploy(tokensContract.address);
  });
  it("should mint doubloons", async () => {
    const mintRoles = await helperRoleContract.getMultiMintRoleBytes([
      asteroids,
      doubloons,
    ]);
    const mintAccounts = [];
    for (i = 0; i < mintRoles.length; i++) {
      mintAccounts[i] = faucetContract.address;
    }
    await tokensContract.grantMultiRole(mintRoles, mintAccounts);

    await faucetContract.mintDoubloons(10);
    expect(await faucetContract.mintedDoubloons(ownerAddress)).to.equal(10);
  });
  it("should mint asteroids", async () => {
    await faucetContract.mintAsteroids(10);

    expect(await faucetContract.mintedAsteroids(ownerAddress)).to.equal(10);
  });
  it("should mint maximum amount of doubloons", async () => {
    await faucetContract.mintDoubloons(9985); // 10 already minted
    expect(await faucetContract.mintedDoubloons(ownerAddress)).to.equal(9995);

    await faucetContract.mintDoubloons(20);
    expect(await faucetContract.mintedDoubloons(ownerAddress)).to.equal(10000);
  });
  it("should mint maximum amount of asteroids", async () => {
    await faucetContract.mintAsteroids(9985); // 10 already minted
    expect(await faucetContract.mintedAsteroids(ownerAddress)).to.equal(9995);

    await faucetContract.mintAsteroids(20);
    expect(await faucetContract.mintedAsteroids(ownerAddress)).to.equal(10000);
  });
  it("should set new mint limit", async () => {
    await faucetContract.setMintLimit(20000);
    expect(await faucetContract.mintLimit()).to.equal(20000);
  });
});
