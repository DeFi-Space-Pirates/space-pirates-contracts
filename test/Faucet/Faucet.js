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
    tokensContract = await TokenContract.deploy("");
    accounts = await ethers.getSigners();
    ownerAddress = accounts[0].getAddress();
    asteroids = await tokensContract.ASTEROIDS();
    doubloons = await tokensContract.DOUBLOONS();

    const FaucetContract = await ethers.getContractFactory(
      "SpacePiratesFaucet"
    );
    faucetContract = await FaucetContract.deploy(tokensContract.address);
  });
  it("should add doubloons token", async () => {
    await faucetContract.setMintLimit(doubloons, 100000);
    expect(await faucetContract.tokenMintLimit(doubloons)).to.equal(100000);
    expect(await faucetContract.supportedTokens(0)).to.be.equal(doubloons);
  });
  it("should mint doubloons", async () => {
    const balance = await tokensContract.balanceOf(ownerAddress, doubloons);
    const mintRoles = await helperRoleContract.getMultiMintRoleBytes([
      asteroids,
      doubloons,
    ]);
    const mintAccounts = [];
    for (i = 0; i < mintRoles.length; i++) {
      mintAccounts[i] = faucetContract.address;
    }
    await tokensContract.grantMultiRole(mintRoles, mintAccounts);

    await faucetContract.mintToken(doubloons, 100);
    expect(await tokensContract.balanceOf(ownerAddress, doubloons)).to.equal(
      ethers.BigNumber.from(balance).add(100)
    );
  });
});
