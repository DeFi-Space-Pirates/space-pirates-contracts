const { expect } = require("chai");
const { ethers } = require("hardhat");
const { BigNumber } = require("ethers");

let accounts;
let ownerAddress;
let tokensContract;
let helperRoleContract;
let questContract;
let asteroids;
let doubloons;
let network;
let signature;

let domain;
let types;

describe("SpacePiratesQuestRedeem", () => {
  before(async () => {
    const HelperRoleContract = await ethers.getContractFactory(
      "HelperRoleContract"
    );
    helperRoleContract = await HelperRoleContract.deploy();
    const TokenContract = await ethers.getContractFactory("SpacePiratesTokens");
    tokensContract = await TokenContract.deploy("");
    const QuestContract = await ethers.getContractFactory(
      "SpacePiratesQuestRedeem"
    );
    questContract = await QuestContract.deploy(tokensContract.address);

    accounts = await ethers.getSigners();
    ownerAddress = await accounts[0].getAddress();
    network = await accounts[0].provider.getNetwork();
    asteroids = await tokensContract.ASTEROIDS();
    doubloons = await tokensContract.DOUBLOONS();

    domain = {
      name: "Space Pirates",
      version: "1",
      chainId: network.chainId,
      verifyingContract: questContract.address,
    };
    types = {
      SpacePiratesQuest: [
        { name: "questName", type: "string" },
        { name: "ids", type: "uint256[]" },
        { name: "amounts", type: "uint256[]" },
        { name: "receiver", type: "address" },
      ],
    };
  });
  it("should claim a quest", async () => {
    const mintRoles = await helperRoleContract.getMultiMintRoleBytes([
      asteroids,
      doubloons,
    ]);
    const mintAccounts = [];
    for (i = 0; i < mintRoles.length; i++) {
      mintAccounts[i] = questContract.address;
    }
    await tokensContract.grantMultiRole(mintRoles, mintAccounts);
    const doubloonsBalance = await tokensContract.balanceOf(
      ownerAddress,
      doubloons
    );
    const asteroidsBalance = await tokensContract.balanceOf(
      ownerAddress,
      asteroids
    );

    const value = {
      questName: "Test Quest",
      ids: [doubloons, asteroids],
      amounts: [1000, 200],
      receiver: ownerAddress,
    };

    signature = await accounts[0]._signTypedData(domain, types, value);
    await questContract.updateVerifier(ownerAddress);

    await questContract.claimQuest(
      "Test Quest",
      [doubloons, asteroids],
      [1000, 200],
      signature
    );

    expect(await tokensContract.balanceOf(ownerAddress, doubloons)).to.be.equal(
      BigNumber.from(doubloonsBalance).add(1000)
    );
    expect(await tokensContract.balanceOf(ownerAddress, asteroids)).to.be.equal(
      BigNumber.from(asteroidsBalance).add(200)
    );
  });
  it("should revert if already claimed", async () => {
    await expect(
      questContract.claimQuest(
        "Test Quest",
        [doubloons, asteroids],
        [1000, 200],
        signature
      )
    ).to.be.revertedWith("SpacePiratesQuestRedeem: quest already claimed");
  });
  it("should revert if the signature is invalid", async () => {
    const value2 = {
      questName: "Test Quest 2",
      ids: [doubloons, asteroids],
      amounts: [1000, 200],
      receiver: ownerAddress,
    };

    const signature2 = await accounts[0]._signTypedData(domain, types, value2);

    await expect(
      questContract.claimQuest(
        "Test Quest 2",
        [doubloons, asteroids],
        [1000, 202],
        signature2
      )
    ).to.be.revertedWith("SpacePiratesQuestRedeem: invalid signature");
  });
});
