const { expect } = require("chai");
const { BigNumber } = require("ethers");
const { ethers } = require("hardhat");

const uri = "https://space-pirates-testnet.com/familiar/";

let accounts;
let ownerAddress;
let tokensContract;
let nftContract;
let helperRoleContract;
let nftCollectionFactory;
let uintMax112;

describe("SpacePiratesNFTFactoryContract", () => {
  before(async () => {
    const HelperRoleContract = await ethers.getContractFactory(
      "HelperRoleContract"
    );
    helperRoleContract = await HelperRoleContract.deploy();

    const TokenContract = await ethers.getContractFactory("SpacePiratesTokens");
    tokensContract = await TokenContract.deploy("");

    accounts = await ethers.getSigners();
    ownerAddress = accounts[0].getAddress();

    const NFTContract = await ethers.getContractFactory("SpacePiratesNFT");
    nftContract = await NFTContract.deploy(uri);

    const NFTCollectionFactory = await ethers.getContractFactory(
      "NFTCollectionFactory"
    );
    nftCollectionFactory = await NFTCollectionFactory.deploy(
      tokensContract.address,
      nftContract.address
    );

    const HelperMaxUint = await ethers.getContractFactory("HelperMaxUint");
    helperMaxUint = await HelperMaxUint.deploy();

    uintMax112 = await helperMaxUint.maxUint(112);

    let role = helperRoleContract.getBurnRoleBytes(1);
    tokensContract.grantRole(role, nftCollectionFactory.address);
    role = helperRoleContract.getBurnRoleBytes(2);
    tokensContract.grantRole(role, nftCollectionFactory.address);
    role = helperRoleContract.getBurnRoleBytes(1001);
    tokensContract.grantRole(role, nftCollectionFactory.address);

    role = await nftContract.CAN_MINT();
    nftContract.grantRole(role, nftCollectionFactory.address);

    tokensContract.setApprovalForAll(nftCollectionFactory.address, true);
  });
  it("createCollection", async () => {
    expect(await nftCollectionFactory.getCollectionsList()).to.be.deep.equal(
      []
    );
    expect(await nftCollectionFactory.exist("First collection")).to.be.false;
    await expect(
      nftCollectionFactory.createCollection("First collection", 0, 0, 0, 0)
    ).to.be.revertedWith("NFTCollectionFactory: collection of 0 element");
    await nftCollectionFactory.createCollection(
      "First collection",
      100,
      0,
      0,
      0
    );
    expect(await nftCollectionFactory.exist("First collection")).to.be.true;
    expect(await nftCollectionFactory.getCollectionsList()).to.be.deep.equal([
      "First collection",
    ]);
  });
  it("edit collection", async () => {
    await expect(
      nftCollectionFactory.editCollection(
        "Non Existing Collection",
        100,
        0,
        0,
        2
      )
    ).to.be.revertedWith("NFTCollectionFactory: collection does not exist");
    await nftCollectionFactory.editCollection("First collection", 100, 0, 0, 2);
  });
  it("mint", async () => {
    const dblBalance = await tokensContract.balanceOf(ownerAddress, 1);
    const astBalance = await tokensContract.balanceOf(ownerAddress, 2);
    const gemBalance = await tokensContract.balanceOf(ownerAddress, 1001);
    let role = helperRoleContract.getMintRoleBytes(1);
    tokensContract.grantRole(role, ownerAddress);
    role = helperRoleContract.getMintRoleBytes(2);
    tokensContract.grantRole(role, ownerAddress);
    role = helperRoleContract.getMintRoleBytes(1001);
    tokensContract.grantRole(role, ownerAddress);

    const dblPrice = await nftCollectionFactory.doubloonsPrice();
    const astPrice = await nftCollectionFactory.asteroidsPrice();

    await tokensContract.mintBatch(
      ownerAddress,
      [1, 2, 1001],
      [dblPrice.mul(2), astPrice.mul(2), 2]
    );

    await expect(nftCollectionFactory.mintCollectionItem("First collection", 3))
      .to.be.reverted;
    await expect(
      nftCollectionFactory.mintCollectionItem("Firstt collection", 3)
    ).to.be.revertedWith("NFTCollectionFactory: the collection does not exist");
    await expect(
      nftCollectionFactory.mintCollectionItem("First collection", 0)
    ).to.be.revertedWith("NFTCollectionFactory: can't mint 0 NFT");

    await nftCollectionFactory.mintCollectionItem("First collection", 2);

    expect(await tokensContract.balanceOf(ownerAddress, 1)).to.be.equal(
      dblBalance
    );
    expect(await tokensContract.balanceOf(ownerAddress, 2)).to.be.equal(
      astBalance
    );
    expect(await tokensContract.balanceOf(ownerAddress, 1001)).to.be.equal(
      gemBalance
    );
    expect(await nftContract.walletOfOwner(ownerAddress)).to.be.deep.equal([
      BigNumber.from("1"),
      BigNumber.from("2"),
    ]);
  });
  it("revert if sale not started", async () => {
    const timestamp = await getTimeStamp();
    await nftCollectionFactory.createCollection(
      "Future collection",
      100,
      timestamp + 100,
      timestamp + 1100,
      0
    );

    const dblPrice = await nftCollectionFactory.doubloonsPrice();
    const astPrice = await nftCollectionFactory.asteroidsPrice();

    await tokensContract.mintBatch(
      ownerAddress,
      [1, 2, 1001],
      [dblPrice.mul(2), astPrice.mul(2), 2]
    );

    await expect(
      nftCollectionFactory.mintCollectionItem("Future collection", 2)
    ).to.be.revertedWith("NFTCollectionFactory: collection not started yet");
  });
  it("revert if sale ended", async () => {
    const timestamp = await getTimeStamp();
    await nftCollectionFactory.createCollection(
      "Ended collection",
      100,
      timestamp - 1100,
      timestamp - 100,
      0
    );

    const dblPrice = await nftCollectionFactory.doubloonsPrice();
    const astPrice = await nftCollectionFactory.asteroidsPrice();

    tokensContract.mintBatch(
      ownerAddress,
      [1, 2, 1001],
      [dblPrice.mul(2), astPrice.mul(2), 2]
    );

    await expect(
      nftCollectionFactory.mintCollectionItem("Ended collection", 2)
    ).to.be.revertedWith("NFTCollectionFactory: collection already ended");
  });
  it("revert if max address mint reached", async () => {
    const timestamp = await getTimeStamp();
    await nftCollectionFactory.createCollection(
      "Max 1 mint per address collection",
      100,
      0,
      0,
      1
    );

    const dblPrice = await nftCollectionFactory.doubloonsPrice();
    const astPrice = await nftCollectionFactory.asteroidsPrice();

    await tokensContract.mintBatch(
      ownerAddress,
      [1, 2, 1001],
      [dblPrice.mul(2), astPrice.mul(2), 2]
    );

    await nftCollectionFactory.mintCollectionItem(
      "Max 1 mint per address collection",
      1
    );

    await expect(
      nftCollectionFactory.mintCollectionItem(
        "Max 1 mint per address collection",
        1
      )
    ).to.be.revertedWith("NFTCollectionFactory: exceeded address mint limit");
  });
  it("revert if max mint reached", async () => {
    const timestamp = await getTimeStamp();
    await nftCollectionFactory.createCollection(
      "Limited collection",
      3,
      0,
      0,
      0
    );

    const dblPrice = await nftCollectionFactory.doubloonsPrice();
    const astPrice = await nftCollectionFactory.asteroidsPrice();

    await tokensContract.mintBatch(
      ownerAddress,
      [1, 2, 1001],
      [dblPrice.mul(4), astPrice.mul(4), 2]
    );

    await nftCollectionFactory.mintCollectionItem("Limited collection", 3);

    await expect(
      nftCollectionFactory.mintCollectionItem("Limited collection", 1)
    ).to.be.revertedWith(
      "NFTCollectionFactory: mint quantity exceed availability"
    );
  });
  it("not decrease availability if max", async () => {
    const timestamp = await getTimeStamp();
    await nftCollectionFactory.createCollection(
      "Unlimited collection",
      uintMax112,
      0,
      0,
      0
    );

    const dblPrice = await nftCollectionFactory.doubloonsPrice();
    const astPrice = await nftCollectionFactory.asteroidsPrice();

    await tokensContract.mintBatch(
      ownerAddress,
      [1, 2, 1001],
      [dblPrice.mul(4), astPrice.mul(4), 2]
    );

    await nftCollectionFactory.mintCollectionItem("Unlimited collection", 4);

    expect(
      (await nftCollectionFactory.collections("Unlimited collection")).available
    ).to.be.equal(uintMax112);
  });
  it("set price", async () => {
    const dblNewPrice = 1000;
    const astNewPrice = 10;
    await nftCollectionFactory.setPrice(dblNewPrice, astNewPrice);

    expect(await nftCollectionFactory.doubloonsPrice()).to.be.equal(
      BigNumber.from(dblNewPrice)
    );
    expect(await nftCollectionFactory.asteroidsPrice()).to.be.equal(
      BigNumber.from(astNewPrice)
    );
  });
});

const getTimeStamp = async () => {
  const blockNumBefore = await ethers.provider.getBlockNumber();
  const blockBefore = await ethers.provider.getBlock(blockNumBefore);
  const timestampBefore = blockBefore.timestamp;
  return timestampBefore;
};
