const { expect } = require("chai");
const { ethers } = require("hardhat");

let accounts;
let ownerAddress;
let tokensContract;
let helperRoleContract;
let splitContract;
let asteroids;
let veAsteroids;
let stkAsteroids;
const swapAmount = 100;

describe("AsteroidsSplitContract", () => {
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
    veAsteroids = await tokensContract.VE_ASTEROIDS();
    stkAsteroids = await tokensContract.STK_ASTEROIDS();
  });
  it("Contract deploy", async () => {
    const SplitContract = await ethers.getContractFactory(
      "AsteroidsSplitContract"
    );
    splitContract = await SplitContract.deploy(tokensContract.address);
  });
  it("Swap Asteroids to ve and stk Asteroids", async () => {
    const mintRoles = await helperRoleContract.getRangeMintRoleBytes(
      asteroids,
      stkAsteroids
    );
    const burnRoles = await helperRoleContract.getRangeBurnRoleBytes(
      asteroids,
      stkAsteroids
    );
    const roles = [...mintRoles, ...burnRoles];
    const accounts = [];
    for (i = 0; i < roles.length; i++) {
      accounts[i] = splitContract.address;
    }
    await tokensContract.grantMultiRole(roles, accounts);
    await tokensContract.setApprovalForAll(splitContract.address, true);

    const asteroidsBalance = await tokensContract.balanceOf(
      ownerAddress,
      asteroids
    );
    const stkAsteroidsBalance = await tokensContract.balanceOf(
      ownerAddress,
      stkAsteroids
    );
    const veAsteroidsBalance = await tokensContract.balanceOf(
      ownerAddress,
      veAsteroids
    );

    await splitContract.splitAsteroids(swapAmount);

    expect(await tokensContract.balanceOf(ownerAddress, asteroids)).to.be.equal(
      asteroidsBalance.sub(swapAmount)
    );
    expect(
      await tokensContract.balanceOf(ownerAddress, stkAsteroids)
    ).to.be.equal(stkAsteroidsBalance.add(swapAmount));
    expect(
      await tokensContract.balanceOf(ownerAddress, veAsteroids)
    ).to.be.equal(veAsteroidsBalance.add(swapAmount));
  });
  it("Swap back ve and stk Asteroids to Asteroids", async () => {
    const asteroidsBalance = await tokensContract.balanceOf(
      ownerAddress,
      asteroids
    );
    const stkAsteroidsBalance = await tokensContract.balanceOf(
      ownerAddress,
      stkAsteroids
    );
    const veAsteroidsBalance = await tokensContract.balanceOf(
      ownerAddress,
      veAsteroids
    );

    await splitContract.mergeAsteroids(swapAmount);

    expect(await tokensContract.balanceOf(ownerAddress, asteroids)).to.be.equal(
      asteroidsBalance.add(swapAmount)
    );
    expect(
      await tokensContract.balanceOf(ownerAddress, stkAsteroids)
    ).to.be.equal(stkAsteroidsBalance.sub(swapAmount));
    expect(
      await tokensContract.balanceOf(ownerAddress, veAsteroids)
    ).to.be.equal(veAsteroidsBalance.sub(swapAmount));
  });
});
