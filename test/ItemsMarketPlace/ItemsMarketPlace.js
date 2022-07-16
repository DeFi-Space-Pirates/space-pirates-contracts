const { expect } = require("chai");
const { BigNumber } = require("ethers");
const { ethers } = require("hardhat");

let accounts;
let ownerAddress;
let tokensContract;
let helperRoleContract;
let marketPlace;
let helperMaxUint;
let uintMax120;
let validEndSale;

const getTimeStamp = async () => {
  const blockNumBefore = await ethers.provider.getBlockNumber();
  const blockBefore = await ethers.provider.getBlock(blockNumBefore);
  const timestampBefore = blockBefore.timestamp;
  return timestampBefore;
};

describe("SpacePiratesItemsMarketPlace", () => {
  before(async () => {
    const HelperRoleContract = await ethers.getContractFactory(
      "HelperRoleContract"
    );
    helperRoleContract = await HelperRoleContract.deploy();

    const HelperMaxUint = await ethers.getContractFactory("HelperMaxUint");
    helperMaxUint = await HelperMaxUint.deploy();

    uintMax120 = await helperMaxUint.maxUint(120);

    const TokenContract = await ethers.getContractFactory("SpacePiratesTokens");
    tokensContract = await TokenContract.deploy("");

    accounts = await ethers.getSigners();
    ownerAddress = accounts[0].getAddress();

    const MarketPlace = await ethers.getContractFactory(
      "SpacePiratesItemsMarketPlace"
    );
    marketPlace = await MarketPlace.deploy(tokensContract.address);

    tokensContract.grantMultiRole(
      [
        "0x77fe00f5aaa81d64d9f55d8616be0398bce160f21a075e1635f854dc0c69a572",
        "0x79c4f19595d0f36d8c94f6d809decda230ff568defdd4e85ca989d8c603c2efb",
      ],
      [marketPlace.address, marketPlace.address]
    );
    await tokensContract.grantRole(
      "0x9a04e0fe6fc58d8074e1248913ba8264db0172239ac5ac3abda2b5e4a8a27af9",
      ownerAddress
    );

    tokensContract.setApprovalForAll(marketPlace.address, true);
    tokensContract
      .connect(accounts[1])
      .setApprovalForAll(marketPlace.address, true);
    validEndSale = (await getTimeStamp()) + 1000000;
  });
  it("create a sale", async () => {
    const index = await marketPlace.salesAmount();
    await marketPlace.createSale(
      [20001, 20002],
      [1, 1],
      1,
      BigNumber.from("100000"),
      validEndSale,
      uintMax120,
      0
    );
    await expect(
      marketPlace
        .connect(accounts[1])
        .createSale(
          [20001, 20002],
          [1, 1],
          1,
          BigNumber.from("100000"),
          validEndSale,
          uintMax120,
          0
        )
    ).to.be.reverted;
    const sale = await marketPlace.sales(index);
    expect(sale.paymentId).to.be.equal(1);
    expect(sale.price).to.be.equal(BigNumber.from("100000"));
    expect(sale.saleEnd).to.be.equal(validEndSale);
    expect(sale.available).to.be.equal(uintMax120);
    expect(sale.maxBuyPerAddress).to.be.equal(0);
    expect(await marketPlace.saleItemsIds(index)).to.be.deep.equal([
      BigNumber.from("20001"),
      BigNumber.from("20002"),
    ]);
    expect(await marketPlace.saleItemsQuantities(index)).to.be.deep.equal([
      BigNumber.from("1"),
      BigNumber.from("1"),
    ]);
    expect(await marketPlace.itemsOnSale(0)).to.be.equal(
      BigNumber.from("20001")
    );
    expect(await marketPlace.itemsOnSale(1)).to.be.equal(
      BigNumber.from("20002")
    );
    expect(await marketPlace.itemsOnSaleArray()).to.be.deep.equal([
      BigNumber.from("20001"),
      BigNumber.from("20002"),
    ]);
    expect(await marketPlace.saleIndexes(20001, 0)).to.be.equal(0);
    expect(await marketPlace.saleIndexes(20002, 0)).to.be.equal(0);
    expect(await marketPlace.salesIndexesFromId(20001)).to.be.deep.equal([
      BigNumber.from("0"),
    ]);
    expect(await marketPlace.salesIndexesFromId(20002)).to.be.deep.equal([
      BigNumber.from("0"),
    ]);
  });
  it("revert if ids and quantities has different length", async () => {
    await expect(
      marketPlace.createSale(
        [20001, 20002],
        [1],
        1,
        BigNumber.from("100000"),
        validEndSale,
        uintMax120,
        0
      )
    ).to.be.revertedWith(
      "SpacePiratesItemsMarketPlace: array with different sizes"
    );
  });
  it("revert if id not of the collections", async () => {
    await expect(
      marketPlace.createSale(
        [20001, 2000200],
        [1, 2],
        1,
        BigNumber.from("100000"),
        validEndSale,
        uintMax120,
        0
      )
    ).to.be.revertedWith("SpacePiratesItemsMarketPlace: invalid id");
  });
  it("buy an item", async () => {
    await tokensContract.mint(ownerAddress, 1, 2000);

    const index = await marketPlace.salesAmount();
    await marketPlace.createSale(
      [20010, 20020],
      [1, 2],
      1,
      BigNumber.from("1000"),
      BigNumber.from("1672531200"),
      uintMax120,
      0
    );

    await marketPlace.buyItem(index, 2);

    expect(await tokensContract.balanceOf(ownerAddress, 20010)).to.be.equal(2);
    expect(await tokensContract.balanceOf(ownerAddress, 20020)).to.be.equal(4);
  });
  it("revert if sale ended", async () => {
    const index = await marketPlace.salesAmount();
    await tokensContract.mint(ownerAddress, 1, 10000);
    await marketPlace.createSale(
      [20010, 20020],
      [1, 2],
      1,
      BigNumber.from("1000"),
      BigNumber.from("1640995200"),
      uintMax120,
      0
    );

    await expect(marketPlace.buyItem(index, 1)).to.be.revertedWith(
      "SpacePiratesItemsMarketPlace: sale ended"
    );
  });
  it("revert if supply reached", async () => {
    const index = await marketPlace.salesAmount();
    await tokensContract.mint(ownerAddress, 1, 10000);
    await marketPlace.createSale(
      [20010, 20020],
      [1, 2],
      1,
      BigNumber.from("1000"),
      validEndSale,
      3,
      0
    );

    await marketPlace.buyItem(index, 2);

    await expect(marketPlace.buyItem(index, 1)).to.be.revertedWith(
      "SpacePiratesItemsMarketPlace: buy exceed available quantity"
    );
  });
  it("revert if max per address reached", async () => {
    const index = await marketPlace.salesAmount();
    await tokensContract.mint(ownerAddress, 1, 10000);
    await tokensContract.mint(accounts[1].getAddress(), 1, 10000);
    await marketPlace.createSale(
      [20010, 20020],
      [1, 2],
      1,
      BigNumber.from("1000"),
      validEndSale,
      uintMax120,
      2
    );

    await marketPlace.buyItem(index, 2);

    await marketPlace.connect(accounts[1]).buyItem(index, 2);

    await expect(marketPlace.buyItem(index, 1)).to.be.revertedWith(
      "SpacePiratesItemsMarketPlace: exceed user max mint"
    );
  });
});
