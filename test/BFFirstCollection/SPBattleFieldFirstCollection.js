const { expect } = require("chai");
const { BigNumber } = require("ethers");
const { ethers } = require("hardhat");

let accounts;
let ownerAddress;
let tokensContract;
let helperRoleContract;
let mintContract;

describe("SpacePiratesBattleFieldMint", () => {
  before(async () => {
    const HelperRoleContract = await ethers.getContractFactory(
      "HelperRoleContract"
    );
    helperRoleContract = await HelperRoleContract.deploy();

    const TokenContract = await ethers.getContractFactory("SpacePiratesTokens");
    tokensContract = await TokenContract.deploy("");

    accounts = await ethers.getSigners();
    ownerAddress = accounts[0].getAddress();

    await tokensContract.grantRole(
      "0x9a04e0fe6fc58d8074e1248913ba8264db0172239ac5ac3abda2b5e4a8a27af9",
      ownerAddress
    );
  });
  beforeEach(async () => {
    const timestamp = await getTimeStamp();
    const duration = 604800;
    const MintContract = await ethers.getContractFactory(
      "BattleFieldFirstCollection"
    );

    mintContract = await MintContract.deploy(
      tokensContract.address,
      timestamp,
      duration
    );
    await tokensContract.grantRole(
      "0x6a5cf4fbc764663782b6c69f42c0b62dfba03c7e30fcffbf9480a5d3db112ef5",
      mintContract.address
    ); //mint role
    await tokensContract.grantRole(
      "0x79c4f19595d0f36d8c94f6d809decda230ff568defdd4e85ca989d8c603c2efb",
      mintContract.address
    ); //burn role

    await tokensContract.setApprovalForAll(mintContract.address, true);
  });
  it("mint 2 NFTs", async () => {
    expect(await mintContract.totalSupply()).to.be.equal(0);
    const startId = await mintContract.mintId();
    const price = await mintContract.PRICE();

    await tokensContract.mint(ownerAddress, 1, 2 * price);

    await mintContract.mint(2);
    expect(
      await tokensContract.balanceOf(ownerAddress, parseInt(startId) + 1)
    ).to.be.equal(1);
    expect(
      await tokensContract.balanceOf(ownerAddress, parseInt(startId) + 2)
    ).to.be.equal(1);
    expect(await mintContract.mintId()).to.be.equal(parseInt(startId) + 2);
    expect(await mintContract.totalSupply()).to.be.equal(2);
  });
  it("should revert if tried to mint a third NFT", async () => {
    const price = await mintContract.PRICE();

    await tokensContract.mint(ownerAddress, 1, 3 * price);
    await mintContract.mint(2);
    await expect(mintContract.mint(1)).to.be.revertedWith(
      "BattleFieldFirstCollection: mint quantity exceeds allowance for this address"
    );
  });
  it("should revert if not enough funds", async () => {
    const price = await mintContract.PRICE();

    await tokensContract.mint(ownerAddress, 1, 2 * price - 1);

    await expect(mintContract.mint(2)).to.be.reverted;
  });
  it("should revert if max supply reached", async () => {
    const price = await mintContract.PRICE();
    const supply = await mintContract.MAX_SUPPLY();
    for (i = 0; i < supply; i++) {
      let wallet = ethers.Wallet.createRandom();
      wallet = wallet.connect(ethers.provider);
      let tx = accounts[0].sendTransaction({
        to: wallet.address,
        value: ethers.BigNumber.from("1000000000000000000"),
      });
      await tx;
      await tokensContract.mint(wallet.address, 1, price);
      await tokensContract
        .connect(wallet)
        .setApprovalForAll(mintContract.address, true);
      await mintContract.connect(wallet).mint(1);
    }
    await tokensContract.mint(ownerAddress, 1, price);
    await expect(mintContract.mint(1)).to.be.revertedWith(
      "BattleFieldFirstCollection: mint quantity exceeds max supply"
    );
  });
  it("should revert if sale not started", async () => {
    const timestamp = await getTimeStamp();
    const duration = 604800;
    const MintContract = await ethers.getContractFactory(
      "BattleFieldFirstCollection"
    );

    mintContract = await MintContract.deploy(
      tokensContract.address,
      timestamp + 1000,
      duration
    );
    await tokensContract.grantRole(
      "0x6a5cf4fbc764663782b6c69f42c0b62dfba03c7e30fcffbf9480a5d3db112ef5",
      mintContract.address
    ); //mint role
    await tokensContract.grantRole(
      "0x72275d2d7cdf971af1091b6e0e4e2863c24b00b92a68a8e7184cc5d55ff619e2",
      mintContract.address
    ); //burn role

    const price = await mintContract.PRICE();

    await tokensContract.mint(ownerAddress, 1, price);

    await expect(mintContract.mint(2)).to.be.revertedWith(
      "BattleFieldFirstCollection: mint not started yet"
    );
  });
  it("should revert if sale already ended", async () => {
    await timeJump(604800 + 1);
    const price = await mintContract.PRICE();

    await tokensContract.mint(ownerAddress, 1, price);

    await expect(mintContract.mint(2)).to.be.revertedWith(
      "BattleFieldFirstCollection: mint already ended"
    );
  });
  it("should revert if quantity equal to 0", async () => {
    const price = await mintContract.PRICE();

    await tokensContract.mint(ownerAddress, 1, price);
    await expect(mintContract.mint(2)).to.be.revertedWith(
      "BattleFieldFirstCollection: need to mint at least 1 NFT"
    );
  });
});

const getTimeStamp = async () => {
  const blockNumBefore = await ethers.provider.getBlockNumber();
  const blockBefore = await ethers.provider.getBlock(blockNumBefore);
  const timestampBefore = blockBefore.timestamp;
  return timestampBefore;
};

const timeJump = async (amount) => {
  await network.provider.send("evm_increaseTime", [amount]);
  await network.provider.send("evm_mine");
};
