const { expect } = require("chai");
const { ethers } = require("hardhat");

let spacePiratesFactory;
let spacePiratesTokens;

let owner;
let addr1;
let addr2;
let addrs;

// token IDs
let doubloons;
let asteroids;

describe("SpacePiratesFactory", () => {
  before(async () => {
    const SpacePiratesFactory = await ethers.getContractFactory(
      "SpacePiratesFactory"
    );
    const SpacePiratesTokens = await ethers.getContractFactory(
      "SpacePiratesTokens"
    );

    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

    spacePiratesTokens = await SpacePiratesTokens.deploy("");
    spacePiratesFactory = await SpacePiratesFactory.deploy(
      spacePiratesTokens.address
    );

    // get tokenIDs
    doubloons = await spacePiratesTokens.DOUBLOONS();
    asteroids = await spacePiratesTokens.ASTEROIDS();
  });

  it("should create a new pair", async () => {
    const tx = await spacePiratesFactory.createPair(doubloons, asteroids);

    let receipt = await tx.wait();

    let [event] = receipt.events?.filter((e) => e.event === "PairCreated");

    expect(await spacePiratesFactory.allPairsLength()).to.equal(1);

    expect(await spacePiratesFactory.getPair(doubloons, asteroids)).to.equal(
      event.args.pair
    );
    expect(await spacePiratesFactory.getPair(asteroids, doubloons)).to.equal(
      event.args.pair
    );
  });

  it("should be reverted with IDENTICAL_IDS", async () => {
    await expect(
      spacePiratesFactory.createPair(doubloons, doubloons)
    ).to.be.revertedWith("SpacePiratesFactory: IDENTICAL_IDS");
  });

  it("should be reverted with PAIR_EXISTS", async () => {
    await expect(
      spacePiratesFactory.createPair(doubloons, asteroids)
    ).to.be.revertedWith("SpacePiratesFactory: PAIR_EXISTS");
  });
});
